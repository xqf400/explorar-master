//
//  ImageTestView.swift
//  explorar
//
//  Created by Fabian Kuschke on 23.07.25.
//

import SwiftUI
import PhotosUI

struct ImageTestView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var statusMessage: String = ""
    @State private var savedImageURL: URL?
    @State private var downloadedUIImage: UIImage?
    
    private let folderName = "images"
    private let fileName = "plochingenp2_image3.jpg"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Local image preview
                if let data = imageData, let uiImage = UIImage(data: data) {
                    Text("Selected Image:")
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
                
                PhotosPicker("Select Image", selection: $selectedItem, matching: .images)
                    .onChange(of: selectedItem) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                self.imageData = data
                                self.statusMessage = "Image selected."
                            }
                        }
                    }
                
                if imageData != nil {
                    Button("Upload to Firebase") {
                        uploadImage()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Download and Save to Documents") {
                    downloadImage()
                }
                .buttonStyle(.bordered)
                
                if let url = savedImageURL {
                    Text("Saved to: \(url.lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                // Display downloaded image from file
                if let downloadedUIImage = downloadedUIImage {
                    Text("Downloaded Image:")
                    Image(uiImage: downloadedUIImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
                
                Text(statusMessage)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
            }
            .padding()
        }
    }
    
    // MARK: - Upload
    private func uploadImage() {
        guard let data = imageData else {
            statusMessage = "No image selected."
            return
        }
        
        FirebaseStorageService.shared.uploadData(data: data, folderName: folderName, fileName: fileName) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    statusMessage = "Upload successful: \(url.lastPathComponent)"
                case .failure(let error):
                    statusMessage = "Upload failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Download
    private func downloadImage() {
        FirebaseStorageService.shared.downloadData(folderName: folderName, fileName: fileName) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let localURL):
                    savedImageURL = localURL
                    loadImageFromFile(url: localURL)
                    statusMessage = "Downloaded and saved as: \(localURL.lastPathComponent)"
                case .failure(let error):
                    statusMessage = "Download failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Load from File
    private func loadImageFromFile(url: URL) {
        if let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            downloadedUIImage = uiImage
        } else {
            downloadedUIImage = nil
            statusMessage = "Failed to load saved image."
        }
    }
}


#Preview {
    ImageTestView()
}
