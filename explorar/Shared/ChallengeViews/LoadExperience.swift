//
//  LoadExperience.swift
//  explorar
//
//  Created by Fabian Kuschke on 29.07.25.
//

import SwiftUI
import Drops
#if !APPCLIP
import TelemetryClient
#endif

struct LoadExperienceView: View {
    @StateObject private var arCoordinator = ARCoordinator()
    var pointOfInterest: PointOfInterest
    @State var recognizeName = ""
    @StateObject private var keyboard = KeyboardResponder()
    @State private var showTextfield = true
    
#if !APPCLIP
    @ObservedObject var userFire = UserFire.shared
#endif
    
    private func savePoints() {
#if !APPCLIP
        if !UserDefaults.standard.bool(forKey: pointOfInterest.id) {
            let points = 10
            let res = LocalizedStringResource(
                "points_awarded",
                defaultValue: "Yeah correct, you got \(points) points! 🎉",
                table: "Localizable",
                comment: ""
            )
            Drops.show(Drop(title: String(localized: res),duration: 4.0))
            recognizeName = ""
            showTextfield = false
            userFire.updatePoints(amount: points) { result in
                switch result {
                case .success(let points):
                    print("Points added now: \(points)")
                    UserDefaults.standard.set(true, forKey: pointOfInterest.id)
                case .failure(let error):
                    print("Error adding points: \(error)")
                    Drops.show(Drop(title: "Error adding points: \(error)"))
                }
            }
        } else {
            Drops.show(Drop(title: NSLocalizedString("Yeah correct! 🎉", comment: ""),duration: 4.0))
            recognizeName = ""
            showTextfield = false
        }
#endif
    }
    
    func checkName() {
        if pointOfInterest.answers.count > 0 {
            if recognizeName.lowercased() == pointOfInterest.answers[0].lowercased() {
                savePoints()
            } else {
                print("Falsches Wort \(recognizeName)")
                Drops.show(Drop(title: "Falsches Wort! Richtig war: \(pointOfInterest.answers[0])"))
            }
        } else {
            Drops.show(Drop(title: "Error no answer"))
        }
    }
    
    var body: some View {
        ZStack {
            ARViewContainer(arCoordinator: arCoordinator)
                .edgesIgnoringSafeArea(.all)
                .onDisappear {
                    arCoordinator.pauseSession()
                }
            VStack {
                if arCoordinator.isRelocalizingMap, let snapshot = arCoordinator.snapshotImage {
                    VStack(spacing: 8) {
                        HStack {
                            Spacer().frame(width: 14)
                            Text("Move your device to match this image...")
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.5)
                                .font(.headline)
                                .background(
                                    Color.green
                                )
                            Spacer().frame(width: 14)
                        }
                        .frame(height: 40)
                        .background(
                            Color.green
                        )
                        .cornerRadius(16)
                        Image(uiImage: snapshot)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.85)
                            .cornerRadius(12)
                            .shadow(radius: 8)
                    }
                    .padding()
                    Spacer()
                } else {
                    if showTextfield {
                        Spacer()
                        VStack {
                            Spacer().frame(height: 14)
                            //MARK: TextField + Button
                            HStack {
                                TextField("", text: $recognizeName)
                                    .placeholder(when: recognizeName.isEmpty) {
                                        Text("\(pointOfInterest.question)")
                                            .foregroundColor(.gray)
                                            .minimumScaleFactor(0.5)
                                    }
                                    .foregroundColor(.blue)
                                    .minimumScaleFactor(0.5)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(20)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        checkName()
                                    }
                                Button {
                                    checkName()
                                } label: {
                                    Image(systemName: "arrow.forward.circle")
                                        .resizable()
                                        .foregroundColor(recognizeName.isEmpty ? .gray : .white)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                        .padding(.leading, 8)
                                }
                                .disabled(recognizeName.isEmpty)
                                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                            }
                            .frame(height: 50)
                            .padding(.horizontal)
                            Spacer().frame(height: 14)
                        }
                        .background(Color.blue)
                        .cornerRadius(30)
                        .padding(.bottom, 10)
                        .animation(.easeOut(duration: 0.25), value: keyboard.currentHeight)
                    }
                }
            }
//            if arCoordinator.isLoading {
//                Spacer()
//                ProgressView("Files are downloading...")
//                    .progressViewStyle(CircularProgressViewStyle())
//                    .background(Color.gray.opacity(0.25))
//                    .tint(.blue)
//                    .padding()
//                Spacer()
//            }
        }
        .background {
            backgroundGradient
                .ignoresSafeArea(.all)
        }
        .loadingOverlay(isPresented: $arCoordinator.isLoading, items: [
            LoadingItem(name: NSLocalizedString("text", comment: ""), color: .green),
            LoadingItem(name: NSLocalizedString("image", comment: ""), color: .blue),
            LoadingItem(name: NSLocalizedString("model", comment: ""), color: .yellow),
            LoadingItem(name: NSLocalizedString("scene", comment: ""), color: .brown)])
        .onAppear {
            print("modelName: \(pointOfInterest.modelName) id: \(pointOfInterest.id)")
            arCoordinator.loadScene(modelName: pointOfInterest.modelName, place: pointOfInterest.id)
#if !APPCLIP
            TelemetryDeck.signal("Load_Experience")
#endif
        }
        .onChange(of: arCoordinator.objectIsPlaced) { oldValue, newValue in
        }
    }
}
