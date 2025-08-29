//
//  PlaceView.swift
//  explorar
//
//  Created by Fabian Kuschke on 05.08.25.
//

import SwiftUI
import AVFoundation
import Drops
#if APPCLIP
import StoreKit
import UIKit
#else
import TelemetryDeck
#endif

struct ImagePlusName {
    let name: String
    let image: UIImage
}

struct PointOfInterestView: View {
    @Environment(\.colorScheme) var colorScheme
    let pointOfInterest: PointOfInterest
    @State private var translatedPOI: PointOfInterest?
    @State private var isTranslating = false
    let onDismiss: (_ value: Bool) -> Void
    @State private var isMovingAround = false
    @State private var challengeText = NSLocalizedString("Do Challenge", comment: "")
    
    @State private var images : [UIImage] = []
    @State private var imagesAndName : [ImagePlusName] = []
    @State private var imagesAreDownloading = false
    @State private var selectedCardIndex = 0
    
    @State private var nextView: AnyView?
    @State private var showNextView = false
    @State private var coordinator = UICoordinator(sampleItems: [])
    @State private var showOverlay = false
    @State private var showAiImage = false
    @State private var inForYears = 1920
    
    @State private var overlayKill = false
    
    var customTransition: AnyTransition {
        AnyTransition.asymmetric(insertion: .offset(y:50).combined(with: .opacity), removal: .offset(y: -50).combined(with: .opacity))
    }
    
    private func checkImage() {
#if APPCLIP
        Drops.show(Drop(title: "Not supported. Please download the app for this feature"))
#else
        if let targetData = images[selectedCardIndex].pngData() {
            if let match = imagesAndName.first(where: { $0.image.pngData() == targetData }) {
                if match.name.contains("_1920") || match.name.contains("_2120") {
                    Drops.show(Drop(title: "Selected image is a generated image. Creation can not be done."))
                }
            } else {
                print("no match")
            }
        } else {
            print("no image")
        }
#endif
    }
    
