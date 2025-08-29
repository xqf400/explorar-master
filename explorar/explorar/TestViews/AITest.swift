//
//  AITest.swift
//  explorar
//
//  Created by Fabian Kuschke on 12.08.25.
//

import SwiftUI
import OpenAI
import PhotosUI
import Foundation
import UIKit
import AVFoundation

enum ImageGenError: Error {
    case missingAPIKey
    case noImageURLReturned
    case invalidURL
    case badImageData
    case imageEncodingFailed
    case noResult
}

struct AITest: View {
    @State var loading = false
    
    @State var returnText = ""
    
    @State var image = UIImage(systemName: "hourglass.circle")!
    @State var showErrorAlert = false
    @State var errorMessage: String = ""
    //upload image and change it
    @State private var pickedItem: PhotosPickerItem?
    @State private var original: UIImage?
    @State private var output: UIImage?
    
    // image recognize
    @State private var picked: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var resultText: String = "No animal identified"
    
    // MARK: create Text
    private func aiCreateTextTest() {
        loading = true
        let openAI = OpenAI(apiToken: openAiKey)
        Task {
            do {
                let query = ChatQuery(
                    messages: [
                        .user(.init(content: .string("What is a bear")))
                    ],
                    model: .gpt4_o
                )
                let result = try await openAI.chats(query: query)
                returnText = result.choices.first?.message.content ?? ""
                print(result.choices.first?.message.content ?? "")
                loading = false
            } catch {
                print("Error ai \(error.localizedDescription)")
                loading = false
            }
        }
    }
    
