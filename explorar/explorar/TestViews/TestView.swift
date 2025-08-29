//
//  TestView.swift
//  explorar
//
//  Created by Fabian Kuschke on 18.07.25.
//

import SwiftUI
import TelemetryClient
import FirebaseCore

struct TestView: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @ObservedObject var userFire = UserFire.shared
    @State private var newUsername = ""
    @State private var weeklyChallenge: WeeklyChallenge?
    @State private var dailyChallenge: DailyChallenge?
    
    private func updatePoints(amount: Int) {
        userFire.updatePoints(amount: amount) { result in
            switch result {
            case .success(let points):
                print("Points added: \(points)")
            case .failure(let error):
                print("Error adding points: \(error)")
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                /*
                if viewModel.authenticationState == .authenticated {
                    Spacer(minLength: 30)
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Hey \(userFire.userFirebase?.userName ?? "Stranger"), your  Points: \(userFire.userFirebase?.points ?? 0)")
                    Spacer(minLength: 30)
                    Text("Challenges:")
                    HStack {
                        Spacer()
                        if let w = weeklyChallenge {
                            VStack {
                                Text("weekly 1: \(w.challenge1)")
                                Text("weekly 2: \(w.challenge2)")
                                Text("weekly 3: \(w.challenge3)")
                            }
                            Spacer()
                        }
                        if let d = dailyChallenge {
                            VStack {
                                Text("daily 1: \(d.challenge1)")
                                Text("daily 2: \(d.challenge2)")
                                Text("daily 3: \(d.challenge3)")
                            }
                        }
                        Spacer()
                    }
                    Spacer(minLength: 30)
                    Button {
                        viewModel.signOut()
                    } label: {
                        Text("Logout")
                    }
                    Spacer(minLength: 30)
                    Button {
                        TelemetryDeck.signal("TestSignal")
                    } label: {
                        Text("Send Test Signal")
                    }
                    Spacer(minLength: 30)
                    Button {
                        updatePoints(amount: 1)
                    } label: {
                        Text("Add one point")
                    }
                    Spacer(minLength: 30)
                    NavigationLink(destination: TTSTestView()) {
                        Text("TTSTestView")
                    }
                    Spacer(minLength: 30)
                    NavigationLink(destination: AITest()) {
                        Text("AITest")
                    }
                    Spacer(minLength: 30)
                    NavigationLink(destination: DrawView(animalName: "Kuh", challenge: "Mahle eine Kuh", poiID: "testKuh")) {
                        Text("DrawingGameView")
                    }
                    Spacer(minLength: 30)
                    NavigationLink(destination: ToastTestView()) {
                        Text("ToastTestView")
                    }
                    Spacer(minLength: 30)
                    NavigationLink(destination: ImageTestView()) {
                        Text("ImageTestView")
                    }
                    Spacer(minLength: 30)
                    NavigationLink(destination: LeaderboardView()) {
                        Text("LeaderboardView")
                    }
                    Spacer(minLength: 30)
                    NavigationLink(destination: SendMessage()) {
                        Text("SendMessage")
                    }
                    Spacer(minLength: 30)
                    NavigationLink(destination: SmileView(poiID: "test1")) {
                        Text("SmileView")
                    }
                    Spacer(minLength: 30)
                    NavigationLink(destination: MapListView()) {
                        Text("MapListView")
                    }
                    Spacer(minLength: 30)
                    NavigationLink(destination: HangmanView(hangmanQuestion: HangmanQuestion(secretWord: "Hund", helpText: "Tier was viele zuhause haben."), poiID: "test2")) {
                        Text("HangmanView")
                    }
                    Spacer(minLength: 30)
                    NavigationLink(destination: RecognizeImageView(recognizeItem: RecognizeItem(question: "Welches Tier ist hier erkennbar?", image: UIImage(named: "Icon")!, answer: "Bär"), poiID: "test3")) {
                        Text("RecognizeImageView")
                    }
                    Spacer(minLength: 30)
                    NavigationLink(destination: QuizView(question: QuizQuestion(question: "Test", options: ["1", "2", "3", "4"], correctIndex: 1), poiID: "test4")) {
                        Text("QuizView")
                    }
                    Spacer(minLength: 30)
                    NavigationLink("TranslateView") {
                        POITranslationView(pointOfInterest: PointOfInterest(
                            id: "plochingenp2",
                            shortInfos: ["Das Haus der Farben", "das is cool"],
                            text: "Ausführlicher text",
                            images: ["plochingenp2_image1.jpg", "plochingenp2_image2.jpg"],
                            name: "Hundertwasser",
                            city: "Plochingen",
                            challenge: "Was ist los",
                            challengeId: 2,
                            latitude: 48.71159673969261,
                            longitude: 9.41852425356231,
                            modelName: "Fox",
                            question: "Was is 1+1",
                            answers: ["eins, zwei, drei, vier"],
                            correctIndex: 0,
                            poiLanguage: "de"
                        ))
                    }
                    Spacer(minLength: 30)
                    NavigationLink("Load Saved Experience") {
                        LoadExperienceView(pointOfInterest: PointOfInterest(
                            id: "plochingenp2",
                            shortInfos: ["Das Haus der Farben", "Das is ein Test"],
                            text: "ausführlicher text",
                            images: ["plochingenp2_image1.jpg", "plochingenp2_image2.jpg"],
                            name: "Hundertwasser",
                            city: "Plochingen",
                            challenge: "Was ist los",
                            challengeId: 2,
                            latitude: 48.71159673969261,
                            longitude: 9.41852425356231,
                            modelName: "",
                            question: "",
                            answers: [""],
                            correctIndex: 0,
                            poiLanguage: "de"
                        ))
                    }
                    if userFire.userFirebase != nil && userFire.userFirebase!.isCreater {
                        Spacer(minLength: 30)
                        NavigationLink("Place object and Save") {
                            CreateExperienceView(placeName: "FoxTest", modelName: "")
                        }
                    }
                } else {
                    switch viewModel.flow {
                    case .login:
                        LoginView()
                            .environmentObject(viewModel)
                    case .signUp:
                        SignupView()
                            .environmentObject(viewModel)
                    }
                }
            }*/
            } // vstack
            .padding()
            .onAppear {
                FirestoreService.shared.fetchCurrentWeeklyChallenge { result in
                    switch result {
                    case .success(let ch):
                        weeklyChallenge = ch
                    case .failure(let err):
                        print("Error Weekly Challange: \(err.localizedDescription)")
                    }
                }
                FirestoreService.shared.fetchTodayDailyChallenge { result in
                    switch result {
                    case .success(let ch):
                        dailyChallenge = ch
                    case .failure(let err):
                        print("Error Weekly Challange: \(err.localizedDescription)")
                    }
                }
            }
            .sheet(isPresented: $viewModel.shouldShowMissingUsernameAlert) {
                UsernameEntrySheet()
                    .environmentObject(viewModel)
                    .presentationDetents([.height(300)])
            }
        }
        .navigationTitle("TestView")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SelfieCityView(folderName: "Plochingen")) {
                    Image(systemName: "photo.on.rectangle")
                }
            }
        }
    }
}

