//
//  firestore.swift
//  explorar
//
//  Created by Fabian Kuschke on 23.07.25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import CoreLocation
import OneSignalFramework
import UserNotifications
import TelemetryClient
import FirebaseStorage
import MapKit
import Drops

struct City: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var coordinates: GeoPoint
    var pointsOfInterestIds: [String]
}

struct Settings: Hashable, Codable {
    var createAIAudio: Bool
    var createAIPOIS: Bool
    var createAIImage: Bool
    var AIidentifyAnimal: Bool
    var summarizeTextAI: Bool
    var listClickable: Bool
}

class FirestoreService {
    struct LeaderboardEntry: Identifiable {
        let id: String
        let name: String
        let points: Int
    }
    
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    var pois: [Place] = []
    var settings: Settings = Settings(createAIAudio: false, createAIPOIS: false, createAIImage: false, AIidentifyAnimal: false, summarizeTextAI: false, listClickable: false)
    
    private init() {}
    
    func checkIfUserExists(completion: ((Result<Bool, Error>) -> Void)? = nil) {
        let uid = Auth.auth().currentUser?.uid ?? ""
        let userRef = db.collection("users").document(uid)
        userRef.getDocument { (document, error) in
            if let error = error {
                completion?(.failure(error))
            } else if let document = document, document.exists {
                completion?(.success(true))
            } else {
                completion?(.success(false))
            }
        }
    }
    
    func createDatabaseUser(completion: ((Result<Void, Error>) -> Void)? = nil) {
        
        let uid = Auth.auth().currentUser?.uid ?? ""
        let userRef = db.collection("users").document(uid)
        guard let playerId = OneSignal.User.pushSubscription.id else {
            print("OneSignal player ID is nil")
            return
        }
        userRef.getDocument { (document, error) in
            // Check if user exists and update username not happens
            if let document = document, document.exists {
                userRef.updateData([
                    "userName": Auth.auth().currentUser?.displayName ?? ""
                ]) { err in
                    if let err = err {
                        print("Error updating: \(err)")
                        if error != nil {
                            completion?(.failure(err))
                            return
                        }
                    } else {
                        print("updated user in db")
                        completion?(.success(()))
                    }
                }
            } else {
                // create user
                userRef.setData([
                    "uid": uid,
                    "email": Auth.auth().currentUser?.email ?? "",
                    "userName": Auth.auth().currentUser?.displayName ?? "",
                    "createrInCities": [],
                    "isCreater": false,
                    "createrInCity":[],
                    "points": 0,
                    "awards": [],
                    "pointsOfInterestsVisited": [],
                    "friendsIds": [],
                    "visitedCityIds": [],
                    "oneSignalID": "\(playerId)"
                ]) { err in
                    if let err = err {
                        print("Error creating: \(err)")
                        if error != nil {
                            completion?(.failure(err))
                            return
                        }
                    } else {
                        print("User created in db")
                        TelemetryDeck.signal("User_created")
                        completion?(.success(()))
                    }
                }
            }
        }
    }
    
