//
//  SmileView.swift
//  explorar
//
//  Created by Fabian Kuschke on 30.07.25.
//

import SwiftUI
import ARKit
import SceneKit
import AVFoundation
import ConfettiSwiftUI
import Drops
import Photos
#if !APPCLIP
import TelemetryClient
#endif

struct SmileView: View {
    @Environment(\.dismiss) private var dismiss
    #if !APPCLIP
    @ObservedObject var userFire = UserFire.shared
    #endif
    @State private var infoLabelText: String = "Loading..."
    @State private var showPhotoButton = false
    @State private var showARView = true
    @State private var savingPhoto = false
    @State private var arViewRef: ARSCNView? = nil
    let poiID: String
    let poiName: String
    @State private var showConfetti: Int = 0

    func saveImageToPhotosAndDocuments(image: UIImage, folderName: String, placeName: String) {
#if !APPCLIP
        TelemetryDeck.signal("saved_smiling_photo")
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
                // dismiss()
            } catch {
                print("Failed to save image: \(error)")
                Drops.show(Drop(title: "Failed to save image: \(error)"))

            }
        }
    }


    
    var body: some View {
        ZStack {
                backgroundGradient
                    .ignoresSafeArea(.all)
            VStack(spacing: 10) {
                Spacer().frame(height: 30)
                Text(infoLabelText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 30)
                
                if showARView {
                    FaceARView(infoLabelText: $infoLabelText,
                               showPhotoButton: $showPhotoButton,
                               showARView: $showARView, arViewReference: $arViewRef)
                    .frame(height: 600)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                    .padding()
                }
                
                if showPhotoButton {
                    HStack {
                        Spacer().frame(width: 30)
                        HStack {
                            Button {
                                if !savingPhoto {
                                    savingPhoto = true
                                    if let snapshot = arViewRef?.snapshot() {
                                        print("AR snapshot captured")
                                        saveImageToPhotosAndDocuments(image: snapshot, folderName: "Cities", placeName: poiName)
                                    }
                                    let haptics = Haptics()
                                    haptics?.playPattern()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        showConfetti += 1
                                    }
                                    #if !APPCLIP
                                    if UserFire.shared.dailyChallenges?.challenge1 == "2" {
                                        UserFire.shared.updateDailyChallenge(id: "1")
                                    }
                                    if UserFire.shared.dailyChallenges?.challenge2 == "2" {
                                        UserFire.shared.updateDailyChallenge(id: "2")
                                    }
                                    if UserFire.shared.dailyChallenges?.challenge3 == "2" {
                                        UserFire.shared.updateDailyChallenge(id: "3")
                                    }
                                    if UserFire.shared.weeklyChallenges?.challenge1 == "2" {
                                        UserFire.shared.updateWeeklyChallenge(id: "1")
                                    }
                                    if UserFire.shared.weeklyChallenges?.challenge2 == "2" {
                                        UserFire.shared.updateWeeklyChallenge(id: "2")
                                    }
                                    if UserFire.shared.weeklyChallenges?.challenge3 == "2" {
                                        UserFire.shared.updateWeeklyChallenge(id: "3")
                                    }
                                    if !UserDefaults.standard.bool(forKey: poiID) {
                                        let points = 10
                                        let res = LocalizedStringResource(
                                            "selfie_points",
                                            defaultValue: "Yeah, selfie taken! And you got \(points) points! 🎉",
                                            table: "Localizable",
                                            comment: ""
                                        )
                                        Drops.show(Drop(title: String(localized: res),duration: 4.0))
                                        userFire.updatePoints(amount: points) { result in
                                            switch result {
                                            case .success(let points):
                                                print("Points added now: \(points)")
                                                savingPhoto = false
                                                UserDefaults.standard.set(true, forKey: poiID)
                                            case .failure(let error):
                                                print("Error adding points: \(error)")
                                                savingPhoto = false
                                            }
                                        }
                                    } else {
                                        let res = LocalizedStringResource(
                                            "selfie_points",
                                            defaultValue: "Yeah, selfie taken!",
                                            table: "Localizable",
                                            comment: ""
                                        )
                                        Drops.show(Drop(title: String(localized: res),duration: 4.0))
                                    }
                                    #else
                                    let res = LocalizedStringResource(
                                        "selfie_points",
                                        defaultValue: "Yeah, selfie taken!",
                                        table: "Localizable",
                                        comment: ""
                                    )
                                    Drops.show(Drop(title: String(localized: res),duration: 4.0))
                                    #endif
                                }
                            } label: {
                                Spacer()
                                Text("Take photo")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .minimumScaleFactor(0.5)
                                    .foregroundColor(Color.white)
                                Spacer()
                            }
                        }
                        .frame(height: 60)
                        .background(foregroundGradient)
                        .cornerRadius(30)
                        .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                        .disabled(savingPhoto)
                        Spacer().frame(width: 30)
                    }
                } else {
                    Spacer().frame(height: 60)
                }
                Spacer().frame(height: 20)
            }
        }
        .confettiCannon(trigger: $showConfetti, num: 50, confettiSize: 15)

        .navigationTitle("Smiling")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - ARKit FaceARView
struct FaceARView: UIViewRepresentable {
    @Binding var infoLabelText: String
    @Binding var showPhotoButton: Bool
    @Binding var showARView: Bool
    @Binding var arViewReference: ARSCNView?
    
    private let configuration = ARFaceTrackingConfiguration()
    
    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        sceneView.automaticallyUpdatesLighting = true
        DispatchQueue.main.async {
            arViewReference = sceneView
            startARSession(sceneView: sceneView)
        }
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func startARSession(sceneView: ARSCNView) {
        guard ARFaceTrackingConfiguration.isSupported else {
            infoLabelText = "Device not supported for AR Face Tracking"
            showPhotoButton = true
            showARView = false
            return
        }
        
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            infoLabelText = NSLocalizedString("Smile to take a photo", comment: "")
            sceneView.session.run(configuration)
        } else {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        infoLabelText = NSLocalizedString("Smile to take a photo", comment: "")
                        sceneView.session.run(configuration)
                    } else {
                        infoLabelText = "Please activate camera access"
                        showARView = false
                    }
                }
            }
        }
    }
    
    // MARK: - Coordinator with Smile Detection
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: FaceARView
        
        init(_ parent: FaceARView) {
            self.parent = parent
        }
        
        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard let device = (renderer as? ARSCNView)?.device,
                  let faceMesh = ARSCNFaceGeometry(device: device) else { return nil }
            
            let node = SCNNode(geometry: faceMesh)
            let material = SCNMaterial()
            material.transparency = 0
            node.geometry?.firstMaterial = material
            return node
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor,
                  let faceGeometry = node.geometry as? ARSCNFaceGeometry else { return }
            
            faceGeometry.update(from: faceAnchor.geometry)
            
            let smileLeft = faceAnchor.blendShapes[.mouthSmileLeft]?.decimalValue ?? 0.0
            let smileRight = faceAnchor.blendShapes[.mouthSmileRight]?.decimalValue ?? 0.0
            
            if (smileLeft + smileRight) > 0.9 {
                DispatchQueue.main.async {
                    self.parent.infoLabelText = NSLocalizedString("Smile detected!", comment: "")
                    self.parent.showPhotoButton = true
                }
            } else {
                self.parent.infoLabelText = NSLocalizedString("Smile to take a photo", comment: "")
                self.parent.showPhotoButton = false
            }
        }
    }
}
