//
//  SelfieCityView.swift
//  explorar
//
//  Created by Fabian Kuschke on 30.07.25.
//

import SwiftUI
import TelemetryClient
import Drops

struct SelfieCityView: View {
    var folderName: String
    @State private var images: [(image: UIImage, displayName: String, fileName: String)] = []
    @State private var selectedImage: UIImage? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var imageToDelete: String? = nil
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 15) {
                    ForEach(images.indices, id: \.self) { index in
                        VStack {
                            Spacer().frame(height: 10)
                            Image(uiImage: images[index].image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 160)
                                .clipped()
                                .cornerRadius(8)
                                .shadow(radius: 3)
                                .onLongPressGesture {
                                    imageToDelete = images[index].fileName
                                    showDeleteAlert = true
                                }
                            
                            Text("\(images[index].displayName)")
                                .minimumScaleFactor(0.5)
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .lineLimit(2)
                                .padding(4)
                            
                        }
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(8)
                        .onTapGesture {
                            selectedImage = images[index].image
                        }
                        
                        
                    }
                }
                .padding()
            }
            .onAppear {
                loadImagesFromFolder()
                TelemetryDeck.signal("Selfie_City_View_Loaded")
            }
            
            if let image = selectedImage {
                ZStack {
                    Color.black.opacity(0.9)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture { selectedImage = nil }
                    
                    VStack {
                        Text("Tap anywhere to close")
                            .minimumScaleFactor(0.5)
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                        Spacer()
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding()
                            .onTapGesture { selectedImage = nil }
                            .background(
                                Color.white
                            )
                        Spacer()
                        NavigationLink(destination: PostOnWallView(image: image)) {
                            Text("Show image on your wall")
                        }
                    }
                }

                .transition(.opacity)
                .zIndex(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            backgroundGradient
                .ignoresSafeArea(.all)
        }
        .navigationTitle("Bilderbibliothek")
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Photo"),
                message: Text("Are you sure you want to delete this photo?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let fileName = imageToDelete {
                        deleteFile(fileName: fileName)
                        loadImagesFromFolder()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func loadImagesFromFolder() {
        images.removeAll()
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else { return }
        let folderURL = documentsURL.appendingPathComponent(folderName)
        
        do {
            let files = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            let pngFiles = files.filter { $0.pathExtension.lowercased() == "png" }
            
            for file in pngFiles {
                if let imageData = try? Data(contentsOf: file),
                   let image = UIImage(data: imageData) {
                    
                    let rawName = file.lastPathComponent
                    let displayName = formatFileNameForDisplay(file.deletingPathExtension().lastPathComponent)
                    
                    images.append((image: image, displayName: displayName, fileName: rawName))
                }
            }
        } catch {
            print("Failed to load images: \(error)")
            Drops.show(Drop(title: "Failed to load images: \(error)"))
        }
    }
    private func formatFileNameForDisplay(_ fileName: String) -> String {
        // format: Placename_HH-mm-ss_dd-MM-yyyy
        let components = fileName.split(separator: "_")
        guard components.count >= 3 else { return fileName }
        
        let placeName = String(components[0])
        let timePart = String(components[1])// HH-mm-ss
        let datePart = String(components[2])// dd-MM-yyyy
        
        // Convert time to HH:mm no seconds
        let timeComponents = timePart.split(separator: "-")
        let timeFormatted = timeComponents.count >= 2 ? "\(timeComponents[0]):\(timeComponents[1])" : timePart
        let dateFormated = datePart.replacingOccurrences(of: "-", with: ".")
        
        return "\(placeName)\n\(timeFormatted) \(dateFormated)"
    }
    private func deleteFile(fileName: String) {
        guard let documentsURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsURL.appendingPathComponent(folderName).appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("Deleted file: \(fileName)")
        } catch {
            print("Failed to delete file: \(error)")
            Drops.show(Drop(title: "Failed to delete file: \(error)"))
        }
    }
    
}
