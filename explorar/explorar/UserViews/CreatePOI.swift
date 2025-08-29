//
//  CreatePOI.swift
//  explorar
//
//  Created by Fabian Kuschke on 05.09.25.
//

import SwiftUI
import UniformTypeIdentifiers
import Drops

enum Challenge: Int, CaseIterable, Identifiable {
    case smile = 1, arView = 2, quiz = 3, hangman = 4, recognizeImage = 5, drawView = 6
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .smile: return "1Smile"
        case .arView: return "2ARView"
        case .quiz: return "3Quiz"
        case .hangman: return "4Hangman"
        case .recognizeImage: return "5RecognizeImage"
        case .drawView: return "6DrawView"
        }
    }
}

struct CreatePOIView: View {
    // Gemeinsame Felder
    @State private var id: String = ""
    @State private var shortInfo: String = ""
    @State private var text: String = ""
    @State private var imagesText: String = ""     // nur Anzeige
    @State private var name: String = ""
    @State private var challengeText: String = ""  // per Challenge vorgegeben
    @State private var challenge: Challenge = .smile
    @State private var poiLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
    @State private var creator: String = "none"

    // Challenge-spezifisch
    @State private var modelName: String = ""      // nur AR (2)
    @State private var question: String = ""       // 3,4 (5 keine Frage; 2 optional)
    @State private var answersText: String = ""    // kommagetrennt
    @State private var correctIndex: Int = 1       // 1-basiert im UI (nicht genutzt bei 5)

    // Steuerung
    @State private var showImporter = false
    @State private var uploading = false
    @State private var errorText: String?
    @ObservedObject var userFire = UserFire.shared
    @ObservedObject private var sharedPlaces = SharedPlaces.shared
    @State var poiCreated = false

