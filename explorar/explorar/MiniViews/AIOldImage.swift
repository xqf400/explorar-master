//
//  AIOldImage.swift
//  explorar
//
//  Created by Fabian Kuschke on 18.08.25.
//

import SwiftUI
import OpenAI
import TelemetryDeck
import Drops

public struct AIOldImageView: View {
    @Binding var showing: Bool
    let poi: PointOfInterest
    let originalImage: UIImage
    let year: Int
    let imageName: String
    var onDismiss: (_ image: UIImage?) -> Void
    
    @State private var isAnimatingOut = false
    @State private var playDisintegrate = false
    
    private func startDismiss() {
        UIApplication.shared.isIdleTimerDisabled = false
        guard !isAnimatingOut else { return }
        isAnimatingOut = true
        DispatchQueue.main.async { playDisintegrate = true }
    }
    
    @State var loading = false
    @State var newImage: UIImage?
    private let editor = ImageEditor()

    private func runEdit() {
        if imageName.contains("1920") || imageName.contains("2120") {
            Drops.show(Drop(title: "Not possible with this image!"))
            startDismiss()
            return
        }
        UIApplication.shared.isIdleTimerDisabled = true
        if UserFire.shared.userFirebase == nil {
//            if !UserFire.shared.userFirebase!.isCreater {
//                Drops.show(Drop(title: "You are not a creator. Sorry you are not allowed to do this!"))
//                startDismiss()
//                return
//            }
        }
        TelemetryDeck.signal("generate ai image")
        loading = true
        let city = poi.city
        let poiName = poi.name
        let country = SharedPlaces.shared.currentCountry
        let formatedImageName = "\(imageName.replacing(".jpg", with: ""))_\(year).jpg"
        print("runEdit for \(city), \(poiName), \(country), \(formatedImageName) \(poi.creator)")
        editor.makeImageLookYearsAgo(from: originalImage, year: year, city: city, poi: poiName, country: country, apiKey: openAiKey) { result in
            switch result {
            case .success(let img):
                print("success got image")
//                if let creater = UserFire.shared.userFirebase?.isCreater {
//                    if creater {
                if poi.creator != "AI" {
                        FirebaseStorageService.shared.uploadImage(image: img, poiID: poi.id, imageName: formatedImageName) { result in
                            switch result  {
                            case .success:
                                print("successfully uploaded")
                                
                                    FirestoreService.shared.addImageToPOI(imageName: formatedImageName, poiID: poi.id) { result2 in
                                        switch result2  {
                                        case .success:
                                            print("successfully added to poi")
                                            self.newImage = img
                                            self.loading = false
                                            Drops.show(Drop(title: "Image generation successfully"))
                                        case .failure(let err):
                                            print("error adding \(err)")
                                            self.loading = false
                                            Drops.show(Drop(title: "error adding \(err)"))
                                            self.startDismiss()
                                        }
                                    }
                            case .failure(let err):
                                print("error uploading \(err)")
                                self.loading = false
                                Drops.show(Drop(title: "error uploading \(err)"))
                                //self.startDismiss()
                            }
                        }
                } else {
                    self.newImage = img
                    self.loading = false
                    self.startDismiss()
                    Drops.show(Drop(title: "Image generation successfully"))
                }
//                    } else {
//                        print("no creater")
//                        self.newImage = img
//                        self.loading = false
//                        Drops.show(Drop(title: "You are not a creator"))
//                        //self.startDismiss()
//                    }
//                } else {
//                    print("user not found")
//                    self.newImage = img
//                    self.loading = false
//                    Drops.show(Drop(title: "You are not a creator"))
//                    //self.startDismiss()
//                }
            case .failure(let err):
                print("error 2 \(err)")
                self.loading = false
                Drops.show(Drop(title: "error 2 \(err)"))
                //self.startDismiss()
            }
        }
    }
    