    //MARK: Userpoints
    func updatePoints(amount: Int, completion: @escaping (Result<Int, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "UserService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authenticated user email."])))
            return
        }
        
        let userRef = db.collection("users").document(uid)
        
        userRef.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists,
                  let currentPoints = document.data()?["points"] as? Int else {
                completion(.failure(NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User document or points field not found."])))
                return
            }
            
            // damit nur Punkte hinzugefügt werden können und nicht neu gesetzt werden können
            let updatedPoints = currentPoints + amount
            
            userRef.updateData(["points": updatedPoints]) { err in
                if let err = err {
                    completion(.failure(err))
                } else {
                    TelemetryDeck.signal("newPointsAdded",parameters: ["point": "\(updatedPoints)"])
                    completion(.success(updatedPoints))
                }
            }
        }
    }
    
    //MARK: Current User points
    func getUser(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "UserService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authenticated user."])))
            return
        }
        
        let userRef = db.collection("users").document(uid)
        
        userRef.getDocument { document, error in
            do {
                if let document = document, document.exists {
                    let user1 = try document.data(as: UserFirebase.self)
                    UserFire.shared.userFirebase = user1
                    FirestoreService.shared.updateOneSignalTokenToFirestore()
                    print("loaded user and updated OneSignal token")
                    completion(.success(true))
                } else {
                    completion(.failure(NSError(domain: "UserNotFound", code: 404)))
                }
            } catch {
                print("Decoding failed: \(error)")
                completion(.failure(error))
            }
        }
    }
    //MARK: Weekly Challenges
    func fetchCurrentWeeklyChallenge(completion: @escaping (Result<WeeklyChallenge, Error>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let week = calendar.component(.weekOfYear, from: now)
        let year = calendar.component(.year, from: now)
        
        let docID = "week\(week)\(year)"
        let docRef = db.collection("weeklyChallenges").document(docID)
        
        docRef.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            do {
                if let document = document, document.exists {
                    let challenge = try document.data(as: WeeklyChallenge.self)
                    completion(.success(challenge))
                } else {
                    let docRef1 = self.db.collection("weeklyChallenges").document("week332025")
                    
                    docRef1.getDocument { document, error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        do {
                            if let document = document, document.exists {
                                let challenge = try document.data(as: WeeklyChallenge.self)
                                completion(.success(challenge))
                            } else {
                                completion(.failure(NSError(domain: "ChallengeService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Challenge not found for week \(week), \(year)."])))
                            }
                        } catch {
                            completion(.failure(error))
                        }
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: Create Weekly Challenge
    func createWeeklyChallenge() {
        let challenge = WeeklyChallenge(id: "week372025", challenge1: "1", challenge2: "2", challenge3: "3", challenge1Value: 2, challenge2Value: 4, challenge3Value: 2)
        
        try? db.collection("weeklyChallenges").document(challenge.id).setData(from: challenge)
        let challenge2 = WeeklyChallenge(id: "week382025", challenge1: "1", challenge2: "2", challenge3: "3", challenge1Value: 2, challenge2Value: 4, challenge3Value: 2)
        
        try? db.collection("weeklyChallenges").document(challenge2.id).setData(from: challenge2)
        print("created weekly Challenge")
    }
    
    // MARK: Daily Challenges
    func fetchTodayDailyChallenge(completion: @escaping (Result<DailyChallenge, Error>) -> Void) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let docID = "day\(weekday)"
        
        let docRef = db.collection("dailyChallenges").document(docID)
        
        docRef.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            do {
                guard let document = document, document.exists else {
                    completion(.failure(NSError(domain: "ChallengeService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Daily challenge not found for day \(weekday)."])))
                    return
                }
                let challenge = try document.data(as: DailyChallenge.self)
                
                completion(.success(challenge))
            } catch {
                completion(.failure(error))
            }
        }
    }
    // MARK: Create Daily Challenge
    func createDailyChallenge() {
        let challenge = DailyChallenge(id: "day7", challenge1: "1", challenge2: "2", challenge3: "3", challenge1Value: 1, challenge2Value: 1, challenge3Value: 1)
        
        try? db.collection("dailyChallenges").document(challenge.id).setData(from: challenge)
        print("created daily Challenge")
    }
    
    //MARK: Leaderboard
    func fetchTopUsers(limit: Int = 5, completion: @escaping (Result<[LeaderboardEntry], Error>) -> Void) {
        db.collection("users")
            .order(by: "points", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.failure(NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No users found."])))
                    return
                }
                
                let entries = documents.compactMap { doc -> LeaderboardEntry? in
                    let data = doc.data()
                    let name = data["userName"] as? String ?? "Unknown"
                    let points = data["points"] as? Int ?? 0
                    return LeaderboardEntry(id: doc.documentID, name: name, points: points)
                }
                
                completion(.success(entries))
            }
    }
    func fetchMyTopFriendsAndMe(completion: @escaping (Result<[LeaderboardEntry], Error>) -> Void) {
        guard let myID = UserFire.shared.userFirebase?.uid else {
            completion(.failure(NSError(domain: "UserService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing user id."])))
            return
        }
        let friendIDs = UserFire.shared.userFirebase?.friendsIds ?? []
        let idsToQuery = [myID] + friendIDs
        
        guard !idsToQuery.isEmpty else {
            completion(.success([]))
            return
        }
        
        db.collection("users")
            .whereField(FieldPath.documentID(), in: idsToQuery)
            .order(by: "points", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.failure(NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No users found."])))
                    return
                }
                
                let entries = documents.compactMap { doc -> LeaderboardEntry? in
                    let data = doc.data()
                    let name = data["userName"] as? String ?? "Unknown"
                    let points = data["points"] as? Int ?? 0
                    return LeaderboardEntry(id: doc.documentID, name: name, points: points)
                }
                completion(.success(entries))
            }
    }
    
    // Search for a user by username and, if found, add them as a friend to current user
    func searchAndAddFriend(username: String,
                            completion: @escaping (Result<String, Error>) -> Void) {
        guard !username.isEmpty else {
            let error = NSError(domain: "FirestoreService",
                                code: 400,
                                userInfo: [NSLocalizedDescriptionKey: "Please enter a username"])
            completion(.failure(error))
            return
        }
        
        db.collection("users")
            .whereField("userName", isEqualTo: username)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    let err = NSError(domain: "FirestoreService",
                                      code: 404,
                                      userInfo: [NSLocalizedDescriptionKey: "No user found with name \(username)"])
                    completion(.failure(err))
                    return
                }
                
                let friendId = document.documentID
                
                self?.addFriendToCurrentUser(friendId: friendId) { result in
                    switch result {
                    case .success:
                        self?.sendOneSignalNotification(toUsername: username, title: "Hey \(username)", message: "Du wurdest von \(UserFire.shared.userFirebase?.userName ?? "") als Freund hinzugefügt.")
                        completion(.success(username))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
    }
    
    /// Adds the friend's ID to the current user's friendsIds array in Firestore
    func addFriendToCurrentUser(friendId: String,
                                completion: @escaping (Result<Void, Error>) -> Void) {
        guard let myId = UserFire.shared.userFirebase?.uid else {
            let error = NSError(domain: "FirestoreService",
                                code: 401,
                                userInfo: [NSLocalizedDescriptionKey: "Missing current user id"])
            completion(.failure(error))
            return
        }
        
        db.collection("users").document(myId).updateData([
            "friendsIds": FieldValue.arrayUnion([friendId])
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                UserFire.shared.userFirebase?.friendsIds.append(friendId)
                completion(.success(()))
            }
        }
    }
    
    //MARK: addVistitedPOI
    func addVistitedPOI(poiId: String) {
        guard let user = UserFire.shared.userFirebase else {
            return
        }
        if user.pointsOfInterestsVisited.contains(poiId) {
            return
        }
        let cityRef = db.collection("users").document(user.uid)
        
        cityRef.getDocument { document, error in
            if let error = error {
                print("Error fetching city: \(error.localizedDescription)")
                Drops.show(Drop(title: "Error fetching city: \(error.localizedDescription)"))
                
                return
            }
            if let document = document, document.exists {
                if var points = document.data()?["pointsOfInterestsVisited"] as? [String] {
                    if !points.contains(poiId) {
                        points.append(poiId)
                        
                        cityRef.updateData([
                            "pointsOfInterestsVisited": points
                        ]) { err in
                            if let err = err {
                                print("Error updating pointsOfInterestsVisited: \(err.localizedDescription)")
                            } else {
                                UserFire.shared.userFirebase?.pointsOfInterestsVisited.append(poiId)
                            }
                        }
                    } else {
                        print("Already exists in pointsOfInterestsVisited.")
                    }
                } else {
                    print("pointsOfInterestsVisited missing or invalid format.")
                    Drops.show(Drop(title: "pointsOfInterestsVisited missing or invalid format."))
                }
            }
        }
    }
    
    //MARK: addImageToPOI
    func addImageToPOI(imageName: String, poiID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let cityRef = db.collection("pointsOfInterest").document(poiID)
        
        cityRef.getDocument { document, error in
            if let error = error {
                print("Error fetching city: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            if let document = document, document.exists {
                if var points = document.data()?["images"] as? [String] {
                    if !points.contains(imageName) {
                        points.append(imageName)
                        
                        cityRef.updateData([
                            "images": points
                        ]) { err in
                            if let err = err {
                                print("Error updating visitedCityIds: \(err.localizedDescription)")
                                completion(.failure(err))
                            } else {
                                print("added image to \(poiID)")
                                completion(.success(()))
                            }
                        }
                    } else {
                        print("Already exists in poiID.")
                        let error = NSError(domain: "FirestoreService",
                                            code: 401,
                                            userInfo: [NSLocalizedDescriptionKey: "Already exists in poiID."])
                        completion(.failure(error))
                    }
                } else {
                    print("poiID missing or invalid format.")
                    let error = NSError(domain: "FirestoreService",
                                        code: 401,
                                        userInfo: [NSLocalizedDescriptionKey: "poiID missing or invalid format."])
                    completion(.failure(error))
                }
            }
        }
    }
    
    //MARK: addVistitedCity
    func addVistitedCity(cityId: String) {
        guard let user = UserFire.shared.userFirebase else {
            return
        }
        if user.visitedCityIds.contains(cityId) {
            return
        }
        let cityRef = db.collection("users").document(user.uid)
        
        cityRef.getDocument { document, error in
            if let error = error {
                print("Error fetching city: \(error.localizedDescription)")
                return
            }
            if let document = document, document.exists {
                if var points = document.data()?["visitedCityIds"] as? [String] {
                    if !points.contains(cityId) {
                        points.append(cityId)
                        
                        cityRef.updateData([
                            "visitedCityIds": points
                        ]) { err in
                            if let err = err {
                                print("Error updating visitedCityIds: \(err.localizedDescription)")
                                Drops.show(Drop(title: "Error updating visitedCityIds: \(err.localizedDescription)"))
                            } else {
                                UserFire.shared.userFirebase?.visitedCityIds.append(cityId)
                            }
                        }
                    } else {
                        print("Already exists in visitedCityIds.")
                    }
                } else {
                    print("visitedCityIds missing or invalid format.")
                    Drops.show(Drop(title: "visitedCityIds missing or invalid format."))
                }
            }
        }
    }
    
    
    //MARK: Create City
    func createNewCity() {
        let city = City(
            id: "plochingen",
            name: "Plochingen",
            description: "Schöne Stadt bla",
            coordinates: GeoPoint(latitude: 48.7132, longitude: 9.4197),
            pointsOfInterestIds: ["plochingenp1", "plochingenp2"],
        )
        try? db.collection("cities").document(city.id!).setData(from: city)
    }
    
    //MARK: Create Spot
    /*
     func createNewSpot() {
     let poi = PointOfInterest(
     id: "placeName",
     shortInfo: "Das Haus der Farben",
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
     correctIndex: 0
     )
     
     try? db.collection("pointsOfInterest").document(poi.id).setData(from: poi)
     }*/
    func uploadPointOfInterest(point: PointOfInterest, completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            try db.collection("pointsOfInterest").document(point.id).setData(from: point)
            print("Uploaded point Of Interest in db")
            let poiPlistRef = Storage.storage().reference().child("Locations/\(point.id).plist")
            do {
                let encoder = PropertyListEncoder()
                encoder.outputFormat = .xml
                let data = try encoder.encode(point)
                let metadata = StorageMetadata()
                metadata.contentType = "application/x-plist"
                
                poiPlistRef.putData(data, metadata: metadata) { metadata, error in
                    if let error = error {
                        print("Failed to upload POI plist: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        print("POI plist uploaded successfully to Storage.")
                        self.addPlaceToCity(point: point) { result in
                            switch result {
                            case .success(_):
                                FirebaseStorageService.shared.createAndUploadFileListJSON() { result in
                                    switch result {
                                    case .success(let bool):
                                        completion(.success(bool))
                                    case .failure(let error):
                                        completion(.failure(error))
                                    }
                                }
                            case .failure(let error):
                                print("Error addPlaceToCity: \(error.localizedDescription)")
                                completion(.failure(error))
                            }
                        }
                    }
                }
            } catch {
                print("Error encoding POI to plist: \(error.localizedDescription)")
                completion(.failure(error))
            }
        } catch {
            print("error uploadPointOfInterest: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    // MARK: getPOIsFromCity
    func getPOIsFromCity(city: String, completion: @escaping (Result<[Place], Error>) -> Void) {
        let cityId = city.lowercased()
        var pois : [Place] = []
        enum CityFetchError: Error {
            case notFound
        }
        let cityRef = db.collection("cities").document(cityId)
        cityRef.getDocument { document, error in
            if let error = error {
                print("Error fetching city: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            if let document = document, document.exists {
                if let points = document.data()?["pointsOfInterestIds"] as? [String] {
                    for point in points {
                        self.getPOI(poiId: point) { result in
                            switch result {
                            case .success(let poi):
                                let coordiante = CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude)
                                let placemark = MKPlacemark(coordinate: coordiante)
                                let item = MKMapItem(placemark: placemark)
                                item.name = poi.name
                                let numberString = String(poi.latitude)
                                let cleanedString = numberString.replacingOccurrences(of: ".", with: "")
                                if let id = Int(cleanedString) {
                                    let place = Place(id: id, item: item, image: UIImage(systemName: "mappin.circle"), pointOfInterest: poi)
                                    pois.append(place)
                                }
                                if (points.count == pois.count) {
                                    self.pois = pois
                                    completion(.success(pois))
                                }
                            case .failure(let error):
                                print("Error fetching POI: \(error.localizedDescription)")
                                completion(.failure(error))
                            }
                        }
                    }
                } else {
                    completion(.failure(CityFetchError.notFound))
                }
            } else {
                print("Nothing found for this city")
                completion(.failure(CityFetchError.notFound))
            }
        }
        
    }
    
    // MARK: getTestPOIs
    func getTestPOIs(completion: @escaping (Result<[Place], Error>) -> Void) {
        enum CityFetchError: Error {
            case notFound
        }
        let cityRef = db.collection("cities").document("stuttgart")
        cityRef.getDocument { document, error in
            if let error = error {
                print("Error fetching city: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            if let document = document, document.exists {
                if let points = document.data()?["pointsOfInterestIds"] as? [String] {
                    var pois1 : [Place] = []
                    for point in points {
                        self.getPOI(poiId: point) { result in
                            switch result {
                            case .success(let poi):
                                let coordiante = CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude)
                                let placemark = MKPlacemark(coordinate: coordiante)
                                let item = MKMapItem(placemark: placemark)
                                item.name = poi.name
                                let numberString = String(poi.latitude)
                                let cleanedString = numberString.replacingOccurrences(of: ".", with: "")
                                if let id = Int(cleanedString) {
                                    let place = Place(id: id, item: item, image: UIImage(systemName: "mappin.circle"), pointOfInterest: poi)
                                    pois1.append(place)
                                }
                                if (points.count == pois1.count) {
                                    for poi in pois1 {
                                        if !self.pois.contains(where: {$0.id == poi.id}) {
                                            self.pois.append(poi)
                                        }
                                    }
                                    completion(.success(pois1))
                                }
                            case .failure(let error):
                                print("Error fetching POI: \(error.localizedDescription)")
                                completion(.failure(error))
                            }
                        }
                    }
                } else {
                    completion(.failure(CityFetchError.notFound))
                }
            } else {
                print("Nothing found for test city")
                completion(.failure(CityFetchError.notFound))
            }
        }
    }
    
    //MARK: Get POI
    func getPOI(poiId: String, completion: @escaping (Result<PointOfInterest, Error>) -> Void) {
        let poiRef = db.collection("pointsOfInterest").document(poiId)
        poiRef.getDocument { document, error in
            if let error = error {
                print("Error fetching POI: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            if let document = document, document.exists {
                do {
                    let point = try document.data(as: PointOfInterest.self)
                    completion(.success(point))
                } catch {
                    print("Decoding failed: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    //MARK: addPlaceToCity
    func addPlaceToCity(point:PointOfInterest,
                        completion: @escaping (Result<Bool, Error>) -> Void) {
        let cityId = point.city.lowercased()
        let cityRef = db.collection("cities").document(cityId)
        
        cityRef.getDocument { document, error in
            if let error = error {
                print("Error fetching city: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let document = document, document.exists {
                if var points = document.data()?["pointsOfInterestIds"] as? [String] {
                    if !points.contains(point.id) {
                        points.append(point.id)
                        
                        cityRef.updateData([
                            "pointsOfInterestIds": points
                        ]) { err in
                            if let err = err {
                                print("Error updating city: \(err.localizedDescription)")
                                completion(.failure(err))
                            } else {
                                TelemetryDeck.signal("pointAddedToCity")
                                print("Added point to existing city: \(point.city)")
                                completion(.success(true))
                            }
                        }
                    } else {
                        print("Point already exists in city.")
                        completion(.success(true))
                    }
                } else {
                    enum lError: Error {
                        case notFound
                    }
                    print("pointsOfInterestIds missing or invalid format.")
                    completion(.failure(lError.notFound))
                }
            } else {
                // ➕ Create new city
                let city = City(
                    id: cityId,
                    name: point.city,
                    description: "Schöne Stadt",
                    coordinates: GeoPoint(latitude: point.latitude, longitude: point.longitude),
                    pointsOfInterestIds: [point.id]
                )
                
                do {
                    try cityRef.setData(from: city) { err in
                        if let err = err {
                            print("Error creating city: \(err.localizedDescription)")
                            completion(.failure(err))
                        } else {
                            TelemetryDeck.signal("newCityAndPointAdded")
                            print("Created new city and added point: \(point.city)")
                            completion(.success(true))
                        }
                    }
                } catch {
                    print("Encoding error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    //MARK: getPlace
    func getPlace(name: String, completion: @escaping (Result<PointOfInterest, Error>) -> Void) {
        let userRef = db.collection("pointsOfInterest").document(name)
        userRef.getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                if let document = document, document.exists {
                    do {
                        let point = try document.data(as: PointOfInterest.self)
                        completion(.success(point))
                    } catch {
                        print("Decoding failed: \(error)")
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    
    // MARK: OneSignal Token
    func updateOneSignalTokenToFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let playerId = OneSignal.User.pushSubscription.id else {
            print("OneSignal player ID is nil")
            Drops.show(Drop(title: "OneSignal player ID is nil"))
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.setData(["oneSignalID": playerId], merge: true) { error in
            if let error = error {
                print("Error saving OneSignal token: \(error)")
                Drops.show(Drop(title: "OneSignal player ID is nil"))
            } else {
                print("OneSignal token saved to Firestore")
            }
        }
    }
    
    // MARK: Send Notification to User
    func sendOneSignalNotification(toUsername username: String, title: String, message: String) {
        TelemetryDeck.signal("sendOneSignalNotificationToUsername")
        // Nicht die beste Lösung & Name kann es mehrmals geben
        let db = Firestore.firestore()
        db.collection("users").whereField("userName", isEqualTo: username).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching user: \(error)")
                Drops.show(Drop(title: "Error fetching user: \(error)"))
                return
            }
            guard let document = snapshot?.documents.first,
                  let playerId = document.data()["oneSignalID"] as? String else {
                print("User not found or no playerId")
                Drops.show(Drop(title: "User not found or no playerId"))
                return
            }
            // Now send the notification
            let url = URL(string: "https://onesignal.com/api/v1/notifications")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Basic \(oneSignalKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let payload: [String: Any] = [
                "app_id": oneSignalID,
                "include_player_ids": [playerId],
                "headings": ["en": title],
                "contents": ["en": message]
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending notification: \(error)")
                    Drops.show(Drop(title: "Error sending notification: \(error)"))
                } else {
                    print("Notification sent!")
                }
            }.resume()
        }
    }
    
    // MARK: Notification AllUsers
    func sendOneSignalNotificationToAllUsers(title: String, message: String) {
        TelemetryDeck.signal("sendOneSignalNotificationToAllUsers")
        let url = URL(string: "https://onesignal.com/api/v1/notifications")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(oneSignalKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "app_id": oneSignalID,
            "included_segments": ["All"],
            "headings": ["en": title],
            "contents": ["en": message]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending notification to all users: \(error)")
                Drops.show(Drop(title: "Error sending notification to all users: \(error)"))
            } else {
                print("Broadcast notification sent!")
            }
        }.resume()
    }
    
    // MARK: Personalized Notification AllUsers
    func sendPersonalizedNotificationToAllUsers(message: String) {
        TelemetryDeck.signal("sendPersonalizedNotificationToAllUsers")
        db.collection("users").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching users: \(error)")
                Drops.show(Drop(title: "Error fetching users: \(error)"))
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No users found")
                Drops.show(Drop(title: "No users found"))
                return
            }
            
            for document in documents {
                let data = document.data()
                guard
                    let playerId = data["oneSignalID"] as? String,
                    let userName = data["userName"] as? String else {
                    print("Missing player ID or username for user: \(document.documentID)")
                    continue
                }
                
                let url = URL(string: "https://onesignal.com/api/v1/notifications")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Basic \(oneSignalKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let payload: [String: Any] = [
                    "app_id": oneSignalID,
                    "include_player_ids": [playerId],
                    "headings": ["en": "Hey \(userName)"],
                    "contents": ["en": message]
                ]
                
                request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error sending notification to \(userName): \(error)")
                        Drops.show(Drop(title: "Error sending notification to \(userName): \(error)"))
                    } else {
                        print("Notification sent to \(userName)")
                    }
                }.resume()
            }
        }
    }
    
    // MARK: Local Notification
    func sendLocalNotification(title: String, message: String, delaySeconds: TimeInterval = 35) {
        TelemetryDeck.signal("sendLocalNotification")
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                    if granted {
                        scheduleNotification()
                    } else {
                        print("Notification permission denied.")
                        Drops.show(Drop(title: "Notification permission denied."))
                    }
                }
            } else {
                scheduleNotification()
            }
        }
        
        func scheduleNotification() {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delaySeconds, repeats: false)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString,
                                                content: content,
                                                trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling local notification: \(error)")
                    Drops.show(Drop(title: "Error scheduling local notification: \(error)"))
                } else {
                    print("Local notification scheduled in \(delaySeconds) seconds.")
                }
            }
        }
    }
    
    // MARK: get Settings
    func getSettings() {
        let userRef = db.collection("temporarySettings").document("settings")
        userRef.getDocument { (document, error) in
            if let error = error {
                print("Settings Error getting \(error.localizedDescription)")
            } else {
                if let document = document, document.exists {
                    do {
                        let settings = try document.data(as: Settings.self)
                        self.settings = settings
                        print("Settings got it \(settings)")
                    } catch {
                        print("Settings error Decoding failed: \(error)")
                    }
                }
            }
        }
    }
    func getKey(name: String) async -> String? {
        let userRef2 = db.collection("temporarySettings").document("keys")
        do {
            let document = try await userRef2.getDocument()
            let data = document.data()
            return data?[name] as? String
        } catch {
            print("Error: \(error)")
            return nil
        }
    }
}