    var body: some View {
        Form {
            // MARK: Picker
            Section("Aufgabe") {
                Picker("Typ", selection: $challenge) {
                    ForEach(Challenge.allCases) { c in Text(c.title).tag(c) }
                }
                .pickerStyle(.segmented)
                .onChange(of: challenge) { _, newValue in
                    applyDefaults(for: newValue)
                }
            }

            // MARK: Allgemein
            Section("Allgemein") {
                TextField("POI-ID (auto)", text: $id)
                    .textInputAutocapitalization(.never)
                    //.disabled(true)
                TextField("Name", text: $name)
                TextField("Kurzinfos (mit , trennen)", text: $shortInfo)
                    .lineLimit(1...6)
                TextField("Beschreibung (Text)", text: $text, axis: .vertical)
                    .lineLimit(1...10)

                NavigationLink("Go to Image Uploader") {
                    ImageUploaderView(uploadedImageNamesText: $imagesText, cityName: id, challengeID: challenge.rawValue)
                }
                Text(imagesText.isEmpty ? "Keine Bilder ausgewählt" : imagesText)
                    .foregroundStyle(imagesText.isEmpty ? .secondary : .primary)
                    .lineLimit(3)
            }

            // MARK: Challenge
            Section("Aufgabe-Angaben") {
                switch challenge {
                case .smile:
                    Text(challengeText)
                        .foregroundStyle(.secondary)
                case .quiz:
                    Text(challengeText)
                        .foregroundStyle(.secondary)
                case .hangman:
                    Text(challengeText)
                        .foregroundStyle(.secondary)
                case .arView, .recognizeImage, .drawView:
                    TextField("Aufgabetext", text: $challengeText)
                        .lineLimit(1...6)
                }
                challengeSpecificFields
            }

            // MARK: Metadaten
            Section("Metadaten") {
                HStack { Text("Sprache"); Spacer(); Text(poiLanguage).foregroundStyle(.secondary) }
                HStack { Text("Ersteller"); Spacer(); Text(creator).foregroundStyle(.secondary) }
            }

            // MARK: Upload POI
            Section {
                Button {
                    Task { await buildAndUpload() }
                } label: {
                    if uploading { ProgressView() } else { Text("POI hochladen") }
                }
                .disabled(uploading)

                if let msg = errorText {
                    Text(msg).foregroundStyle(.red)
                }
            }
        }
        .overlay {
            if uploading {
                ProgressView("Uploading POI...").padding()
            }
        }
        .navigationTitle("POI erstellen")
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.usdz],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result) { success, url in
                if success, let url { print("Saved modell  at \(url)") }
                else { Drops.show(Drop(title: "Failed url")) }
            }
        }
        .onAppear {
            poiLanguage = getDeviceLanguage()
            creator = userFire.userFirebase?.email ?? "none"
            id = makeAutomaticId()
            applyDefaults(for: challenge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            backgroundGradient
                .ignoresSafeArea(.all)
        }
    }

    // MARK: Challenge Felder
    @ViewBuilder
    private var challengeSpecificFields: some View {
        switch challenge {
        case .smile:
            EmptyView()
        case .arView:
            Section {
                HStack {
                    Text("Modell")
                    Spacer()
                    Text(modelName.isEmpty ? "Kein Modell gewählt" : modelName)
                        .foregroundStyle(modelName.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                }

                Button("Pick USDZ") { showImporter = true }

                NavigationLink("Place object in AR") {
                    CreateExperienceView(placeName: id, modelName: modelName)
                }
                .disabled(modelName.isEmpty)

                TextField("Frage", text: $question, axis: .vertical)
                    .lineLimit(1...6)
                TextField("Antwort (ein Wort)", text: $answersText)
            }


        case .quiz:
            VStack(alignment: .leading, spacing: 12) {
                TextField("Frage", text: $question)
                    .lineLimit(1...6)
                TextField("Antworten (4, mit , trennen)", text: $answersText)
                    .lineLimit(1...6)
                Stepper("Korrekte Antwort: \(correctIndex)",
                        value: $correctIndex,
                        in: 1...4)
            }

        case .hangman:
            VStack(alignment: .leading, spacing: 12) {
                TextField("Frage", text: $question)
                    .lineLimit(1...6)
                TextField("Antwort (ein Wort)", text: $answersText)
                    .lineLimit(1...6)
            }

        case .recognizeImage:
            VStack(alignment: .leading, spacing: 12) {
                Text("Gib 1–4 Synonyme an, z. B.: hund, schäferhund, husky")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                TextField("Antworten (1–4, mit , trennen)", text: $answersText)
                    .lineLimit(1...6)
            }

        case .drawView:
            VStack(alignment: .leading, spacing: 12) {
                TextField("Antwort (ein Wort)", text: $answersText)
            }
        }
    }

    private func answersArray() -> [String] {
        answersText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    private func isBlank(_ s: String) -> Bool {
        s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func applyDefaults(for challenge: Challenge) {
        switch challenge {
        case .smile:
            challengeText = "Erstelle ein Selfie mit der Sehenswürdigkeit!"
            modelName = ""; question = ""; answersText = ""; correctIndex = 1

        case .arView:
            challengeText = "Suche die Statue"
            question = "Welches virtuelle Tier versteckt sich hier auf dem Boden?"; answersText = ""; correctIndex = 1

        case .quiz:
            challengeText = "Löse das Quiz"
            modelName = ""; question = ""; answersText = ""; correctIndex = 1

        case .hangman:
            challengeText = "Löse die Galgenmännchen Aufgabe"
            modelName = ""; question = ""; answersText = ""; correctIndex = 1

        case .recognizeImage:
            challengeText = "Erkenne"
            modelName = "";
            answersText = "";
            correctIndex = 1

        case .drawView:
            challengeText = "Zeichne ein"
            modelName = ""; question = ""; answersText = ""; correctIndex = 1
        }
    }
// MARK: Upload
    private func buildAndUpload() async {
        errorText = nil

        var issues: [String] = []

        if isBlank(name)           { issues.append("Name") }
        if isBlank(challengeText)  { issues.append("Aufgaben-Text") }
        if isBlank(shortInfo)  { issues.append("Kurfinfos") }
        if isBlank(text)  { issues.append("Beschreibungstext") }

        guard let location = sharedPlaces.currentLocation?.coordinate else {
            Drops.show(Drop(title: "Location error"))
            return
        }

        var answers = answersArray()

        switch challenge {
        case .smile:
            answers = []; correctIndex = 1

        case .arView:
            if modelName.isEmpty { issues.append("USDZ-Modell") }
            if isBlank(question) { issues.append("Frage") }
            if answers.isEmpty   { issues.append("Antwort (1 Wort)") }
            answers = Array(answers.prefix(1))
            correctIndex = 1

        case .quiz:
            if isBlank(question) { issues.append("Frage") }
            if answers.count != 4 { issues.append("4 Antworten") }
            if !(1...4).contains(correctIndex) { issues.append("Korrekte Antwort (1–4)") }

        case .hangman:
            if isBlank(question) { issues.append("Frage") }
            if answers.isEmpty   { issues.append("Antwort (1 Wort)") }
            answers = Array(answers.prefix(1))
            correctIndex = 1

        case .recognizeImage:
            answers = Array(answers.prefix(4))
            if answers.isEmpty { issues.append("Antworten (1–4 Synonyme)") }

        case .drawView:
            if answers.isEmpty { issues.append("Antwort (1 Wort)") }
            answers = Array(answers.prefix(1))
            correctIndex = 1
        }

        if !issues.isEmpty {
            Drops.show(Drop(title: "Missing: " + issues.joined(separator: " • ")))
            return
        }

        let poi = PointOfInterest(
            id: id,
            shortInfos: shortInfo.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            text: text,
            images: imagesText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            name: name,
            city: sharedPlaces.currentCity,
            challenge: challengeText,
            challengeId: challenge.rawValue,
            latitude: location.latitude,
            longitude: location.longitude,
            modelName: modelName,
            question: question,
            answers: answers,
            correctIndex: challenge == .recognizeImage ? 0 : max(0, correctIndex - 1),
            poiLanguage: poiLanguage,
            creator: userFire.userFirebase?.email ?? "none"
        )
        uploading = true
        FirestoreService.shared.uploadPointOfInterest(point: poi) { result in
            switch result {
            case .success:
                uploading = false
                poiCreated = true
                Drops.show(Drop(title: "POI created"))
                resetForm()
            case .failure(let error):
                uploading = false
                errorText = "Error uploadPointOfInterest: \(error.localizedDescription)"
                Drops.show(Drop(title: "Error uploadPointOfInterest: \(error.localizedDescription)"))
            }
        }
    }
    private func resetForm() {
        id = makeAutomaticId()
        name = ""
        shortInfo = ""
        text = ""
        imagesText = ""
        challenge = .smile
        applyDefaults(for: .smile)
        modelName = ""
        question = ""
        answersText = ""
        correctIndex = 1
        uploading = false
        errorText = nil
        poiCreated = false
        showImporter = false
        FirestoreService.shared.getPOIsFromCity(city: sharedPlaces.currentCity) { result in
            switch result {
            case .success(let points):
                print("getPOIsFromCity success \(points.count)")
                let count = points.count + 1
                let city = sharedPlaces.currentCity.lowercased()
                id = "\(city)p\(count)"
            case .failure(let error):
                print("Error getPOIsFromCity: \(error.localizedDescription)")
            }
        }
    }


    // Projekt-spezifisch
    private func makeAutomaticId() -> String {
        let city = sharedPlaces.currentCity.lowercased()
        let count = FirestoreService.shared.pois.count + 1
        return "\(city)p\(count)"
    }

    func handleImport(result: Result<[URL], Error>, completion: (Bool, URL?) -> Void) {
        switch result {
        case .success(let urls):
            guard let picked = urls.first else { completion(false, nil); return }
            let secured = picked.startAccessingSecurityScopedResource()
            defer { if secured { picked.stopAccessingSecurityScopedResource() } }

            let pickedName = picked.deletingPathExtension().lastPathComponent
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: " ", with: "")

            let docs = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            let dest = docs.appendingPathComponent("\(pickedName).usdz")

            do {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                var coordinatorError: NSError?
                var innerError: Error?

                let coordinator = NSFileCoordinator()
                coordinator.coordinate(readingItemAt: picked, options: .withoutChanges, error: &coordinatorError) { coordinatedURL in
                    do {
                        let data = try Data(contentsOf: coordinatedURL)
                        try data.write(to: dest, options: .atomic)
                        self.modelName = pickedName
                    } catch {
                        innerError = error
                        self.modelName = ""
                    }
                }
                if let er = innerError { throw er }
                if let err = coordinatorError { throw err }
                completion(true, dest)
            } catch {
                Drops.show(Drop(title: "Save failed: \(error.localizedDescription)"))
                self.modelName = ""
                completion(false, nil)
            }

        case .failure(let error):
            Drops.show(Drop(title: "Import failed: \(error.localizedDescription)"))
            self.modelName = ""
            completion(false, nil)
        }
    }
}
