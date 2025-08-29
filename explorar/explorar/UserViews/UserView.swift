//
//  UserView.swift
//  explorar
//
//  Created by Fabian Kuschke on 05.08.25.
//

import SwiftUI
import TelemetryDeck
import Drops

enum AppColor: String, CaseIterable, Identifiable {
    case standard, green
    var id: String { rawValue }

    var alternateIconName: String? {
        switch self {
        case .standard: return nil
        case .green: return "AppIcon-Green"
        }
    }

    var title: String {
        switch self {
        case .standard: return NSLocalizedString("Blue", comment: "")
        case .green: return NSLocalizedString("Green", comment: "")
        }
    }
}

struct UserView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @ObservedObject var userFire = UserFire.shared
    @State private var showLogOutAlert: Bool = false
    @Environment(\.dismiss) var dismiss
    let onDismiss: () -> Void
    
    @AppStorage("appcolor") private var appColorRaw = AppColor.standard.rawValue

    @State private var dailyChallenge1 = ""
    @State private var dailyChallenge2 = ""
    @State private var dailyChallenge3 = ""
    @State private var weeklyChallenge1 = ""
    @State private var weeklyChallenge2 = ""
    @State private var weeklyChallenge3 = ""
    
    var customTransition: AnyTransition {
        AnyTransition.asymmetric(insertion: .offset(y:50).combined(with: .opacity), removal: .offset(y: -50).combined(with: .opacity))
    }
    
    private func createChallengesStrings() {
        if let d = userFire.dailyChallenges {
            dailyChallenge1 = "\(userFire.getDailyChallengePoints(id: "\(d.challenge1)"))/\(d.challenge1Value) \(getDailyChallengeText(id: d.challenge1))"
            dailyChallenge2 = "\(userFire.getDailyChallengePoints(id: "\(d.challenge2)"))/\(d.challenge2Value) \(getDailyChallengeText(id: d.challenge2))"
            dailyChallenge3 = "\(userFire.getDailyChallengePoints(id: "\(d.challenge3)"))/\(d.challenge3Value) \(getDailyChallengeText(id: d.challenge3))"
        }
        if let w = userFire.weeklyChallenges {
            weeklyChallenge1 = "\(userFire.getWeeklyChallengePoints(id: "\(w.challenge1)"))/\(w.challenge1Value) \(getWeeklyChallengeText(id: w.challenge1))"
            weeklyChallenge2 = "\(userFire.getWeeklyChallengePoints(id: "\(w.challenge2)"))/\(w.challenge2Value) \(getWeeklyChallengeText(id: w.challenge2))"
            weeklyChallenge3 = "\(userFire.getWeeklyChallengePoints(id: "\(w.challenge3)"))/\(w.challenge3Value) \(getWeeklyChallengeText(id: w.challenge3))"
        }
    }
    
    private func applyIcon(color: AppColor, onFailure: @escaping () -> Void) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(color.alternateIconName) { error in
            if let error = error {
                print("Icon change error:", error)
                DispatchQueue.main.async { onFailure() }
            } else {
                print("Icon change success →", UIApplication.shared.alternateIconName ?? "primary")
            }
        }
    }
    
    // MARK: View
    var body: some View {
        ScrollView {
            VStack (spacing: 20) {
                if viewModel.authenticationState == .authenticated {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 14)
                        if let user = userFire.userFirebase {
                            GamificationMiniView(points: user.points)
                                .frame(height: 200)
                                .cardStyle(color: colorScheme == .dark ? Color.black : Color.white)
                                     
                            //MARK: Today
                            VStack(spacing: 10) {
                                Text("Heutige Aufgaben").font(.headline)
                                    .minimumScaleFactor(0.5)
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(dailyChallenge1)
                                        .multilineTextAlignment(.leading)
                                        .minimumScaleFactor(0.5)
                                        .font(.system(size: 16))
                                    Text(dailyChallenge2)
                                        .multilineTextAlignment(.leading)
                                        .minimumScaleFactor(0.5)
                                        .font(.system(size: 16))
                                    Text(dailyChallenge3)
                                        .multilineTextAlignment(.leading)
                                        .minimumScaleFactor(0.5)
                                        .font(.system(size: 16))
                                }
                                    Text("Heutige Punkte: \(userFire.dailyPoints)")
                                    .font(.footnote).foregroundStyle(.blue)
                            }
                            .cardStyle(color: colorScheme == .dark ? Color.black : Color.white)
                            
                            // MARK: Weekly
                            VStack(spacing: 10) {
                                Text("Wöchentliche Aufgaben").font(.headline)
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(weeklyChallenge1)
                                        .multilineTextAlignment(.leading)
                                        .font(.system(size: 16))
                                    Text(weeklyChallenge2)
                                        .multilineTextAlignment(.leading)
                                        .font(.system(size: 16))
                                    Text(weeklyChallenge3)
                                        .multilineTextAlignment(.leading)
                                        .font(.system(size: 16))
                                }
                                Text("Wöchentliche Punkte: \(userFire.weeklyPoints)")
                                    .minimumScaleFactor(0.5)
                                    .font(.footnote)
                                    .foregroundStyle(.blue)
                            }
                            .cardStyle(color: colorScheme == .dark ? Color.black : Color.white)
                        }
                    }
                    .padding(.horizontal, 16) // links rechts Platz
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: weeklyChallenge3)
                    
                    HStack {
                        Picker("App Icon", selection: $appColorRaw) {
                            ForEach(AppColor.allCases) { c in
                                Text(c.title).tag(c.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: appColorRaw) { _, newValue in
                            let appColor = AppColor(rawValue: newValue) ?? .standard
                            applyIcon(color: appColor) {
                                let current = UIApplication.shared.alternateIconName
                                appColorRaw = (current == AppColor.green.alternateIconName) ? AppColor.green.rawValue
                                                                                            : AppColor.standard.rawValue
                            }
                        }
                    }
                    .cardStyle(color: colorScheme == .dark ? Color.black : Color.white)
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    if userFire.userFirebase != nil {
                        Text(userFire.userFirebase!.isCreater ? "Du bist Ersteller": "Du bis kein Ersteller")
                            .font(.footnote)
                            .foregroundStyle(Color.gray)
                    }
                    Spacer().frame(height: 10)
                    //missing userFire.userFirebase.createrInCity.contains(currentcity)
                    if userFire.userFirebase != nil && userFire.userFirebase!.isCreater {
                        NavigationLink {
                            CreatePOIView()
                        } label: {
                            Text("Create point of interest")
                                .minimumScaleFactor(0.5)
                                .foregroundColor(.orange)
                        }
                        Spacer().frame(height: 100)
                        if userFire.userFirebase?.email == "fabiankuschke@gmail.com" {
                            NavigationLink {
                                CreatePointOfInterest()
                            } label: {
                                Text("Create point of interest (old Method)")
                                    .minimumScaleFactor(0.5)
                                    .foregroundColor(.green)
                            }
                            VStack(spacing: 20) {
                                Button {
                                    FirestoreService.shared.sendPersonalizedNotificationToAllUsers( message: "Es gibt neue Orte zu entdecken! Check die App und siehe, was es Neues gibt!")
                                } label: {
                                    Text("Send Message with One Signal")
                                        .minimumScaleFactor(0.5)
                                        .foregroundColor(.green)
                                }
                                Button {
                                    LocalNotifications.shared.scheduleIn(minutes: 1, title: "Title min Test", body: "body min test")
                                } label: {
                                    Text("Send local message in x minutes")
                                        .minimumScaleFactor(0.5)
                                        .foregroundColor(.green)
                                }
                                Button {
                                    var comps = DateComponents()
                                    comps.year = 2025;
                                    comps.month = 8;
                                    comps.day = 17
                                    comps.hour = 19;
                                    comps.minute = 30
                                    let date = Calendar.current.date(from: comps)!
                                    LocalNotifications.shared.scheduleOn(date: date, title: "Title date Test", body: "body date test")
                                } label: {
                                    Text("Send local with date")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.horizontal, 16)
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
            }
        }
        .sheet(isPresented: $viewModel.shouldShowMissingUsernameAlert) {
            UsernameEntrySheet()
                .environmentObject(viewModel)
                .presentationDetents([.height(300)])
        }
        .onChange(of: viewModel.shouldShowMissingUsernameAlert, { oldValue, newValue in
            if !viewModel.shouldShowMissingUsernameAlert {
                UserFire.shared.getChallenges { result in
                    switch result {
                    case .success(let str):
                        print(str)
                        createChallengesStrings()
                    case .failure(let err):
                        print(err)
                        Drops.show(Drop(title: "\(err.localizedDescription)"))
                    }
                }
            }
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            backgroundGradient
                .ignoresSafeArea(.all)
        }
        .onChange(of: viewModel.authenticationState, { oldValue, newValue in
            FirestoreService.shared.getUser { result in
                UserFire.shared.getChallenges { result in
                    switch result {
                    case .success(let str):
                        print(str)
                        createChallengesStrings()
                    case .failure(let err):
                        print(err)
                        Drops.show(Drop(title: "\(err.localizedDescription)"))
                    }
                }
            }
        })
        
        .onAppear {
            let current = UIApplication.shared.alternateIconName
            let sysColor: AppColor = (current == AppColor.green.alternateIconName) ? .green : .standard
            if sysColor.rawValue != appColorRaw {
                appColorRaw = sysColor.rawValue
            }
            FirestoreService.shared.getUser { result in
                UserFire.shared.getChallenges { result in
                    switch result {
                    case .success(let str):
                        print(str)
                        createChallengesStrings()
                    case .failure(let err):
                        print(err)
                        Drops.show(Drop(title: "\(err.localizedDescription)"))
                    }
                }
            }
        }
        .alert(isPresented: $showLogOutAlert) {
            Alert(
                title: Text("Log out"),
                message: Text("Are you sure you want to log out?"),
                primaryButton: .destructive(Text("Log out")) {
                    viewModel.signOut()
                    TelemetryDeck.signal("Logged_out")
                    dismiss()
                },
                secondaryButton: .cancel()
            )
        }
        .navigationTitle(viewModel.authenticationState == .authenticated ? "Profil" : "Login")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(Color.white)
                }
            }
            if viewModel.authenticationState == .authenticated {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showLogOutAlert = true
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                            .foregroundStyle(Color.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: LeaderboardView()) {
                        Image(systemName: "person.line.dotted.person")
                            .foregroundStyle(Color.white)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SelfieCityView(folderName: "Cities")) {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundStyle(Color.white)
                    }
                }
            }
        }
        .onAppear {
            SharedPlaces.shared.locationManager.stopUpdatingLocation()
            // FirestoreService.shared.createDailyChallenge()
            // FirestoreService.shared.createWeeklyChallenge()
        }
        .onDisappear {
            print("dissappear Userview")
        }
    }
    
}
