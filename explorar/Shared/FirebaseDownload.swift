//
//  FirebaseDownload.swift
//  explorar
//
//  Created by Fabian Kuschke on 30.07.25.
//

import Foundation
import UIKit
import Drops

// MARK: download file
func downloadFileFromFireBase(name: String, folder: String, safeFile: Bool, success: @escaping (_ data: Data) -> Void, failure: @escaping (_ error: String) -> Void
) {
    let cachesURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("Caches")
    let targetURL = cachesURL.appendingPathComponent(name)
    
    // if file exists
    if safeFile {
        if FileManager.default.fileExists(atPath: targetURL.path) {
            do {
                let data = try Data(contentsOf: targetURL)
                print("File already downloaded \(name)")
                DispatchQueue.main.async {
                    success(data)
                }
                return
            } catch {
                print("Failed to load cached file, will download again: \(error.localizedDescription)")
                Drops.show(Drop(title: "Failed to load cached file, will download again: \(error.localizedDescription)"))

            }
        }
    }
    
    getTokenFromFirebase(folder: folder, name: name) { token in
        let filePath = "\(folder)/\(name)"
        let encodedFilePath = filePath.replacingOccurrences(of: "/", with: "%2F")
        
        let urlBaseline = "https://firebasestorage.googleapis.com/v0/b/explorar-f8349.firebasestorage.app/o/"
        let urlString = urlBaseline+"\(encodedFilePath)?alt=media&token=\(token)"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                failure("Invalid URL")
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    failure("Network error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    failure("Invalid HTTP response")
                }
                return
            }
            
            if httpResponse.statusCode > 300 {
                let err = NSError(domain: urlString, code: httpResponse.statusCode, userInfo: nil)
                DispatchQueue.main.async {
                    failure("HTTP error \(httpResponse.statusCode): \(err.localizedDescription)")
                }
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    failure("Unexpected status code: \(httpResponse.statusCode)")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    failure("No data received")
                }
                return
            }
            if safeFile {
                do {
                    try data.write(to: targetURL)
                    print("File \(name) saved")
                    DispatchQueue.main.async {
                        success(data)
                    }
                } catch {
                    DispatchQueue.main.async {
                        failure("File write error: \(error.localizedDescription)")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    success(data)
                }
            }
        }
        task.resume()
    } failure: { error in
        DispatchQueue.main.async {
            failure(error)
        }
    }
}



// MARK: get Token From Firebase
func getTokenFromFirebase( folder: String, name: String, success: @escaping (_ token: String) -> Void, failure: @escaping (_ error: String) -> Void
) {
    let urlBaseline = "https://firebasestorage.googleapis.com/v0/b/explorar-f8349.firebasestorage.app/o/"
    var encodedFilePath = name
    if !folder.isEmpty {
        let filePath = "\(folder)/\(name)"
        encodedFilePath = filePath.replacingOccurrences(of: "/", with: "%2F")
    }

    
    let urlString = urlBaseline+encodedFilePath
    guard let url = URL(string: urlString) else {
        DispatchQueue.main.async {
            failure("Invalid URL")
        }
        return
    }
    fetchDownloadToken(from: url, success: success, failure: failure)
    
    func fetchDownloadToken(
        from url: URL,
        success: @escaping (String) -> Void,
        failure: @escaping (String) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    failure(error.localizedDescription)
                }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    failure("Invalid response")
                }
                return
            }
            guard httpResponse.statusCode == 200 else {
                print("Statuscode: \(httpResponse.statusCode) \(httpResponse)")
                DispatchQueue.main.async {
                    failure("\(httpResponse.statusCode) File not found")
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    failure("No data")
                }
                return
            }
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let downloadTokens = jsonObject["downloadTokens"] as? String {
                    DispatchQueue.main.async {
                        success(downloadTokens)
                    }
                } else {
                    DispatchQueue.main.async {
                        failure("error downloadtoken")
                    }
                }
            } catch {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    failure(error.localizedDescription)
                }
            }
        }
        task.resume()
    }
}

// MARK: Availble places
func downloadFileListJSON(success: @escaping ([String]) -> Void, failure: @escaping (String) -> Void) {
    let folder = ""
    let name = "locations_list.json"
    
    getTokenFromFirebase(folder: folder, name: name, success: { token in
        let encodedFilePath = name.replacingOccurrences(of: "/", with: "%2F")
        let urlBaseline = "https://firebasestorage.googleapis.com/v0/b/explorar-f8349.firebasestorage.app/o/"
        let urlString = "\(urlBaseline)\(encodedFilePath)?alt=media&token=\(token)"
        
        guard let url = URL(string: urlString) else {
            failure("Invalid URL for JSON file")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { failure("Network error: \(error.localizedDescription)") }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { failure("No data received") }
                return
            }
            do {
                let fileList = try JSONDecoder().decode([String].self, from: data)
                DispatchQueue.main.async { success(fileList) }
            } catch {
                DispatchQueue.main.async { failure("Failed to decode JSON: \(error.localizedDescription)") }
            }
        }.resume()
    }, failure: { error in
        failure(error)
    })
}

//MARK:  Download Image

func downloadFirebaseImage(
    name: String,
    folder: String,
    safeFile: Bool = true,
    success: @escaping (UIImage) -> Void,
    failure: @escaping (String) -> Void
) {
    downloadFileFromFireBase(name: name, folder: folder, safeFile: safeFile) { data in
        if let image = UIImage(data: data) {
            success(image)
        } else {
            failure("Failed to create image from data")
        }
    } failure: { error in
        failure(error)
    }
}
