//
//  CameraView.swift
//  explorar
//
//  Created by Fabian Kuschke on 05.08.25.
//

import SwiftUI
import AVKit

class ScannerDelegate: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    
    @Published var scannedCode: String?
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        if let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            guard let code = object.stringValue else { return}
            scannedCode = code
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

struct CameraView: UIViewRepresentable {
    var frameSize: CGSize
    @Binding var session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIViewType(frame: CGRect(origin: .zero, size: frameSize))
        view.backgroundColor = .clear
        
        let cameraLayer = AVCaptureVideoPreviewLayer(session: session)
        cameraLayer.frame = .init(origin: .zero, size: frameSize)
        cameraLayer.videoGravity = .resizeAspectFill
        cameraLayer.masksToBounds = true
        view.layer.addSublayer(cameraLayer)
        
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator, action:
                #selector(context.coordinator.focus(_:)))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject {
        var parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        //Touch the screen for autofocus
        @objc func focus(_ gesture: UITapGestureRecognizer) {
            let touchPoint = gesture.location(in: gesture.view)
            
            // Perform autofocus at the tapped point
            if let device = AVCaptureDevice.default(for: .video) {
                do {
                    try device.lockForConfiguration()
                    device.focusPointOfInterest = touchPoint
                    device.focusMode = .autoFocus
                    device.unlockForConfiguration()
                } catch {
                    print("Error focusing: \(error.localizedDescription)")
                }
            }
        }
    }
}