    // MARK: Dwnload images func
    func downloadImages() {
#if !APPCLIP
//                FirestoreService.shared.uploadPointOfInterest(point: pointOfInterest) { result in
//                    switch result {
//                    case .success(let bool):
//                        print("uploadPointOfInterest uploaded: \(bool)")
//                    case .failure(let error):
//                        print("Error uploadPointOfInterest: \(error.localizedDescription)")
//                    }
//                }
        /*
        let poi = PointOfInterest(
            id: "stuttgartp7",
            shortInfos: ["1843 gegründet","ca 5000 Gemälde und Plastiken"],
            text: """
            Die Staatsgalerie Stuttgart ist eines der wichtigsten Kunstmuseen Baden-Württembergs und eine der bedeutendsten Kunstsammlungen Deutschlands. Sie wurde ursprünglich von König Wilhelm I. von Württemberg als Museum der Bildenden Künste gegründet. Der 1843 eröffnete Gründungsbau von Gottlob Georg Barth, die klassizistische Alte Staatsgalerie, zeigt Malerei ab dem Hochmittelalter sowie Skulpturen ab dem 19. Jahrhundert. Außerdem verfügt sie über eine umfangreiche graphische Sammlung. Der 1984 eröffnete Erweiterungsbau von James Stirling, die postmoderne Neue Staatsgalerie, gilt als Meisterwerk dieses Baustils in Deutschland.
            Neue Staatsgalerie

            Blick in den Innenhof der Neuen Staatsgalerie

            Fensterfront des Foyers der Neuen Staatsgalerie (Foto: 2009)

            Henry Moore: Die Liegende, am Haupteingang zur Neuen Staatsgalerie (Foto: 2006)
            1974 führte das Land Baden-Württemberg einen allgemeinen Ideenwettbewerb für das Museumsgelände durch. 1977 wurde ein internationaler beschränkter Wettbewerb für einen Erweiterungsbau zur Alten Staatsgalerie ausgeschrieben. Neben den sieben Preisträgern von 1974, darunter Günter Behnisch, wurden vier Ausländer eingeladen. Aus dem Wettbewerb ging der Entwurf des Londoner Büros James Stirling, Michael Wilford & Associates einstimmig als Sieger hervor. Am 9. März 1984 wurde die Neue Staatsgalerie eingeweiht. Sie gilt heute als eines der bedeutendsten Werke der Postmodernen Architektur in Deutschland. 1985 wurde vor dem Haupteingang die Skulptur Die Liegende von Henry Moore installiert.

            Die unkonventionelle Architektur des Baus war zunächst sowohl beim Fachpublikum als auch in der breiten Öffentlichkeit umstritten. Ironisch verfremdete historisierende Bauformen und Verkleidungen im Wechsel aus Travertin und Sandstein kontrastieren mit grellgrünen Fenstern, bunten Stahlträgern und pink-blauen Handläufen. Die internationale Fachpresse reagierte überwiegend positiv. Aber führende Architekten wie Frei Otto und Architekturkritiker, wie der Österreicher Friedrich Achleitner, warfen Stirling die Monumentalität und die vielen historischen Zitate in seinem Bau vor – ein Tabubruch, weil die deutsche Architektur der Nachkriegszeit, in Abgrenzung zur Architektur der Nationalsozialisten, allem Monumentalen und Historisierenden aus dem Wege ging. Stirling konterte die Kritik: „Wir hoffen, daß der Bau… monumental geworden ist, weil Monumentalität in der Tradition öffentlicher Bauten liegt. Aber ebenso hoffen wir, daß er informell und ‚populistisch‘, volkstümlich, geworden ist.“ ([4]) Die Besucherzahlen stiegen im ersten Jahr nach der Eröffnung auf Platz zwei der deutschen Besucherstatistik.
            """,
            images: ["stuttgartp7_image1.jpg", "stuttgartp7_image2.jpg", "stuttgartp7_image3.jpg"],
            name: "Staatsgalerie 2",
            city: "Stuttgart",
            challenge: "Suche das Bild",
            challengeId: 2,
            latitude: 48.77873632138373,
            longitude: 9.179558296366295,
            modelName: "dog1",
            question: "Welches Tier versteckt sich hier?",
            answers: ["Hund"],
            correctIndex: 1,
            poiLanguage: "de",
            creator: "Test"
        )
        
        FirestoreService.shared.uploadPointOfInterest(point: poi) { result in
            switch result {
            case .success(let bool):
                print("uploadPointOfInterest uploaded: \(bool)")
            case .failure(let error):
                print("Error uploadPointOfInterest: \(error.localizedDescription)")
            }
        }*/

        
#endif
        var imageCount = 0
        let sortedImageNames = pointOfInterest.images.sorted()
        if sortedImageNames.count == 0 {
            imagesAreDownloading = false
        }
        for imageName in sortedImageNames {
            downloadFirebaseImage(name: imageName, folder: "images/\(pointOfInterest.id)") { image in
                DispatchQueue.main.async {
                    if pointOfInterest.challengeId == 5 {
                        if !imageName.contains("_image1.jpg")  {
                            images.append(image)
                        }
                    } else {
                        images.append(image)
                    }
                    imagesAndName.append(ImagePlusName(name: imageName, image: image))
                    imageCount += 1
                    if pointOfInterest.images.count == imageCount {
                        withAnimation {
                            let items = imagesAndName.enumerated().map { (idx, img) in
                                DetailImage(id: "\(idx)", title: img.name, image: img.image, previewImage: img.image)
                            }
                            coordinator.items = items
                            imagesAreDownloading = false
                            let time = Date.now.formatted(
                                Date.FormatStyle()
                                    .hour(.twoDigits(amPM: .omitted))
                                    .minute(.twoDigits)
                                    .second(.twoDigits)
                            )
                            print("\(time) images are downloaded \(images.count)")
                            Timer.scheduledTimer(withTimeInterval: 1.6, repeats: false) { _ in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    overlayKill = true
                                }
                            }
                        }
                    }
                }
            } failure: { errorString in
                print("Download imageName \(imageName) failed: \(errorString)")
                Drops.show(Drop(title: "Download imageName \(imageName) failed: \(errorString)"))
                imagesAreDownloading = false
            }
        }
    }
