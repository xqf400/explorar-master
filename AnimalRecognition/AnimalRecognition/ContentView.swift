//
//  ContentView.swift
//  AnimalRecognition
//
//  Created by Fabian Kuschke on 13.08.25.
//

import SwiftUI
import PhotosUI
import Vision
import CoreML

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var image: UIImage? = nil
    @State private var classification: String = ""
    @State private var confidence: Float = 0.0
    @State private var modelIsDownloaded: Bool = false
    @State private var modelIsDownloading: Bool = false
    @State private var downloadStatus: String = ""
    
    // MARK: Check available model
    func checkDownloadedModel(){
        let fileManager = FileManager.default
        let supportDir = try! fileManager.url(for: .applicationSupportDirectory,
                                              in: .userDomainMask,
                                              appropriateFor: nil,
                                              create: true)
        let modelURL = supportDir.appendingPathComponent("Inceptionv3.mlmodel")
        print("modelURL \(modelURL)")
        if fileManager.fileExists(atPath: modelURL.path) {
            modelIsDownloaded = true
        } else {
            print("Model not found")
        }
    }
    
    // MARK: download Model
    func downloadModel() {
        modelIsDownloading = true
        let modelURL = URL(string: "https://explor-ar.fun/Inceptionv3.mlmodel")!
        let downloader = ModelDownloader()
        downloader.downloadModel(from: modelURL, progressHandler: { progress in
            print("Download progress: \(progress * 100)%")
            downloadStatus = "\(Int(progress * 100))%"
        }) { savedURL in
            modelIsDownloading = false
            if let savedURL = savedURL {
                print("Model saved at: \(savedURL.path)")
                checkDownloadedModel()
            }
        }
    }
    
// MARK: Classify image
    func classify(image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }
        do{
            let supportDir = try FileManager.default.url(for: .applicationSupportDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: nil,
                                                         create: true)
            let modelURL = supportDir.appendingPathComponent("Inceptionv3.mlmodel")

            let mlModel = try MLModel(contentsOf: modelURL)
            print("got mlModel")
            let visionModel = try VNCoreMLModel(for: mlModel)
            // if in app stored
            // guard let visionModel = try? VNCoreMLModel(for: Inceptionv3().model) else { return }
            print("got visionModel")
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let results = request.results as? [VNClassificationObservation],
                   let best = results.first, best.confidence > 0.5 {
                    classification = best.identifier.components(separatedBy: ",").first ?? best.identifier
                    confidence = best.confidence
                } else {
                    classification = "Unknown"
                    confidence = 0.0
                }
            }
            
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: .up)
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    classification = "Classification failed"
                    confidence = 0.0
                }
            }
        } catch {
            classification = error.localizedDescription
        }
    }

    // MARK: View
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                }
                if modelIsDownloaded {
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text("Pick a Photo")
                            .font(.title2)
                    }
                    if image != nil {
                        Button {
                            guard let uiImage = image else {return}
                            classify(image: uiImage)
                        } label: {
                            Text("Classiy image")
                        }
                    }
                } else {
                    Button {
                        downloadModel()
                    } label: {
                        Text("Download Model")
                    }
                }
                if !classification.isEmpty {
                    Text("Prediction: \(classification)")
                    Text(String(format: "Confidence: %.1f%%", confidence * 100))
                }
            }
            if modelIsDownloading {
                    ProgressView("Model is downloading \(downloadStatus)...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
            }
        }
        .padding()
        .onAppear {
            checkDownloadedModel()
        }
        .onChange(of: selectedItem) { _ ,newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    image = uiImage
                }
            }
        }
    }
}


class ModelDownloader: NSObject, URLSessionDownloadDelegate {
    private var progressHandler: ((Double) -> Void)?
    private var completionHandler: ((URL?) -> Void)?

    func downloadModel(from url: URL,
                       progressHandler: @escaping (Double) -> Void,
                       completionHandler: @escaping (URL?) -> Void) {
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: url)
        task.resume()
    }

    // Progress update
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            DispatchQueue.main.async {
                self.progressHandler?(progress)
            }
        }
    }

    // File is fully downloaded, so *move/compile and save*
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        print("download successful \(location)")
        do {
            // Compile model (mlmodel → mlmodelc)
            let compiledURL = try MLModel.compileModel(at: location)
            let supportDir = try FileManager.default.url(for: .applicationSupportDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: nil,
                                                         create: true)
            let destinationURL = supportDir.appendingPathComponent("Inceptionv3.mlmodel")
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: compiledURL, to: destinationURL)
            DispatchQueue.main.async {
                self.completionHandler?(destinationURL)
            }
        } catch {
            print("Error handling model file: \(error)")
            DispatchQueue.main.async {
                self.completionHandler?(nil)
            }
        }
    }
}
