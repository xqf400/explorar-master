//
//  Content.swift
//  explorar
//
//  Created by Fabian Kuschke on 30.07.25.
//

import SwiftUI
import CoreLocation
import Drops

enum ActiveAlert: Identifiable {
    case isInTestAlert
    case aiAlert
    
    var id: Int {
        switch self {
        case .isInTestAlert: return 0
        case .aiAlert: return 1
        }
    }
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @ObservedObject private var sharedPlaces = SharedPlaces.shared
    @ObservedObject var userFire = UserFire.shared
    @State private var selectedTab: CGFloat = 0
    @Binding var contentID: String?
    @State var showQRcodeView: Bool = false
    @State private var pointOfInterest: PointOfInterest? = nil
    @State var isLoadingPOI: Bool = false
    @State private var shine: Bool = false
    private let durationShine = 3.0
    @State private var triggerAnimateText: Bool = false
    
    @State private var showOverlay = false
    @State var showGame = false
    @State private var activeAlert: ActiveAlert? = nil
    
    private var mapORList: String {
        selectedTab == 1 ? "map" : "list"
    }
    
    @State private var showOnBoarding: Bool = {
        let key = "showOnBoarding"
        if UserDefaults.standard.object(forKey: key) == nil {
            return true
        } else {
            return UserDefaults.standard.bool(forKey: key)
        }
    }()
    
    // MARK: Closest Point
    private func getClosestPointOfInterest() -> Place? {
        guard !sharedPlaces.interestingPlaces.isEmpty else { return nil }
        var closestPlace: Place?
        var shortestDistance: CLLocationDistance = .greatestFiniteMagnitude
        for place in sharedPlaces.interestingPlaces {
            let distance = sharedPlaces.getDistance(from: place)
            if distance < shortestDistance {
                shortestDistance = distance
                closestPlace = place
            }
        }
        if closestPlace != nil  {
            if sharedPlaces.getDistance(from: closestPlace!) < 30 {
                return closestPlace
            }
        }
        return nil
        
    }
    // MARK: load Place
    func loadPOI(from id: String) {
        print("loadPOI \(id)")
        isLoadingPOI = true
        FirestoreService.shared.getPlace(name: id) { result in
            switch result {
            case .success(let pointOfInterest):
                isLoadingPOI = false
                print("loadPOI Load: ", pointOfInterest.name)
                self.pointOfInterest = pointOfInterest
            case .failure(let error):
                isLoadingPOI = false
                print("loadPOI Error getting poi: \(error.localizedDescription)")
                Drops.show(Drop(title: "Error getting poi: \(error.localizedDescription)"))
            }
        }
    }
    