    // MARK: Generate POis
    @State private var resultsPOI: [PointOfInterest] = []
    @State private var showOverlay = false
    @State var showGame = false
    func getPOIsStuttgart() {
        print("getPOIsStuttgart")
        showGame = true
        showOverlay = true
        AIService.shared.getInterestingPlaces(in: "plochingen") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let pois):
                    self.resultsPOI = pois
                    self.showGame = false
                    print("Count: ",resultsPOI.count)
                    for poi in resultsPOI {
                        print("name:", poi.name)
                        print("images: ", poi.images)
                        print("question: ", poi.question)
                        print("answers: ", poi.answers)
                        print("correctIndex: ", poi.correctIndex)
                        print("latitude: ", poi.latitude)
                        print("longitude: ", poi.longitude)
                        print("shortInfos: ", poi.shortInfos)
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showGame = false
                    showErrorAlert = true
                }
            }
        }
    }


    
    // MARK: Summarize Text
    func summary() {
        AIService.shared.summarizeText(text: "Mein Haus wurde im 14. Jahrhundert erbaut und überblickt das Rheintal.") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let summary):
                    print(summary)
                case .failure(let error):
                    print(error)
                    loading = false
                }
            }
        }
        //        summarizeText(text: "text") { summary in
        //                            guard let summary else {
        //                                print("⚠️ Falling back to full text")
        //                                return
        //                            }
        //                        }
    }
    /*
    func summarizeText(text: String, completion: @escaping (String?) -> Void) {
        loading = true
        let openAI = OpenAI(apiToken: openAiKey)
        Task {
            do {
                let query = ChatQuery(
                    messages: [
                        .user(.init(content: .string("Please summarize this text in a way that's clear and suitable to be read aloud in the language it is written in:\n\n\(text)")))
                    ],
                    model: .gpt4_o
                )
                let result = try await openAI.chats(query: query)
                let summary = result.choices.first?.message.content ?? ""
                print(result.choices.first?.message.content ?? "")
                loading = false
                completion(summary)
            } catch {
                print("Error ai \(error.localizedDescription)")
                loading = false
                completion(nil)
            }
        }
    }*/
    
    // MARK: create Image
    private func aiCreateImageTest() {
        loading = true
        generateUIImage(prompt: "a bear on a couch") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self.image = image
                    loading = false
                case .failure(let error):
                    print("Error:", error)
                    loading = false
                }
            }
        }
    }
    
    func generateImageURL(
        prompt: String,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        
        let client = OpenAI(apiToken: openAiKey)
        let query = ImagesQuery(prompt: prompt, n: 1, size: ._1024)
        
        _ = client.images(query: query) { result in
            switch result {
            case .success(let response):
                guard let urlString = response.data.first?.url else {
                    completion(.failure(ImageGenError.noImageURLReturned)); return
                }
                guard let url = URL(string: urlString) else {
                    completion(.failure(ImageGenError.invalidURL)); return
                }
                print("got AI url: ", url)
                completion(.success(url))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func generateUIImage(
        prompt: String,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        generateImageURL(prompt: prompt) { urlResult in
            switch urlResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let url):
                URLSession.shared.dataTask(with: url) { data, _, error in
                    if let error = error { completion(.failure(error)); return }
                    guard let data, let image = UIImage(data: data) else {
                        completion(.failure(ImageGenError.badImageData)); return
                    }
                    print("Got AI image")
                    completion(.success(image))
                }.resume()
            }
        }
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
    
    // MARK: identifyAnimal
    func identifyAnimal() {
        loading = true
        guard let selectedImage, let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
            resultText = "No image data."
            loading = false
            return
        }
        let client = OpenAI(apiToken: openAiKey)
        
        let message = ChatQuery.ChatCompletionMessageParam.user(
            .init(content: .contentParts([
                .image(
                    .init(
                        imageUrl: .init(
                            imageData: imageData,
                            detail: ChatQuery.ChatCompletionMessageParam.ContentPartImageParam.ImageURL.Detail.high
                        )
                    )
                ),
                .text(.init(text: """
                    You are an art teacher evaluating a child's drawing. 
                    Identify the intended animal in the image.
                    
                    Scoring rules (strict):
                    - If the animal is clearly identifiable without doubt → rating = 10
                    - If mostly identifiable with minor uncertainty → rating = 9
                    - Anything else → 8 or below
                    
                    Be generous: internet-quality, realistic, or professional-looking images that match the animal perfectly should always get 10.
                    
                    Return ONLY valid JSON with:
                    {
                      "name": "<animal in lowercase>",
                      "rating": <integer from 1 to 10>
                    }
                    """))
            ]))
        )
        let schema: JSONSchema = .object([
            "type": AnyJSONDocument("object"),
            "properties": AnyJSONDocument([
                "name": AnyJSONDocument([
                    "type": AnyJSONDocument("string")
                ]),
                "rating": AnyJSONDocument([
                    "type": AnyJSONDocument("integer")
                ])
            ]),
            "required": AnyJSONDocument(["name", "rating"]),
            "additionalProperties": AnyJSONDocument(false)
        ])
        
        let schemaDef: JSONSchemaDefinition = .jsonSchema(schema)
        
        // desc for context
        let options = ChatQuery.StructuredOutputConfigurationOptions(
            name: "animal_rating",
            description: "For a child's drawing, identify the intended animal and give a generous, encouraging rating from 1–10 based on recognizability. Ignore colors.",
            schema: schemaDef,
            strict: true
        )
        let query = ChatQuery(
            messages: [message],
            model: .gpt4_o_mini,
            responseFormat: .jsonSchema(options)
        )
        
        _ = client.chats(query: query) { result in
            switch result {
            case .success(let response):
                if let text = response.choices.first?.message.content {
                    print("AI says:", text)
                    //                    DispatchQueue.main.async {
                    //                        resultText = text
                    //                        loading = false
                    //                    }
                    if let jsonData = text.data(using: .utf8) {
                        do {
                            let decoded = try JSONDecoder().decode(AnimalRating.self, from: jsonData)
                            DispatchQueue.main.async {
                                resultText = "Animal: \(decoded.name)\nRating: \(decoded.rating)/10"
                                loading = false
                            }
                        } catch {
                            
                        }
                    } else {
                        DispatchQueue.main.async {
                            resultText = "No structured result found."
                            loading = false
                        }
                    }
                } else {
                    print("No text output.")
                    DispatchQueue.main.async {
                        resultText = "No text output."
                        loading = false
                    }
                }
            case .failure(let error):
                print("Error:", error)
                DispatchQueue.main.async {
                    resultText = "Error: \(error)"
                    loading = false
                }
            }
        }
    }
    
    //MARK: 100 years ago
    func makeImageLookYearsAgo(
        from image: UIImage,
        yearsBack: Int = 100,
        apiKey: String,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        //        guard let png = image.pngData() else {
        //            ensureMain(.failure(ImageGenError.badImageData), completion); return
        //        }
        guard let png = pngDataWithAlpha(from: image) else {
            completion(.failure(ImageGenError.badImageData)); return
        }
        
        let client = OpenAI(apiToken: apiKey)
        
        let oldPrompt = """
        Transform this photo into how this exact place would have looked around the year 1920. 
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
        
        let futurePrompt = """
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
        
        let input: ImagesQuery.InputImage = .png(png)
        
        let query = ImageEditsQuery(
            images: [input],
            prompt: futurePrompt,
            mask: nil,
            n: 1,
        )
        
        _ = client.imageEdits(query: query) { result in
            switch result {
            case .failure(let err):
                ensureMain(.failure(err), completion)
                
            case .success(let resp):
                guard let urlString = resp.data.first?.url,
                      let url = URL(string: urlString) else {
                    ensureMain(.failure(ImageGenError.noResult), completion); return
                }
                loadUIImage(from: url) { imgResult in
                    ensureMain(imgResult, completion)
                }
            }
        }
    }
    
    //MARK: Variation: small, style-adjacent changes to the input image
    func generateImageVariation(
        from image: UIImage,
        apiKey: String,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        guard let png = image.pngData() else {
            ensureMain(.failure(ImageGenError.badImageData), completion); return
        }
        
        let client = OpenAI(apiToken: apiKey)
        
        let query = ImageVariationsQuery(image: png, n: 1, size: "1024x1024")
        
        _ = client.imageVariations(query: query) { result in
            switch result {
            case .failure(let err):
                ensureMain(.failure(err), completion)
                
            case .success(let resp):
                guard let urlString = resp.data.first?.url,
                      let url = URL(string: urlString) else {
                    ensureMain(.failure(ImageGenError.noResult), completion); return
                }
                loadUIImage(from: url) { imgResult in
                    ensureMain(imgResult, completion)
                }
            }
        }
    }
    
    func pngDataWithAlpha(from image: UIImage) -> Data? {
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        guard let cgImage = image.cgImage else { return nil }
        
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)
        
        guard let newCGImage = context.makeImage() else { return nil }
        let newUIImage = UIImage(cgImage: newCGImage)
        return newUIImage.pngData()
    }
    
    
    
    // MARK: funcs
    private func runEdit(yearsBack: Int) {
        guard let original else { return }
        loading = true
        makeImageLookYearsAgo(from: original, yearsBack: yearsBack, apiKey: openAiKey) { result in
            self.loading = false
            switch result {
            case .success(let img): self.output = img
            case .failure(let err):
                print("e2\(err.localizedDescription)")
            }
        }
    }
    
    private func runVariation() {
        guard let original else { return }
        loading = true
        generateImageVariation(from: original, apiKey: openAiKey) { result in
            self.loading = false
            switch result {
            case .success(let img): self.output = img
            case .failure(let err):
                print("e2\(err.localizedDescription)")
            }
        }
    }
    
    // MARK: View
    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    Text("hey ai")
                    Text(returnText)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .cornerRadius(16)
                        .clipped()
                    if let original {
                        Text("Original").font(.headline)
                        Image(uiImage: original).resizable().scaledToFit()
                            .frame(width: 200, height: 200)
                        
                    }
                    if let output {
                        Text("Result").font(.headline)
                        Image(uiImage: output).resizable().scaledToFit()                    .frame(width: 200, height: 200)
                        
                    }
                    
                    PhotosPicker("Pick a photo", selection: $pickedItem, matching: .images)
                    Spacer().frame(height: 30)
                    Button {
                        runEdit(yearsBack: 100)
                    } label: {
                        Text(loading ? "Working…" : "Make it look 100 years ago")
                    }
                    .disabled(original == nil || loading)
                    Spacer().frame(height: 30)
                    
                    Button {
                        runVariation()
                    } label: {
                        Text(loading ? "Working…" : "Variation")
                    }
                    .disabled(original == nil || loading)
                    Spacer().frame(height: 30)
                    
                    PhotosPicker("Pick a drawing", selection: $picked, matching: .images)
                        .onChange(of: picked) { _, newItem in
                            guard let newItem else { return }
                            Task {
                                do {
                                    if let data = try await newItem.loadTransferable(type: Data.self),
                                       let ui = UIImage(data: data) {
                                        await MainActor.run {
                                            self.selectedImage = ui
                                        }
                                    }
                                } catch {
                                    await MainActor.run {
                                        print("err5\(error.localizedDescription)")
                                    }
                                }
                            }
                        }
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                        Button {
                            identifyAnimal()
                        } label: {
                            Text("identify drawing animal")
                        }
                        .disabled(loading)
                        Text(resultText)
                    }
                    Spacer()
                    Text("POIS:")
                    Button {
                        getPOIsStuttgart()
                    } label: {
                        Text("Get AI POIs")
                    }

                    if resultsPOI.isEmpty {
                        Text("No results yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        List(resultsPOI, id: \.id) { poi in
                            HStack(spacing: 4) {
                                Text("\(poi.name)")
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                                    .foregroundColor(.blue)
                            }
                            .frame(height: 30)
                        }
                        .listStyle(.insetGrouped)
                        .frame(height: 300)
                    }
                    
                }
            }
            if loading {
                VStack {
                    Spacer()
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                    Spacer()
                }
            }
            if showOverlay {
                AIPOISLoadingOverlay(loading: $showGame) {
                    showOverlay = false
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .background(Color.gray)
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) {
                        await MainActor.run {
                            self.original = ui
                            self.output = nil
                        }
                    }
                } catch {
                    await MainActor.run {
                        print("err5\(error.localizedDescription)")
                    }
                }
            }
        }
        .onAppear {
            // aiCreateImageTest()
            // aiCreateTextTest()

        }
        .alert("Try again", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}
