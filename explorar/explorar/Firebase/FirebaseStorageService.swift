//
//  Storage.swift
//  explorar
//
//  Created by Fabian Kuschke on 23.07.25.
//

import Foundation
import FirebaseStorage
import UIKit

class FirebaseStorageService {
    static let shared = FirebaseStorageService()
    private let storage = Storage.storage()
    private let maxFileSize: Int = 50 * 1024 * 1024 // 50 MB safty
    private init() {}
    
    //MARK: Upload Image
    func uploadImage(image: UIImage, poiID: String, imageName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference().child("images/\(poiID)/\(imageName)")
        
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            let error = NSError(domain: "FirestoreService",
                                code: 401,
                                userInfo: [NSLocalizedDescriptionKey: "imageData"])
            completion(.failure(error))
            return
        }
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("uploaded add to place")
                completion(.success(()))
            }
        }
    }
    
    //MARK: Upload data
    func uploadData(data: Data, folderName: String, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard data.count <= maxFileSize else {
            let error = NSError(
                domain: "Storage",
                code: 413,
                userInfo: [NSLocalizedDescriptionKey: "File 50MB upload limit."]
            )
            completion(.failure(error))
            return
        }
        let storageRef = storage.reference().child("\(folderName)/\(fileName)")
        
        storageRef.putData(data, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                }
            }
        }
    }
    //MARK: Download data-> save local
    func downloadData(folderName: String, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = storage.reference().child("\(folderName)/\(fileName)")
        
        // Destination in local Documents directory
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            completion(.failure(NSError(domain: "Storage", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not access Library directory."])))
            return
        }
        
        let destinationURL = documentsURL.appendingPathComponent(fileName)
        
        // Check if the file already exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            print("alreads exits")
            completion(.success(destinationURL))
            return
        }
        
        // Download the data
        storageRef.getData(maxSize: Int64(maxFileSize)) { data, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "Storage", code: 500, userInfo: [NSLocalizedDescriptionKey: "Data is nil."])))
                return
            }
            
            do {
                try data.write(to: destinationURL)
                completion(.success(destinationURL))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func createAndUploadFileListJSON(completion: @escaping (Result<Bool, Error>) -> Void) {
        let storage = Storage.storage()
        let locationsRef = storage.reference().child("Locations")
        let rootRef = storage.reference()
        
        locationsRef.listAll { result, error in
            if let error = error {
                print("Failed to list files: \(error)")
                completion(.failure(error))
                return
            }
            
            let fileNamesWithoutExtensions = result!.items.map { ref -> String in
                let name = ref.name
                if let dotIndex = name.lastIndex(of: ".") {
                    return String(name[..<dotIndex])
                } else {
                    return name
                }
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: fileNamesWithoutExtensions, options: [])
                let jsonFileRef = rootRef.child("locations_list.json")
                let metadata = StorageMetadata()
                metadata.contentType = "application/json"
                
                jsonFileRef.putData(jsonData, metadata: metadata) { metadata, error in
                    if let error = error {
                        print("Failed to upload JSON: \(error)")
                        completion(.failure(error))
                    } else {
                        print("Successfully uploaded JSON file with file list!")
                        completion(.success(true))
                    }
                }
            } catch {
                print("Failed to serialize JSON: \(error)")
                completion(.failure(error))
            }
        }
    }

}