    private func generatePoisFromCity(useOldPromt: Bool = false) {
        showOverlay = true
        if !FirestoreService.shared.settings.createAIPOIS {
            Drops.show(Drop(title: "Admin disabled generating AI Texts, sorry!"))
            return
        }
        showGame = true
        let city = sharedPlaces.currentCity
        AIService.shared.getInterestingPlaces(in: city, useOldPromt: useOldPromt) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let pois1):
                    print("Got pois: \(pois1.count)")
                    if pois1.count == 0 {
                        print("Count is 0 use old Prompt")
                        if useOldPromt == false {
                            generatePoisFromCity(useOldPromt: true)
                        } else {
                            self.showGame = false
                            Drops.show(Drop(title: "Keine Sehenswürdigkeiten in der Stadt: \(city) gefunden.", duration: .seconds(10)))
                        }
                    } else {
                        var pois: [PointOfInterest] = []
                        var count = 0
                        for poi1 in pois1 {
                            var poi = poi1
                            count += 1
                            if poi.images.isEmpty {
                                AIService.shared.fetchWikipediaImages(for: poi.name.replacingOccurrences(of: " (AI)", with: "")) { result1 in
                                    poi.images = result1
                                    pois.append(poi)
                                    print("added")
                                    if count == pois.count {
                                        getCoordinates(pois1: pois, city: city)
                                    }
                                }
                            } else {
                                pois.append(poi)
                                if count == pois.count {
                                    getCoordinates(pois1: pois, city: city)
                                }
                            }
                        }
                    }
                case .failure(let error):
                    self.showGame = false
                    Drops.show(Drop(title: "Error \(error.localizedDescription)"))
                }
            }
        }
    }
    
    private func getCoordinates(pois1: [PointOfInterest], city: String) {
        print("get corrdodante")
        var pois: [PointOfInterest] = []
        var count = 0
        for poi1 in pois1 {
            var poi = poi1
            count += 1
            if poi.latitude == 0 {
                AIService.shared.fetchWikiCoordinates(name: poi.name, cityHint: city) { coords in
                    print("coord: \(coords.latitude), \(coords.longitude)")
                    if coords.latitude != 0 {
                        poi.latitude = coords.latitude
                        poi.longitude = coords.longitude
                    }
                    pois.append(poi)
                    if count == pois.count {
                        savePois(pois: pois, city: city)
                    }
                }
            } else {
                pois.append(poi)
                if count == pois.count {
                    savePois(pois: pois, city: city)
                }
            }
        }
    }
    
    private func savePois(pois: [PointOfInterest], city: String) {
        AIService.shared.savePOIs(pois, for: city)
        self.showGame = false
        print("Count: ",pois.count)
        for poi in pois {
            print("name:", poi.name)
            print("images: ", poi.images)
            print("question: ", poi.question)
            print("answers: ", poi.answers)
            print("correctIndex: ", poi.correctIndex)
            print("latitude: ", poi.latitude)
            print("longitude: ", poi.longitude)
            print("shortInfos: ", poi.shortInfos)
        }
        SharedPlaces.shared.addAiPlaces(pois: pois)
    }
    
    // MARK: View
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // MARK: Text
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center) {
                            Spacer()
                            Text("Explore your surroundings")
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .font(.largeTitle.bold())
                            Spacer()
                        }
                        .frame(height:20)
                        HStack {
                            Text("The \(NSLocalizedString(mapORList, comment: "")) shows sights and interesting information about \(sharedPlaces.currentCity).")
                                .foregroundColor(.white)
                                .font(.system(size: 26))
                                .minimumScaleFactor(0.5)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                        }
                        .frame(height:50)
                        HStack {
                            Text("Scan the QR code on-site or select a pin to get more details about the place!")
                                .foregroundColor(.white)
                                .font(.system(size: 22).italic())
                                .minimumScaleFactor(0.5)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                        }
                        .frame(height:50)
                    }
                    .cardStyle(color: colorScheme == .dark ? Color.black : Color.white, opacity: 0.1)
                    // MARK: List/Map
                    VStack {
                        // MARK: Switcher
                        withAnimation {
                            SwitchView($selectedTab)
                                .frame(height: 10)
                                .padding()
                                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                                .shadow(color: Color.white.opacity(0.3), radius: 1, x: -2, y: -2)
                        }
                        // MARK: Map/ List
                        if selectedTab == 0 {
                            ListView()
                                .padding(.top, -8)
                            // .cornerRadius(30)
                        } else {
                            withAnimation {
                                MapARView()
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .frame(height: 380)
                    .cardStyle(color: colorScheme == .dark ? Color.black : Color.white, opacity: 0.1, paddingHorizontal: selectedTab == 0 ? 0: 16)
                    // MARK: Buttons
                    VStack {
                        HStack {
                            Spacer().frame(width: 8)
                            // MARK: Closes Point Button
                            Button(action: {
                                guard let foundPointOfInterest = getClosestPointOfInterest() else {
                                    Drops.show(Drop(title: "Keine Sehenswürdigkeit in der Nähe gefunden!"))
                                    return
                                }
                                print(foundPointOfInterest.item.name ?? "No name")
                                pointOfInterest = foundPointOfInterest.pointOfInterest
                            }) {
                                HStack {
                                    Image(systemName:"magnifyingglass")
                                        .foregroundStyle(Color.black)
                                    Text("Identify sightseeing features nearby")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .minimumScaleFactor(0.3)
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal, 4)
                            }
                            .padding()
                            .frame(height: 50)
                            .background(foregroundGradient)
                            .cornerRadius(30)
                            .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                            .shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
                            Spacer().frame(width: 8)
                        }
                        Spacer().frame(height: 20)
                        HStack {
                            Spacer().frame(width: 8)
                            // MARK: Scan Barcode Button
                            Button(action: {
                                selectedTab = 0
                                showQRcodeView = true
                            }){
                                HStack {
                                    Spacer()
                                    Image(systemName:"qrcode.viewfinder")
                                        .foregroundStyle(Color.black)
                                    Text("Scan QR-Code")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .minimumScaleFactor(0.5)
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                            }
                            .padding()
                            .frame(height: 50)
                            .background(foregroundGradient)
                            //.shine(toggle: shine, duration: durationShine)
                            .cornerRadius(30)
                            .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                            .shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
                            Spacer().frame(width: 8)
                        }
                    }
                    .cardStyle(color: colorScheme == .dark ? Color.black : Color.white, opacity: 0.1)
                    Spacer().frame(height: 2)
                } // Vstack
                .padding(.horizontal, 10)
            } // ScrollView
            .overlay{
                if showOverlay {
                    AIPOISLoadingOverlay(loading: $showGame) {
                        showOverlay = false
                    }
                    .frame(height: 700)
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                backgroundGradient
                    .ignoresSafeArea(.all)
            }
            .loadingOverlay(isPresented: $isLoadingPOI)
            .onChange(of: contentID) { oldValue, newValue in
                guard let id = newValue else { return }
                loadPOI(from: id)
            }
            // MARK: Navigation
            .navigationTitle("ExplorAR")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $pointOfInterest) { place in
                PointOfInterestView(pointOfInterest: place) {value in
                    pointOfInterest = nil
                    contentID = nil
                    sharedPlaces.locationManager.startUpdatingLocation()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        activeAlert = .isInTestAlert
                    }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(Color.white)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        activeAlert = .aiAlert
                    }) {
                        Image(systemName: "smoke.circle")
                            .foregroundStyle(Color.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: UserView() {
                        sharedPlaces.locationManager.startUpdatingLocation()
                    }
                        .environmentObject(viewModel)) {
                            Image(systemName: "person.circle")
                                .foregroundStyle(Color.white)
                        }
                }
            }
            .sheet(isPresented: $showQRcodeView, content: {
                QRcodeScannerView(contentID: $contentID, isShowing: $showQRcodeView)
                    .presentationDetentsSheet(height: 500)
            })
        }
        // MARK: Onboarding View
        .sheet(isPresented: $showOnBoarding) {
            OnboardingView(tint: Color(red: 73 / 255, green: 73 / 255, blue: 175 / 255), title: NSLocalizedString("Welcome to ExplorAR", comment: "")) {
                Spacer().frame(height: 10)
                Image(colorScheme == .dark ? "Icon_dark" :"Icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(16)
                    .clipped()
            } cards: {
                /// Cards
                AppleOnBoardingCard(
                    symbol: "list.bullet",
                    title: NSLocalizedString("Explore the world", comment: ""),
                    subTitle: NSLocalizedString("Find interessting places around you.", comment: "")
                )
                
                AppleOnBoardingCard(
                    symbol: "person.2",
                    title: NSLocalizedString("Gamification elements", comment: ""),
                    subTitle: NSLocalizedString("Challenge yourself and compete with your friends.", comment: "")
                )
                
                AppleOnBoardingCard(
                    symbol: "figure.walk.circle",
                    title: NSLocalizedString("Augmented Reality Experience", comment: ""),
                    subTitle: NSLocalizedString("Cool Mini games with Augmented Reality.", comment: "")
                )
            } footer: {
                HStack() {
                    Text("Made with ❤️")
                        .minimumScaleFactor(0.5)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                .padding(.vertical, 15)
            } onContinue: {
                showOnBoarding = false
                UserDefaults.standard.set(showOnBoarding, forKey: "showOnBoarding")
                if sharedPlaces.currentCity != "Unknown City" {
                    FirestoreService.shared.getPOIsFromCity(city: sharedPlaces.currentCity) { result in
                        switch result {
                        case .success(let pois):
                            print("getPOIsFromCity success \(pois.count)")
                            sharedPlaces.searchInterestLocations()
                        case .failure(let error):
                            print("Error getPOIsFromCity: \(error.localizedDescription)")
                            sharedPlaces.searchInterestLocations()
                        }
                    }
                }
            }
            .presentationDetents([.height(600)])
        }
        .onChange(of: selectedTab, { _, _ in
            if selectedTab == 0 {
                sharedPlaces.searchInterestLocations()
            } else if selectedTab == 1 {
                //ToDo: nur 2 mal anzeigen den Hinweis
                Drops.show(Drop(title: "Gerät nach oben neigen um die Kamera zu aktivieren!", titleNumberOfLines: 2, duration: 4.0))
            }
        })
        // MARK: Appear
        .onAppear() {
            print("Contentview Appear")
            // triggerAnimateText = true
            sharedPlaces.requestLocation()
            sharedPlaces.locationManager.startUpdatingLocation()
            FirestoreService.shared.getUser { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let gotUser):
                        print("Loaded User \(gotUser)")
                        UserFire.shared.getChallenges { result in
                            switch result {
                            case .success(let str):
                                print(str)
                            case .failure(let err):
                                print(err)
                                Drops.show(Drop(title: "Err23\(err.localizedDescription)"))
                            }
                        }
                    case .failure(let error):
                        print("Error get User: \(error.localizedDescription)")
                    }
                }
            }
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                if sharedPlaces.currentCity != "Unknown City" {
                    FirestoreService.shared.getPOIsFromCity(city: sharedPlaces.currentCity) { result in
                        switch result {
                        case .success(let pois):
                            print("getPOIsFromCity success \(pois.count)")
                            sharedPlaces.searchInterestLocations()
                        case .failure(let error):
                            print("Error getPOIsFromCity: \(error.localizedDescription)")
                            sharedPlaces.searchInterestLocations()
                        }
                    }
                } else {
                    // Repeat it in 2 seconds
                    Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                        if sharedPlaces.currentCity != "Unknown City" {
                            FirestoreService.shared.getPOIsFromCity(city: sharedPlaces.currentCity) { result in
                                switch result {
                                case .success(let pois):
                                    print("getPOIsFromCity success \(pois.count)")
                                    sharedPlaces.searchInterestLocations()
                                case .failure(let error):
                                    print("Error getPOIsFromCity: \(error.localizedDescription)")
                                    sharedPlaces.searchInterestLocations()
                                }
                            }
                        }
                    }
                }
            }
            FirestoreService.shared.getSettings()
            
            shine.toggle()
            Timer.scheduledTimer(withTimeInterval: durationShine, repeats: true) { _ in
                shine.toggle()
            }
            if contentID != nil {
                print("contentID \(contentID!)")
            } else {
                print("contentID is nil")
            }
            print("is InTestMode \(isInTestMode)")
            if isInTestMode {
                FirestoreService.shared.getTestPOIs { result in
                    switch result {
                    case .success(let pois):
                        print("getTestPOIs success \(pois.count)")
                        sharedPlaces.searchInterestLocations()
                    case .failure(let error):
                        print("Error getTestPOIs: \(error.localizedDescription)")
                        sharedPlaces.searchInterestLocations()
                    }
                }
            }
        }
        .onDisappear {
            print("Contentview disappear")
            sharedPlaces.locationManager.stopUpdatingLocation()
        }
        .task{
//            guard let key  = await FirestoreService.shared.getKey(name: "oneSignalID") else {
//                return
//            }
//            print("Settings key \(key)")
        }
        .sheet(isPresented: $viewModel.shouldShowMissingUsernameAlert) {
            UsernameEntrySheet()
                .environmentObject(viewModel)
                .presentationDetents([.height(300)])
        }
        // MARK: Alert
        .alert(item: $activeAlert) { alertState in
            switch alertState {
            case .isInTestAlert:
                return Alert(
                    title: Text("Testmode is \(isInTestMode ? NSLocalizedString("on", comment: "") : NSLocalizedString("off", comment: ""))"),
                    message: Text("Hier kannst du den Testmodus aktivieren oder deaktivieren.\nFalls er aktiv ist, ist die aktuelle Stadt Stuttgart.\nAnsonsten ist es deine aktuelle Stadt. \nBitte schließe die App vollständig, nachdem du den Umsetzen-Button gedrückt hast und öffne sie anschließend erneut."),
                    primaryButton: .default(Text("Testmode umschalten"), action: {
                        isInTestMode.toggle()
                        UserDefaults.standard.set(isInTestMode, forKey: "isInTestMode")
                        if isInTestMode {
                            FirestoreService.shared.getTestPOIs { result in
                                switch result {
                                case .success(let pois):
                                    print("getTestPOIs success \(pois.count)")
                                    sharedPlaces.searchInterestLocations()
                                case .failure(let error):
                                    print("Error getTestPOIs: \(error.localizedDescription)")
                                    sharedPlaces.searchInterestLocations()
                                }
                            }
                        }
                    }),
                    secondaryButton: .cancel(Text(NSLocalizedString("Cancel", comment: "")))
                )
                
            case .aiAlert:
                return Alert(
                    title: Text("Search sightseeing attractions for \(SharedPlaces.shared.currentCity)"),
                    message: Text("The sightseeing infos can be wrong. The AI isn't perfect and can be wrong."),
                    primaryButton: .default(Text("Start AI research"), action: {
                        generatePoisFromCity()
                    }),
                    secondaryButton: .cancel(Text(NSLocalizedString("Cancel", comment: "")))
                )
            }
        }
    }
}