    // MARK: View
    public var body: some View {
        HStack {
            VStack {
                HStack(spacing: 12) {
                    Spacer().frame(width: 8)
                    if loading {
                        ProgressView()
                    }
                    Text(loading ? "The AI is generating the image in \(year). While you wait, you can play a round Tic Tac Toe." : "Generating finished")
                        .lineLimit(3)
                        .minimumScaleFactor(0.5)
                        .font(.headline)
                    Spacer().frame(width: 8)
                }
                .frame(height: 30)
                HStack {
                    Image(uiImage: originalImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .cornerRadius(16)
                        .clipped()
                    if newImage != nil {
                        Image(uiImage: newImage!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .cornerRadius(16)
                            .clipped()
                    }
                }
                TicTacToeView()
                    .frame(height: 360)
                Spacer().frame(height: 10)
                HStack {
                    Spacer().frame(width:20)
                    Button {
                        withAnimation {
                            startDismiss()
                        }
                    } label: {
                        Spacer()
                        Text(newImage == nil ? "Zurückkehren" : "Zurückkehren und betrachten")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .foregroundColor(Color.white)
                        Spacer()
                    }
                    .frame(width: 200)
                    Spacer().frame(width:20)
                }
                .frame(height: 30)
                .background(Color.blue)
                .cornerRadius(30)
                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                Spacer().frame(height: 10)
            }
            .overlay {
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(foregroundGradient)
        .cornerRadius(24)
        .shadow(radius: 10)
        .padding(.top, UIScreen.main.bounds.height * 0.08)
        .padding(.bottom, UIScreen.main.bounds.height * 0.08)
        .padding(.horizontal, UIScreen.main.bounds.width * 0.05)
        .onAppear {
            if FirestoreService.shared.settings.createAIImage {
                runEdit()
            } else {
                Drops.show(Drop(title: "Admin disabled generating AI Images, sorry!"))
            }
        }
        .disintegrationEffect(isDeleted: playDisintegrate) {
            isAnimatingOut = false
            playDisintegrate = false
            onDismiss(newImage)
        }
    }
}


import UIKit
// MARK: Image Editor class
final class ImageEditor {
    private var client: OpenAI?
    
    let oldPrompt1 = """
    Transform this photo into how this exact place on the photo would have looked around the year 1920. 
    Keep the same perspective, composition, and main structures, but reimagine all elements 
    to match the early 20th century:  
    - Replace modern cars with period-appropriate vehicles from the 1910s–1920s  
    - Replace modern clothing with 1920s fashion styles  
    - Remove modern signage, street lights, and road markings  
    - Adjust the building to match its 1920s architectural style and materials  
    - Remove any modern technology or infrastructure  
    - Adjust lighting, colors, and textures to match photographic style of the time, 
      with subtle sepia or black-and-white tones, slight film grain, and authentic 
      imperfections of old photographs.
    """

    let futurePrompt2 = """
        Transform this photo into how this exact place could look around the year 2125. 
        Keep the same perspective, composition, and main structures, but reimagine all elements 
        to match a futuristic, advanced society:
        - Update architecture with sleek, high-tech designs, futuristic materials, and glowing accents
        - Replace current vehicles with advanced, autonomous transportation like hovering cars or maglev pods
        - Replace people’s clothing with stylish, futuristic fashion and wearable technology
        - Add clean, sustainable energy elements such as solar glass, vertical gardens, or wind turbines
        - Replace road surfaces with advanced smart materials or illuminated pathways
        - Include subtle holographic displays, drones, and robotic assistants
        - Use bright, vibrant colors, dynamic lighting, and high-detail textures to convey a 
          highly advanced, optimistic future aesthetic
        """
    

    func makeImageLookYearsAgo(
        from image: UIImage,
        year: Int,
        city: String,
        poi: String,
        country: String,
        apiKey: String,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        print("makeImageLookYearsAgo \(city) \(poi) \(year)")

        let isLandscape = image.size.width >= image.size.height
        let targetSize = isLandscape ? CGSize(width: 1536, height: 1024)
                                     : CGSize(width: 1024, height: 1536)

        guard
            let basePNG = resizedPNG_exactPixels(image: image, to: targetSize)
        else {
            completion(.failure(ImageGenError.badImageData))
            return
        }

        // Example edit areas (tune for your photo)
        let roadRect = CGRect(x: 0, y: targetSize.height*0.55,
                              width: targetSize.width, height: targetSize.height*0.35)
        let skyRect  = CGRect(x: 0, y: 0,
                              width: targetSize.width, height: targetSize.height*0.25)

        guard
            let maskPNG = maskEditingRects(size: targetSize, editRects: [roadRect, skyRect])
        else {
            completion(.failure(ImageGenError.badImageData))
            return
        }

        let client = OpenAI(configuration: .init(token: apiKey, timeoutInterval: 180))
        self.client = client
        
        var prompt = """
        Transform only the transparent areas of the mask. Keep all opaque regions pixel-aligned and unchanged.

        Scene: \(poi), \(city), \(country), circa \(year).

        Requirements:
        - Preserve the exact camera perspective and the shapes/outlines of all protected buildings and the ground plane.
        - Replace modern cars with period-appropriate vehicles (1910s–1920s), horse carriages, and street furniture only where allowed by the mask.
        - Replace people’s clothing with 1920s fashion only in editable regions.
        - Remove modern signage, traffic lights, painted lane markings, LED lights, antennas, and overhead cables in editable regions.
        - Restore facade materials and storefront styling to early 20th-century appearance without changing building dimensions or window/door placements.
        - Overall look: early 20th-century photograph (subtle sepia or B&W, mild lens softness and film grain), but keep high realism.
        - Do not add any contemporary elements or alter the silhouettes of protected structures.
        """
        
        if year > 2025 {
            prompt = """
                Transform only the transparent areas of the mask. Keep all opaque regions pixel-aligned and unchanged.

                        Scene: \(poi), \(city), \(country), circa \(year).(optimistic, human-centered, clean technology).

                Goals:
                - Preserve the exact camera perspective, protected building silhouettes, ground plane, and skyline geometry.
                - Material upgrade: transparent solar glass, self-healing concrete, engineered timber/metal hybrids, adaptive façades with micro-shading.
                - Mobility: small autonomous EV pods and micro-shuttles; minimal road paint; smart pavement with subtle illuminated lane cues; a distant low-profile maglev/guideway is OK.
                - Street elements: wireless inductive charging pads, flush ground lighting, elegant wayfinding totems, e-paper signage; discrete AR beacons (no big floating UI).
                - People: \(year) fashion with integrated wearables; lightweight umbrellas/visors; a few service drones (small scale, not swarms).
                - Nature: mature trees, planters, green roofs, vertical gardens; water features with smart recycling.
                - Energy: building-integrated photovoltaics, solar canopies, small rooftop wind micro-turbines; no giant reactors.
                - Sky: clear air corridors; a couple of distant eVTOLs or drones sized to perspective.
                - Lighting & rendering: realistic global illumination, physically plausible reflections; crisp, vibrant color; high detail.

                Constraints (very important):
                - Do not alter sizes or positions of protected/opaque regions.
                - Keep historical landmarks recognizable; no demolition or radical reshaping.
                - No dystopian vibes, no cyberpunk grime, no alien megastructures, no Times-Square-style billboards.

                Match the original time of day and weather unless the mask includes the sky.

                """
        }


        let query = ImageEditsQuery(
            images: [.png(basePNG)],
            prompt: prompt,
            mask: maskPNG,
            model: .gpt_image_1,
            n: 1,
            quality: .high,
            user: "years-ago-transform"
        )

        print("sending imageEdits…")
        _ = client.imageEdits(query: query) { [weak self] result in
            defer { self?.client = nil }
            switch result {
            case .failure(let err):
                print("imageEdits failure: \(err)")
                self?.ensureMain(.failure(err), completion)
            case .success(let resp):
                print("imageEdits success; items: \(resp.data.count)")
                guard let first = resp.data.first else {
                    self?.ensureMain(.failure(ImageGenError.noResult), completion); return
                }

                if let urlString = first.url, let url = URL(string: urlString) {
                    self?.loadUIImage(from: url) { imgResult in
                        self?.ensureMain(imgResult, completion)
                    }
                    return
                }

                // 2) Base64 branch (SDKs differ on the property name; reflect to find it)
                if let b64 = ImageEditor.extractB64(from: first),
                   let data = Data(base64Encoded: ImageEditor.stripDataURLPrefix(b64)),
                   let ui = UIImage(data: data) {
                    self?.ensureMain(.success(ui), completion)
                    return
                }

                print("no url or base64 in ImagesResult: \(first)")
                self?.ensureMain(.failure(ImageGenError.noResult), completion)
            }
        }
    }
    
    private static func stripDataURLPrefix(_ s: String) -> String {
        if let r = s.range(of: "base64,") { return String(s[r.upperBound...]) }
        return s
    }

    private static func extractB64<T>(from item: T) -> String? {
        let mirror = Mirror(reflecting: item)
        for child in mirror.children {
            if let label = child.label?.lowercased(),
               (label.contains("b64") || label.contains("base64")),
               let str = child.value as? String {
                return str
            }
        }
        return nil
    }

    private func resizedPNG_exactPixels(image: UIImage, to size: CGSize) -> Data? {
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.opaque = false
        fmt.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: fmt)
        let img = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return img.pngData()
    }

    private func loadUIImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data, let ui = UIImage(data: data) else {
                completion(.failure(ImageGenError.badImageData)); return
            }
            completion(.success(ui))
        }.resume()
    }

    private func ensureMain<T>(_ result: Result<T, Error>, _ completion: @escaping (Result<T, Error>) -> Void) {
        if Thread.isMainThread { completion(result) }
        else { DispatchQueue.main.async { completion(result) } }
    }
    
    private func maskEditingRects(size: CGSize, editRects: [CGRect]) -> Data? {
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.opaque = false
        fmt.scale = 1.0                                     // exact pixels
        let r = UIGraphicsImageRenderer(size: size, format: fmt)
        let img = r.image { ctx in
            // Keep everything by default (opaque)
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Make the allowed edit regions transparent
            ctx.cgContext.setBlendMode(.clear)
            for rect in editRects {
                ctx.fill(rect)
            }
        }
        return img.pngData()
    }

}
