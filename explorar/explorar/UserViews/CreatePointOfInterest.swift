//
//  CreatePointOfInterest.swift
//  explorar
//
//  Created by Fabian Kuschke on 06.08.25.
//

import SwiftUI
import UniformTypeIdentifiers
import Drops

struct CreatePointOfInterest: View {
    @ObservedObject private var sharedPlaces = SharedPlaces.shared
    @State var uploading = false
    @State var poiCreated = false
    @State var poi: PointOfInterest?
    @State private var showImporter = false
    @ObservedObject var userFire = UserFire.shared
    
    @State private var id = ""
    @State private var shortInfo = ""
    @State private var text = ""
    @State private var images = ""
    @State private var name = ""
    @State private var challenge = ""
    // challengeId 1 = Smile
    // challengeId 2 = ARView
    // challengeId 3 = Quiz
    // challengeId 4 = Hangman
    // challengeId 5 = RecognizeImage
    // challengeId 6 = DrawView
    @State private var challengeId = 2
    @State private var modelName = ""
    @State private var question = ""
    @State private var answers = ""
    @State private var correctIndex = 1
    @State private var poiLanguage = "de"//getDeviceLanguage()
    
    
    func handleImport(result: Result<[URL], Error>, completion: (Bool, URL?) -> Void) {
        switch result {
        case .success(let urls):
            guard let picked = urls.first else { completion(false, nil); return }
            
            let secured = picked.startAccessingSecurityScopedResource()
            defer { if secured { picked.stopAccessingSecurityScopedResource() } }
            let pickedNameRaw = picked.deletingPathExtension().lastPathComponent
            let pickedName = pickedNameRaw
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
                
                if let e = innerError { throw e }
                if let e = coordinatorError { throw e }
                
                completion(true, dest)
            } catch {
                print("Save failed: \(error.localizedDescription)")
                Drops.show(Drop(title: "Save failed: \(error.localizedDescription)"))
                self.modelName = ""
                completion(false, nil)
            }
            
        case .failure(let error):
            print("Import failed: \(error.localizedDescription)")
            Drops.show(Drop(title: "Import failed: \(error.localizedDescription)"))
            self.modelName = ""
            completion(false, nil)
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    Group {
                        TextField("Id", text: $id)
                        Text("Short Infos Example: test,test2,test")
                            .minimumScaleFactor(0.5)
                        TextField("Short Infos", text: $shortInfo)
                        Text("Description long text")
                            .minimumScaleFactor(0.5)
                        TextField("Description Text", text: $text)
                        Text("If challenge id is 5 please upload one single photo first and than upload the rest. The first one is the recognize image and not displayed in the POI View")
                            .minimumScaleFactor(0.5)
                        TextField("Image names (comma-separated) from upload view", text: $images)
                        NavigationLink("Go to Image Uploader") {
                            ImageUploaderView(uploadedImageNamesText: $images, cityName: id, challengeID: challengeId)
                        }
                        TextField("POI Name", text: $name)
                        Text("Challenge Text")
                            .minimumScaleFactor(0.5)
                        TextField("Challenge Text", text: $challenge)
                        Text("Challenge Id: 1:Smile,2:ARView,3:Quiz,4:Hangman,5:Recognize,6:Draw")
                            .minimumScaleFactor(0.5)
                        TextField("Challenge ID", value: $challengeId, format: .number)
                        Text("Language of POI")
                            .minimumScaleFactor(0.5)
                        TextField("Device language", text: $poiLanguage)
                    }
                    
                    Group {
                        Text("Picked Model: \(modelName)")
                            .minimumScaleFactor(0.5)
                        //TextField("Model Name", text: $modelName)
                        Text("Question if Quiz or helpText in hangman")
                            .minimumScaleFactor(0.5)
                        TextField("Question", text: $question)
                        Text("AR View one answer, hangman guess word first index draw (1-4 answers), quiz please for answers: Example 1,2,3,")
                            .minimumScaleFactor(0.5)
                        TextField("Answers (comma-separated)", text: $answers)
                        Text("Correct index")
                            .minimumScaleFactor(0.5)
                        TextField("Correct Answer Index", value: $correctIndex, format: .number)
                    }
                    
                    Button("Create POI") {
                        if challengeId == 2 && modelName == "" {
                            return
                        }
                        guard let location = sharedPlaces.currentLocation?.coordinate else {
                            print("no location found")
                            Drops.show(Drop(title: "no location found"))
                            return
                        }
                        uploading = true
                        if sharedPlaces.currentCity != "Unknown City" {
                            poi = PointOfInterest(
                                id: id,
                                shortInfos: shortInfo.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                                text: text,
                                images: images
                                    .split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespaces) },
                                name: name,
                                city: sharedPlaces.currentCity,
                                challenge: challenge,
                                challengeId: challengeId,
                                latitude: location.latitude,
                                longitude: location.longitude,
                                modelName: modelName,
                                question: question,
                                answers: answers
                                    .split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespaces) },
                                correctIndex: correctIndex,
                                poiLanguage: poiLanguage,
                                creator: userFire.userFirebase?.email ?? "none"
                            )
                            
                            FirestoreService.shared.uploadPointOfInterest(point: poi!) { result in
                                switch result {
                                case .success(let bool):
                                    print("uploadPointOfInterest uploaded: \(bool)")
                                    uploading = false
                                    poiCreated = true
                                case .failure(let error):
                                    print("Error uploadPointOfInterest: \(error.localizedDescription)")
                                    Drops.show(Drop(title: "Error uploadPointOfInterest: \(error.localizedDescription)"))
                                }
                            }
                        } else {
                            print("no city found")
                            uploading = false
                            Drops.show(Drop(title: "no city found"))
                        }
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    NavigationLink(destination: QRCodeView(url: "https://explor-ar.fun/?id=\(id)")) {
                        Text("Show QR code")
                            .minimumScaleFactor(0.5)
                            .frame(height: 60)
                    }
                    Button("Pick USDZ") {
                        showImporter = true
                    }
                    if poiCreated && challengeId == 2 {
                        NavigationLink(destination: CreateExperienceView(placeName: id, modelName: modelName)) {
                            Text("Place object in AR")
                                .minimumScaleFactor(0.5)
                                .frame(height: 60)
                        }
                    }
                    if userFire.userFirebase?.email == "fabiankuschke@gmail.com" {
                        NavigationLink(destination: CreateExperienceView(placeName: id, modelName: modelName)) {
                            Text("Place object in AR")
                                .minimumScaleFactor(0.5)
                                .frame(height: 60)
                        }
                    }
                }
                .textFieldStyle(.roundedBorder)
                .padding()
            }
            if uploading {
                Spacer()
                ProgressView("Uploading POI...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                Spacer()
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.usdz],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result) { success, url in
                if success, let url = url {
                    print("Saved at \(url)")
                } else {
                    print("Failed url")
                    Drops.show(Drop(title: "Failed url"))
                }
            }
        }
        .navigationTitle("Create POI")
        .onAppear {
            sharedPlaces.locationManager.startUpdatingLocation()
            if sharedPlaces.currentCity != "Unknown City" {
                id = "\(sharedPlaces.currentCity.lowercased())p\(FirestoreService.shared.pois.count+1)"
                Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                    sharedPlaces.locationManager.stopUpdatingLocation()
                }
            }
            
        }
        .onDisappear {
            print("CreatePointOfInterest disappear")
            sharedPlaces.locationManager.stopUpdatingLocation()
        }
        .onChange(of: poiCreated) { oldValue, newValue in
            FirestoreService.shared.getPOIsFromCity(city: sharedPlaces.currentCity) { result in
                switch result {
                case .success(let points):
                    print("getPOIsFromCity success \(points.count)")
                case .failure(let error):
                    print("Error getPOIsFromCity: \(error.localizedDescription)")
                }
            }
        }
    }
}


