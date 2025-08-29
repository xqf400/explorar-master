//
//  QRCodeView.swift
//  explorar
//
//  Created by Fabian Kuschke on 31.07.25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import TelemetryClient

struct QRCodeView: View {
    let url: String
    @State private var qrImage: UIImage? = nil
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        VStack(spacing: 20) {
            Text(url)
                .cornerRadius(8)
                .shadow(radius: 4)
            if let qrImage = qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 4)
            } else {
                ProgressView()
            }
            
            Button(action: saveToPhotos) {
                Label("Save QR Code", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .task {
            await generateQRCode()
        }
        .onAppear {
            TelemetryDeck.signal("QRCode_created")
        }
    }
    
    @MainActor
    private func generateQRCode() async {
        let data = Data(url.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        if let outputImage = filter.outputImage {
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrImage = UIImage(cgImage: cgImage)
            }
        }
    }
    
    private func saveToPhotos() {
        guard let image = qrImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}
