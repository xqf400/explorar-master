//
//  QRCodeScannerView.swift
//  explorar
//
//  Created by Fabian Kuschke on 05.08.25.
//

import SwiftUI
import AVKit
import Drops

struct QRcodeScannerView: View {
    
    // MARK: Vars
    @Environment(\.colorScheme) var colorScheme
    
    @State private var shouldShowRectangle = true
    @State private var scanAnimationIsRunning: Bool = false
    @State private var captureSession: AVCaptureSession = .init()
    @StateObject private var qrDelegate = ScannerDelegate()
    @State private var infoMessage: String = NSLocalizedString("Place the QR-Code inside the camera area", comment: "")
    @Binding var contentID: String?
    @Binding var isShowing: Bool
    @State private var isLoading = false
    @State private var textColor = Color.white
    @State private var notFound = false
    var notFoundMessage = "Not found"
    
    // MARK: Functions
    func barcodeNotFound() {
        isLoading = false
        infoMessage = notFoundMessage
        textColor = .red
    }
    
    func activateCamera() {
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
    }
    
    func checkPermissions() {
        Task {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                if captureSession.inputs.isEmpty {
                    setupCamera()
                } else {
                    activateCamera()
                }
            case .notDetermined:
                if await AVCaptureDevice.requestAccess(for: .video) {
                    setupCamera()
                } else {
                    infoMessage = "No camera access allowed!"
                    shouldShowRectangle.toggle()
                }
            case .denied, .restricted:
                infoMessage = "No camera access allowed!"
                shouldShowRectangle.toggle()
            default: break
            }
        }
    }
    
    func setupCamera() {
        do {
            guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                mediaType: .video,
                                                                position: .back).devices.first else {
                infoMessage = "No backcam available!"
                return
            }
            
            let input = try AVCaptureDeviceInput(device: device)
            let dataOutput = AVCaptureMetadataOutput()
            guard captureSession.canAddInput(input), captureSession.canAddOutput(dataOutput) else {
                infoMessage = "Input Error"
                return
            }
            captureSession.beginConfiguration()
            captureSession.addInput(input)
            captureSession.addOutput(dataOutput)
            dataOutput.metadataObjectTypes = [.qr]
            dataOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            captureSession.commitConfiguration()
            DispatchQueue.global(qos: .background).async {
                captureSession.startRunning()
            }
            withAnimation(.easeInOut(duration: 0.85).delay(0.3).repeatForever(autoreverses: true)) {
                scanAnimationIsRunning = true
            }
        } catch {
            infoMessage = error.localizedDescription
        }
    }
    
    // MARK: UI
    var body: some View {
        VStack(spacing: 12) {
            // MARK: Text
            Text(infoMessage)
                .font(.title)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .foregroundColor(textColor)
                .shadow(color: .black, radius: 1, x: 0, y: 1)
                .padding(.top, -10)
                .lineLimit(4)
            // MARK: CamView
            CameraView(frameSize: CGSize(width: 300, height: 300), session: $captureSession)
                .cornerRadius(8)
                .scaleEffect(0.9)
                .frame(width: 300, height: 300)
                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                //.shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
                .overlay(alignment: .top, content: {
                    if shouldShowRectangle {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 4)
                            .scaleEffect(0.9)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.8),
                                    radius: 8,
                                    x: scanAnimationIsRunning ? -15 : 15, y: 0)
                            .offset(x: scanAnimationIsRunning ? -(300*0.86)/2 : (300*0.86)/2)
                    }
                })
            // MARK: Close Button
            HStack {
                Spacer(minLength: 40)
                Button {
                    withAnimation {
                        isShowing = false
                    }
                } label: {
                    Spacer()
                    Text("Close")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .foregroundColor(colorScheme == .dark ?
                                         Color(UIColor.secondarySystemBackground)
                                         :Color(UIColor.tertiarySystemBackground))
                    Spacer()
                }
                Spacer(minLength: 40)
            }
            .frame(height: 60)
            .background(Color.green)
            .cornerRadius(30)
            .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
            //.shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
            .padding(.bottom, 10)
        }
        .padding()
        .onAppear{
            checkPermissions()
        }
        .onDisappear {
            captureSession.stopRunning()
        }
        .onChange(of: qrDelegate.scannedCode) { oldValue, newValue in
            if let scannedUrl = newValue {
                if let url = URL(string: scannedUrl),
                   url.host == "explor-ar.fun",
                   let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?
                    .first(where: { $0.name == "id" })?
                    .value {
                    
                    captureSession.stopRunning()
                    qrDelegate.scannedCode = nil
                    withAnimation(.easeInOut(duration: 0.85)) {
                        scanAnimationIsRunning = false
                        shouldShowRectangle.toggle()
                    }
                    print("id: ",id)
                    contentID = id
                    withAnimation {
                        isShowing = false
                    }
                } else {
                    print("QR does not contain a valid URL with ?id=")
                    Drops.show(Drop(title: "QR does not contain a valid URL with ?id="))
                }
            }
        }
    }
}

extension View {
    func presentationDetentsSheet(height: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            return self
                .presentationDragIndicator(.visible)
                .presentationBackground(
                    backgroundGradient
                )
                .presentationDetents([.height(height)])
        } else {
            return self
        }
    }
}
