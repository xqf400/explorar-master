//
//  DrawView.swift
//  explorar
//
//  Created by Fabian Kuschke on 11.08.25.
//

import SwiftUI
import PencilKit
import ConfettiSwiftUI
import Drops
import Photos
#if !APPCLIP
import TelemetryClient
import OpenAI
#endif

struct AnimalRating: Codable {
    let name: String
    let rating: Int
}

struct DrawView: View {
    let animalName: String
    let challenge: String
    let poiID: String
    let poiName: String
    
    @State private var canvas = PKCanvasView()
    @State private var tool: PKTool = PKInkingTool(.pen, color: .label, width: 6)
    @State private var canUndo = false
    @State private var canRedo = false
    
    @State private var showNoAIAlert: Bool = false
        
#if !APPCLIP
    @ObservedObject var userFire = UserFire.shared
#endif
    @State var loading = false
    @State private var resultText: String = "No animal identified"
    @State private var showConfetti: Int = 0
    
    func getImageFromCanvas(_ canvas: PKCanvasView) -> UIImage? {
        let bounds = canvas.bounds
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, scale)
        canvas.drawing.image(from: bounds, scale: scale).draw(in: bounds)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func checkDrawing() {
        guard let image = getImageFromCanvas(canvas) else {
            print("No image")
            Drops.show(Drop(title: "No image"))
            return
        }
        print("got image")
        identifyAnimal(selectedImage: image)
    }
    
    // MARK: AI Things
    func identifyAnimal(selectedImage: UIImage) {
#if !APPCLIP
        if !FirestoreService.shared.settings.AIidentifyAnimal {
            Drops.show(Drop(title: "Admin disabled identifying AI Images, sorry!"))
            return
        }
        loading = true
        saveImageToPhotosAndDocuments(image: selectedImage, folderName: "Cities", placeName: poiName)
        AIService.shared.identifyAnimal(selectedImage: selectedImage, challenge: challenge, animalName: animalName) { result in
            DispatchQueue.main.async {
                loading = false
            }
            switch result {
            case .success(let decoded):
                if !UserDefaults.standard.bool(forKey: poiID) {
                    let addPoint: Int = 10*decoded.rating
                    Drops.show(Drop(title: "Die KI hat dir eine Bewertung von \(decoded.rating)/10 gegeben.\n Du hast dafür \(addPoint) Punkte erhalten!",duration: 4.0))
                    if decoded.rating > 6 {
                        showConfetti += 1
                    }
                    let haptics = Haptics()
                    haptics?.playPattern()
                    userFire.updatePoints(amount: addPoint) { result in
                        switch result {
                        case .success(let points):
                            print("Points added now: \(points)")
                            UserDefaults.standard.set(true, forKey: poiID)
                            DispatchQueue.main.async {
                                resultText = "Animal: \(decoded.name)\nRating: \(decoded.rating)/10"
                            }
                        case .failure(let error):
                            print("Error adding points: \(error)")
                        }
                    }
                } else {
                    Drops.show(Drop(title: "Die KI hat dir eine Bewertung von \(decoded.rating)/10 gegeben.",duration: 4.0))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    resultText = error.localizedDescription
                }
            }
        }
        #else
        Drops.show(Drop(title: "Not supported. Please download the app for this feature", duration: 4.0))
#endif
    }
    
    func saveImageToPhotosAndDocuments(image: UIImage, folderName: String, placeName: String) {
#if !APPCLIP
        TelemetryDeck.signal("saved_draw_photo")
#endif
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else { return }
        
        let folderURL = documentsURL.appendingPathComponent(folderName)
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create folder: \(error)")
                Drops.show(Drop(title: "Failed to create folder: \(error)"))
                return
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH-mm-ss_dd-MM-yyyy"
        let fileName = "\(placeName)_\(formatter.string(from: Date())).png"
        let fileURL = folderURL.appendingPathComponent(fileName)
        
        if let imageData = image.pngData() {
            do {
                try imageData.write(to: fileURL)
                print("Saved image to documents folder: \(fileURL.path)")
            } catch {
                print("Failed to save image: \(error)")
                Drops.show(Drop(title: "Failed to save image: \(error)"))

            }
        }
    }
    
    // MARK: View
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Text(challenge)
                    .minimumScaleFactor(0.5)
                    .font(.title).bold()
                    .foregroundStyle(.white)
                    .padding(.top, 8)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color(UIColor.separator), lineWidth: 1)
                    
                    PencilCanvasView(
                        canvas: $canvas,
                        tool: $tool,
                        canUndo: $canUndo,
                        canRedo: $canRedo
                    )
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                    .shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
                    .padding(4)
                }
                .frame(minHeight: 340, maxHeight: 540)
                
                Spacer().frame(height: 10)
                HStack(spacing: 14) {
                    Spacer()
                    Menu {
                        Button("Pen")    { tool = PKInkingTool(.pen, color: .label, width: 6) }
                        Button("Marker") { tool = PKInkingTool(.marker, color: .label, width: 10) }
                        Button("Pencil") { tool = PKInkingTool(.pencil, color: .label, width: 5) }
                        Divider()
                        Button("Vector Eraser") { tool = PKEraserTool(.vector) }
                        Button("Bitmap Eraser") { tool = PKEraserTool(.bitmap) }
                    } label: {
                        Image(systemName: "pencil.tip")
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(30)
                    Spacer()
                    Button {
                        canvas.undoManager?.undo()
                    } label: {
                        Image(systemName: "arrow.uturn.left")
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                    }
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(30)
                    .disabled(!canUndo)
                    Spacer()
                    Button {
                        canvas.undoManager?.redo()
                    } label: {
                        Image(systemName: "arrow.uturn.right")
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                    }
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(30)
                    .disabled(!canRedo)
                    Spacer()
                    Button(role: .destructive) {
                        canvas.drawing = PKDrawing()
                    } label: {
                        Image(systemName: "trash")
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                    }
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(30)
                    Spacer()
                }
                .frame(height: 40)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(30)
                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                .shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
                Spacer()
                HStack {
                    Spacer().frame(width: 14)
                    Button {
                        #if !APPCLIP
                        checkDrawing()
                        #else
                        showNoAIAlert = true
                        #endif
                    } label: {
                        Text("Get a rating from AI")
                            .minimumScaleFactor(0.5)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .foregroundStyle(.white)
                    }
                    Spacer().frame(width: 14)
                }
                .frame(height: 50)
                .background(foregroundGradient)
                .cornerRadius(30)
                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                .shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
            }
            .padding(.horizontal, 20)
            
            if loading {
                VStack {
                    Spacer()
                    ProgressView("Ai is rating...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .background(Color.gray)
                        .tint(.blue)
                        .padding()
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            backgroundGradient
                .ignoresSafeArea(.all)
        }
        .confettiCannon(trigger: $showConfetti, num: 50, confettiSize: 15)
        .alert("Ai Feature is only working in the full app.", isPresented: $showNoAIAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

struct PencilCanvasView: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    @Binding var tool: PKTool
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.tool = tool
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.allowsFingerDrawing = true
        canvas.delegate = context.coordinator
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.tool = tool
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvasView
        
        init(_ parent: PencilCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.canUndo = canvasView.undoManager?.canUndo ?? false
            parent.canRedo = canvasView.undoManager?.canRedo ?? false
        }
    }
}