#if !APPCLIP // appclip hat noch keine ki
    // MARK: getImagesFromWiki
    func getImagesFromWiki() {
        print("getImagesFromWiki")
        AIService.shared.fetchWikipediaImages(for: translatedPOI!.name.replacingOccurrences(of: " (AI)", with: "")) { result1 in
            translatedPOI!.images = result1
            print("Count \(result1.count)")
            if result1.count == 0 {
                imagesAreDownloading = false
            } else {
                downloadURLImages(downloadImages: result1)
            }
        }
    }
#endif
    // MARK: downloadURLImages
    func downloadURLImages(downloadImages: [String]) {
        print("downloadURLImages \(downloadImages.count)")
        print("Todo save and load images local if available")
        if downloadImages.count == 0 {
            imagesAreDownloading = false
            return
        }
        var count = 0
        for imageName in downloadImages {
            downloadURLImage(from: imageName) { uiImage in
                DispatchQueue.main.async {
                    if let img = uiImage {
                        images.append(img)
                        imagesAndName.append(ImagePlusName(name: imageName, image: img))
                    } else {
                        print("no image")
                        Drops.show(Drop(title: "no image"))
                    }
                    count += 1
                    if count == downloadImages.count {
                        withAnimation {
                            let items = imagesAndName.enumerated().map { (idx, img) in
                                DetailImage(id: "\(idx)", title: img.name, image: img.image, previewImage: img.image)
                            }
                            coordinator.items = items
                            imagesAreDownloading = false
                            print("images from urls are downloaded \(images.count)")
                        }
                    }
                }
            }
        }
    }
    
    func downloadURLImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            Drops.show(Drop(title: "Invalid URL: \(urlString)"))
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Download error for \(urlString):", error.localizedDescription)
                completion(nil)
                return
            }
            
            guard let data = data, let uiImage = UIImage(data: data) else {
                print("Could not decode image at \(urlString)")
                Drops.show(Drop(title: "Could not decode image at \(urlString)"))
                completion(nil)
                return
            }
            completion(uiImage)
        }.resume()
    }
    
    
    // MARK: Speak
    class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
        var didFinish: () -> Void
        init(didFinish: @escaping () -> Void) {
            self.didFinish = didFinish
        }
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            didFinish()
        }
    }
    @State private var audioDelegate: AudioPlayerDelegate?
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var aiIsLoadingAudio = false
    
    func speak() {
#if APPCLIP
        let utterance = AVSpeechUtterance(string: translatedPOI!.text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
        print("read aloud")
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            print("\(voice.language): \(voice.name) [\(voice.quality.rawValue)]")
        }
#else
        let name = "\(pointOfInterest.id)_\(getDeviceLanguage()).mp3"
        do {
            let docs = try FileManager.default.url(for: .libraryDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: true)
            let folderURL = docs.appendingPathComponent(pointOfInterest.id, isDirectory: true)
            
            if !FileManager.default.fileExists(atPath: folderURL.path) {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            }
            
            let audioURL = folderURL.appendingPathComponent(name)
            
            if FileManager.default.fileExists(atPath: audioURL.path) {
                player = try AVAudioPlayer(contentsOf: audioURL)
                let delegate = AudioPlayerDelegate { aiIsLoadingAudio = false }
                audioDelegate = delegate
                player!.delegate = delegate
                player!.play()
                print("plays from local")
            } else {
                if !FirestoreService.shared.settings.createAIAudio {
                    Drops.show(Drop(title: "Admin disabled generating AI Audio, sorry!"))
                    aiIsLoadingAudio = false
                    return
                }
                aiIsLoadingAudio = true
                AIService.shared.summarizeText(text: translatedPOI!.text) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let summary):
                            AIService.shared.downloadVoiceMp3(summary, to: audioURL) { result in
                                switch result {
                                case .success(let url):
                                    print("Saved to:", url.path)
                                    do {
                                        player = try AVAudioPlayer(contentsOf: url)
                                        let delegate = AudioPlayerDelegate {
                                            isPlaying = false
                                        }
                                        audioDelegate = delegate
                                        player!.delegate = delegate
                                        player!.play()
                                        isPlaying = true
                                        self.aiIsLoadingAudio = false
                                        print("plays audio after fetching from AI")
                                    } catch {
                                        print("Playback error: \(error.localizedDescription)")
                                        Drops.show(Drop(title: "Playback error: \(error.localizedDescription)"))
                                    }
                                case .failure(let error):
                                    print("TTS error: \(error.localizedDescription)")
                                    Drops.show(Drop(title: "TTS error: \(error.localizedDescription)"))
                                }
                            }
                        case .failure(let error):
                            print("Download voice \(error)")
                            Drops.show(Drop(title: "TTS error: \(error.localizedDescription)"))
                            AIService.shared.downloadVoiceMp3(translatedPOI!.text, to: audioURL) { result in
                                switch result {
                                case .success(let url):
                                    print("Saved to:", url.path)
                                    do {
                                        player = try AVAudioPlayer(contentsOf: url)
                                        let delegate = AudioPlayerDelegate {
                                            isPlaying = false
                                        }
                                        audioDelegate = delegate
                                        player!.delegate = delegate
                                        player!.play()
                                        isPlaying = true
                                        self.aiIsLoadingAudio = false
                                        print("plays audio after fetching from AI")
                                    } catch {
                                        print("Playback error: \(error.localizedDescription)")
                                    }
                                case .failure(let error):
                                    print("TTS error: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            print("Speak error:", error)
            Drops.show(Drop(title: "Speak error: \(error)"))
        }
#endif
    }
    
    //MARK: showFullAppPopup
#if APPCLIP
    func showFullAppPopup() {
        Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in

            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                let config = SKOverlay.AppClipConfiguration(position: .bottom)
                let overlay = SKOverlay(configuration: config)
                overlay.present(in: scene)
            }
        }
    }
#endif
    
    // MARK: View
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: true) {
                if let translatedPOI = translatedPOI {
                    VStack(alignment: .leading, spacing: 10) {
                        Spacer().frame(height:2)
                        // MARK: Infos
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Info")
                                    .minimumScaleFactor(0.5)
                            }
                            .frame(height: 20)
                            HStack {
                                Spacer().frame(width: 5)
                                VStack(alignment: .leading) {
                                    ScrollView(.vertical, showsIndicators: true) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            ForEach(translatedPOI.shortInfos, id: \.self) { info in
                                                Text("- \(info)")
                                                    .multilineTextAlignment(.leading)
                                                    .minimumScaleFactor(0.5)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                            .frame(height: 70)
                            // .padding(.horizontal, 10)
                        } // V
                        .cardStyle(color: colorScheme == .dark ? Color.black : Color.white, opacity: 0.1)
                        // MARK: Images
                        VStack {
                            if !imagesAreDownloading && images.count > 0 {
                                HStack {
                                    Spacer()
                                    CardStackView(imagesAndNames: imagesAndName, selectedCardIndex: $selectedCardIndex, imageSize: CGSize(width: 220, height: 300), coordinator: coordinator)
                                        .transition(customTransition.combined(with: .scale(scale: 0, anchor: .leading)))
                                        .animation(.easeInOut, value: coordinator.items)
                                    Spacer()
                                }
                                Spacer().frame(height: 20)
#if !APPCLIP
                                HStack(spacing: 10) {
                                    // MARK: 100 Years button
                                    Button {
                                        if translatedPOI.creator == "AI" {
                                            Drops.show(Drop(title: "Images can not be generated for AI generated POIs."))
                                            return
                                        }
                                        inForYears = 1920
                                        showOverlay = true
                                        showAiImage = true
                                        checkImage()
                                    } label: {
                                        Text("100 years ago")
                                            .fontWeight(.semibold)
                                            .minimumScaleFactor(0.4)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 4)
                                            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                                    }
                                    .background(foregroundGradient)
                                    .cornerRadius(30)
                                    .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                                    .shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
                                    Button {
                                        if translatedPOI.creator == "AI" {
                                            Drops.show(Drop(title: "Images can not be generated for AI generated POIs."))
                                            return
                                        }
                                        inForYears = 2120
                                        showOverlay = true
                                        showAiImage = true
                                        checkImage()
                                    } label: {
                                        Text("100 years ahead")
                                            .fontWeight(.semibold)
                                            .minimumScaleFactor(0.4)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 4)
                                            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                                    }
                                    .background(foregroundGradient2)
                                    .cornerRadius(30)
                                    .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                                    .shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
                                }
                                .frame(height: 30)
                                .transition(customTransition.combined(with: .scale(scale: 0, anchor: .leading)))
                                .animation(.easeInOut, value: coordinator.items)
#endif
                            } else {
                                HStack {
                                    Spacer()
                                    Image(systemName: "photo.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 140, height: 140)
                                        .cornerRadius(16)
                                        .clipped()
                                        .opacity(0.5)
                                    //                                .redacted(reason: !imagesAreDownloading ? .placeholder : [])
                                    Spacer()
                                }
                                Spacer().frame(height: 10)
                            }
                        } // V
                        .cardStyle(color: colorScheme == .dark ? Color.black : Color.white, opacity: 0.1)
                        // MARK: Challenges
                        VStack(alignment: .leading) {
                            VStack(alignment: .leading) {
                                // Spacer().frame(width: 16)
                                Text("Challenge:")
                                    .font(.system(size: 18, weight: .bold, design: .default))
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                Text("\(translatedPOI.challenge) \(UserDefaults.standard.bool(forKey: pointOfInterest.id) ? NSLocalizedString("(already completed)", comment: "") : "")")
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(2)
                            }
                            .frame(height: 50)
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, dash: [140, 400], dashPhase: isMovingAround ? 220 : -220
                                                                    ))
                                    .frame(height: 36)
                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .yellow, .green, .blue, .white, .red, .cyan]),startPoint: .trailing, endPoint: .leading))
                                //                                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                                //                                .shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
                                Button {
                                    print("Do Challenge")
                                    if translatedPOI.challengeId == 1 {
                                        nextView = AnyView(SmileView(poiID: translatedPOI.id, poiName: translatedPOI.name))
                                        showNextView = true
                                    } else if translatedPOI.challengeId == 2 {
                                        nextView = AnyView(LoadExperienceView(pointOfInterest: translatedPOI))
                                        showNextView = true
                                    } else if translatedPOI.challengeId == 4 {
                                        let hangmanQuestion = HangmanQuestion(secretWord: translatedPOI.answers[0], helpText: translatedPOI.question)
                                        nextView = AnyView(HangmanView(hangmanQuestion: hangmanQuestion, poiID: translatedPOI.id))
                                        showNextView = true
                                    } else if translatedPOI.challengeId == 3 {
                                        let question = QuizQuestion(question: translatedPOI.question, options: translatedPOI.answers, correctIndex: translatedPOI.correctIndex)
                                        nextView = AnyView(QuizView(question: question, poiID: translatedPOI.id)
                                            .background {
                                                backgroundGradient
                                                    .ignoresSafeArea(.all)
                                            })
                                        showNextView = true
                                    } else if translatedPOI.challengeId == 5 {
                                        if images.count > 0 {
                                            if let imageAndName = imagesAndName.first(where: { $0.name.contains("_image1.jpg") }) {
                                                let recognizeItem = RecognizeItem(question: translatedPOI.challenge, image: imageAndName.image, answers: translatedPOI.answers)
                                                nextView = AnyView(RecognizeImageView(recognizeItem: recognizeItem, poiID: translatedPOI.id))
                                                nextView = AnyView(RecognizeImageView(recognizeItem: recognizeItem, poiID: translatedPOI.id))
                                                showNextView = true
                                            }
                                        } else {
                                            print("No image")
                                            showNextView = false
                                            Drops.show(Drop(title: "No image"))
                                        }
                                    } else if translatedPOI.challengeId == 6 {
                                        nextView = AnyView(DrawView(animalName: translatedPOI.answers[0], challenge: translatedPOI.challenge, poiID: translatedPOI.id, poiName: translatedPOI.name))
                                        showNextView = true
                                        
                                    }else {
                                        print("Id not found \(translatedPOI.challengeId)")
                                    }
                                    
                                } label: {
                                    Text(challengeText)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .minimumScaleFactor(0.5)
                                        .padding(.vertical, 4)
                                        .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                                }
                                .frame(height: 30)
                                .background(foregroundGradient)
                                .cornerRadius(30)
                                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                                .shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
                            }// Zstack
                            .onAppear {
                                isMovingAround = true
                            }
                            .animation(
                                .linear(duration: 4)
                                .repeatForever(autoreverses: false),
                                value: isMovingAround
                            )
                        } //V
                        .cardStyle(color: colorScheme == .dark ? Color.black : Color.white, opacity: 0.1)
                        // Spacer().frame(height: 10)
                        VStack(alignment: .leading) {
                            // MARK: Read
                            HStack {
                                Button {
                                    if let player = player {
                                        if isPlaying {
                                            player.pause()
                                        } else {
                                            player.play()
                                        }
                                        isPlaying.toggle()
                                    } else {
                                        speak()
                                    }
                                } label: {
                                    Text(isPlaying ? "Pause" : "Read out the summary")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                        .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                                }
                                .frame(height: 30)
                                .background(foregroundGradient)
                                .cornerRadius(30)
                                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                                .shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
                            }
                            Spacer().frame(height: 10)
                            // MARK: Text
                            Text(translatedPOI.text)
                                .font(.body)
                                .minimumScaleFactor(0.5)
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                        } // V
                        .cardStyle(color: colorScheme == .dark ? Color.black : Color.white, opacity: 0.1)

                    } // vstack
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 10) // links rechts Platz
                }
            } // scrollview
        }// zstack
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            backgroundGradient
                .ignoresSafeArea(.all)
        }
        .loadingOverlay(isPresented: $aiIsLoadingAudio, items: [
            LoadingItem(name: NSLocalizedString("text", comment: ""), color: .green),
            LoadingItem(name: NSLocalizedString("audio", comment: ""), color: .blue)],
                        baseText: NSLocalizedString("generating", comment: ""))
        //.loadingOverlay(isPresented: $isTranslating, baseText: NSLocalizedString("translating", comment: ""))
        .loadingOverlay(isPresented: $imagesAreDownloading, killSwitch: $overlayKill)
        .overlay{
            if showOverlay {
                if let targetData = images[selectedCardIndex].pngData() {
                    if let match = imagesAndName.first(where: { $0.image.pngData() == targetData }) {
                        // Not working
                        //                        if !match.name.contains("_1920") || !match.name.contains("_2120") {
#if !APPCLIP
                        AIOldImageView(showing: $showAiImage, poi: pointOfInterest, originalImage: match.image, year: inForYears, imageName: match.name) { image in
                            print("return from ai")
                            showOverlay = false
                            guard let img = image else{
                                print("no image from ai")
                                return
                            }
                            withAnimation {
                                images.append(img)
                                let items = imagesAndName.enumerated().map { (idx, img) in
                                    DetailImage(id: "\(idx)", title: img.name, image: img.image, previewImage: img.image)
                                }
                                coordinator.items = items
                            }
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.90)
                        .transition(.opacity)
                        .zIndex(1)
#endif
                        // }
                    } else {
                        let x = print("no image found 1")
                    }
                } else {
                    let x = print("no image2")
                }
            }
            if coordinator.selectedItem != nil && coordinator.animateView {
                withAnimation {
                    Detail()
                        .environment(coordinator)
                        .transition(.opacity)
                        .zIndex(100)
                        .background(backgroundGradient
                            .ignoresSafeArea(.all))
                }
            }
        }
        .navigationDestination(isPresented: $showNextView) {
            nextView
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        //.toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarHidden(coordinator.selectedItem != nil && coordinator.animateView)
        .translatePOI1(pointOfInterest, isTranslating: $isTranslating) { result in
            isTranslating = false
            switch result {
            case .success(let poi):
                withAnimation(.bouncy) {
                    translatedPOI = poi
                }
                print("Image count2 \(pointOfInterest.images.count)")
                if poi.images.count > 0 {
                    if poi.creator == "AI" {
                        downloadURLImages(downloadImages: poi.images)
                    } else {
                        downloadImages()
                    }
                } else {
                    if poi.creator == "AI" {
#if !APPCLIP
                        getImagesFromWiki()
                        #else
                        imagesAreDownloading = false
#endif
                    } else {
                        imagesAreDownloading = false
                    }
                }
            case .failure(let error):
                withAnimation(.bouncy) {
                    translatedPOI = pointOfInterest
                }
                print("Translation Error \(error.localizedDescription)")
                // errorMessage = error.localizedDescription
                Drops.show(Drop(title: "Translation Error \(error.localizedDescription)"))
                print("Image count1 \(pointOfInterest.images.count)")
                if pointOfInterest.images.count > 0 {
                    if pointOfInterest.creator == "AI" {
                        downloadURLImages(downloadImages: pointOfInterest.images)
                    } else {
                        downloadImages()
                    }
                } else {
                    if pointOfInterest.creator == "AI" {
#if !APPCLIP
                        getImagesFromWiki()
                        #else
                        imagesAreDownloading = false
#endif
                    } else {
                        imagesAreDownloading = false
                    }
                }
            }
        }
        .onChange(of: showNextView, { oldValue, newValue in
            print("showNextView changed")
            if UserDefaults.standard.bool(forKey: pointOfInterest.id) {
                challengeText = NSLocalizedString("Do challenge again", comment: "")
            }
        })
        // MARK: onAppear
        .onAppear{
            print("Appear")
            if UserDefaults.standard.bool(forKey: pointOfInterest.id) {
                challengeText = NSLocalizedString("Do challenge again", comment: "")
            }
            if images.count == 0 {
                imagesAreDownloading = true
            }
            if translatedPOI != nil && pointOfInterest.images.count == 0 {
                imagesAreDownloading = false
            }
            isMovingAround = true
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                isMovingAround.toggle()
            }
#if APPCLIP
            showFullAppPopup()
#else
            SharedPlaces.shared.locationManager.stopUpdatingLocation()
            TelemetryDeck.signal("Show_POI")
            
            if UserFire.shared.weeklyChallenges?.challenge1 == "1" {
                UserFire.shared.updateWeeklyChallenge(id: "1")
            }
            if UserFire.shared.weeklyChallenges?.challenge2 == "1" {
                UserFire.shared.updateWeeklyChallenge(id: "2")
            }
            if UserFire.shared.weeklyChallenges?.challenge3 == "1" {
                UserFire.shared.updateWeeklyChallenge(id: "3")
            }
            if UserFire.shared.dailyChallenges?.challenge1 == "1" {
                UserFire.shared.updateDailyChallenge(id: "1")
            }
            if UserFire.shared.dailyChallenges?.challenge2 == "1" {
                UserFire.shared.updateDailyChallenge(id: "2")
            }
            if UserFire.shared.dailyChallenges?.challenge3 == "1" {
                UserFire.shared.updateDailyChallenge(id: "3")
            }
            FirestoreService.shared.addVistitedPOI(poiId: pointOfInterest.id)
            FirestoreService.shared.addVistitedCity(cityId: pointOfInterest.city)
            
            print("Images count \(pointOfInterest.images.count)")
#endif
        }
        .onDisappear {
        }
        .navigationTitle(pointOfInterest.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
#if !APPCLIP
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    onDismiss(false)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(Color.white)
                }
            }
        }
#endif
    }
}

