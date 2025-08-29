//
//  User.swift
//  explorar
//
//  Created by Fabian Kuschke on 28.07.25.
//

import Foundation
import Drops

struct UserFirebase: Codable {
    let uid: String
    var email: String
    var userName: String
    var createrInCities: [String]
    var isCreater: Bool
    var points: Int
    var awards: [String]
    var pointsOfInterestsVisited: [String]
    var friendsIds: [String]
    var visitedCityIds: [String]
    var oneSignalID : String
}

class UserFire: ObservableObject {
    static let shared = UserFire()
    @Published var userFirebase: UserFirebase?
    var weeklyChallenges: WeeklyChallenge?
    var dailyChallenges: DailyChallenge?
    var dailyPoints: Int = 0
    var weeklyPoints: Int = 0
    
    var dailyChallenge1Points: Int = 0
    var dailyChallenge2Points: Int = 0
    var dailyChallenge3Points: Int = 0
    var weeklyChallenge1Points: Int = 0
    var weeklyChallenge2Points: Int = 0
    var weeklyChallenge3Points: Int = 0
    
    // MARK: Update Points
    func updatePoints(amount: Int, completion: @escaping (Result<Int, Error>) -> Void) {
        FirestoreService.shared.updatePoints(amount: amount) { result in
            switch result {
            case .success(let points):
                self.userFirebase?.points = points
                completion(.success(points))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: getChallenges
    func getChallenges(completion: @escaping (Result<String, Error>) -> Void) {
        getDailyWeeklyPoints()
        FirestoreService.shared.fetchCurrentWeeklyChallenge { result in
            switch result {
            case .success(let ch):
                self.weeklyChallenges = ch
                FirestoreService.shared.fetchTodayDailyChallenge { result in
                    switch result {
                    case .success(let ch):
                        self.dailyChallenges = ch
                        completion(.success("Got Daily& weekly"))
                    case .failure(let err):
                        print("Error Weekly Challange: \(err.localizedDescription)")
                        completion(.failure(err))
                    }
                }
            case .failure(let err):
                print("Error Weekly Challange: \(err.localizedDescription)")
                completion(.failure(err))
            }
        }
    }
    
    // MARK: getDailyWeeklyPoints Local
    func getDailyWeeklyPoints() {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let now = Date()
        let week = calendar.component(.weekOfYear, from: now)
        dailyPoints = UserDefaults.standard.integer(forKey: "dailyPoints\(weekday)")
        weeklyPoints = UserDefaults.standard.integer(forKey: "weeklyPoints\(week)")
        dailyChallenge1Points = UserDefaults.standard.integer(forKey: "dailyChallenge1Points\(weekday)")
        dailyChallenge2Points = UserDefaults.standard.integer(forKey: "dailyChallenge2Points\(weekday)")
        dailyChallenge3Points = UserDefaults.standard.integer(forKey: "dailyChallenge3Points\(weekday)")
        weeklyChallenge1Points = UserDefaults.standard.integer(forKey: "weeklyChallenge1Points\(weekday)")
        weeklyChallenge2Points = UserDefaults.standard.integer(forKey: "weeklyChallenge2Points\(weekday)")
        weeklyChallenge3Points = UserDefaults.standard.integer(forKey: "weeklyChallenge3Points\(weekday)")
        
        deleteOldDailyWeeklyPoints()
    }
    
    // MARK: updateDailyChallenge Local
    func updateDailyChallenge(id: String, points: Int = 1) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        if id == "1" {
            let poin = UserDefaults.standard.integer(forKey: "dailyChallenge1Points\(weekday)") + points
            if poin <= dailyChallenges?.challenge1Value ?? 6 {
                UserDefaults.standard.set(poin, forKey: "dailyChallenge1Points\(weekday)")
            }
        } else if id == "2" {
            let poin = UserDefaults.standard.integer(forKey: "dailyChallenge2Points\(weekday)") + points
            if poin <= dailyChallenges?.challenge2Value ?? 6 {
                UserDefaults.standard.set(poin, forKey: "dailyChallenge2Points\(weekday)")
            }
        } else if id == "3" {
            let poin = UserDefaults.standard.integer(forKey: "dailyChallenge3Points\(weekday)") + points
            if poin <= dailyChallenges?.challenge3Value ?? 6 {
                UserDefaults.standard.set(poin, forKey: "dailyChallenge3Points\(weekday)")
            }
        } else {
            print("updateDailyChallenge not possible \(id)")
            Drops.show(Drop(title: "updateDailyChallenge not possible \(id)"))
        }
        var points = 0
        if UserDefaults.standard.integer(forKey: "dailyChallenge1Points\(weekday)") == dailyChallenges?.challenge1Value {
            points += DailyChallengeType(rawValue: "1")!.points
        }
        if UserDefaults.standard.integer(forKey: "dailyChallenge2Points\(weekday)") == dailyChallenges?.challenge2Value {
            points += DailyChallengeType(rawValue: "2")!.points
        }
        if UserDefaults.standard.integer(forKey: "dailyChallenge3Points\(weekday)") == dailyChallenges?.challenge3Value {
            points += DailyChallengeType(rawValue: "3")!.points
        }
        dailyPoints = points
        UserDefaults.standard.set(dailyPoints, forKey: "dailyPoints\(weekday)")
        checkDailyChallengeStatus()
    }
    
    // MARK: checkDailyChallengeStatus upload firebase
    func checkDailyChallengeStatus() {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        var points = 0
        if UserDefaults.standard.integer(forKey: "dailyChallenge1Points\(weekday)") == dailyChallenges?.challenge1Value {
            if !UserDefaults.standard.bool(forKey: "dailyChallenge1Done\(weekday)") {
                points = DailyChallengeType(rawValue: "1")!.points
                UserDefaults.standard.set(true, forKey: "dailyChallenge1Done\(weekday)")

            }
        }
        if UserDefaults.standard.integer(forKey: "dailyChallenge2Points\(weekday)") == dailyChallenges?.challenge2Value {
            if !UserDefaults.standard.bool(forKey: "dailyChallenge2Done\(weekday)") {
                points = DailyChallengeType(rawValue: "2")!.points
                UserDefaults.standard.set(true, forKey: "dailyChallenge2Done\(weekday)")

            }
        }
        if UserDefaults.standard.integer(forKey: "dailyChallenge3Points\(weekday)") == dailyChallenges?.challenge3Value {
            if !UserDefaults.standard.bool(forKey: "dailyChallenge3Done\(weekday)") {
                points = DailyChallengeType(rawValue: "3")!.points
                UserDefaults.standard.set(true, forKey: "dailyChallenge3Done\(weekday)")
            }
        }
        
        if points > 0 {
            updatePoints(amount: points) { result in
                switch result {
                case .success(let points):
                    print("Points added now: \(points)")
                case .failure(let error):
                    print("Error adding points: \(error)")
                    Drops.show(Drop(title: "Error adding points: \(error)"))
                }
            }
        }
    }
    
    // MARK: getDailyChallengePoints
    func getDailyChallengePoints(id: String) -> Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        if id == "1" {
            return UserDefaults.standard.integer(forKey: "dailyChallenge1Points\(weekday)")
        } else if id == "2" {
            return UserDefaults.standard.integer(forKey: "dailyChallenge2Points\(weekday)")
        } else if id == "3" {
            return UserDefaults.standard.integer(forKey: "dailyChallenge3Points\(weekday)")
        } else {
            print("getDailyChallengePoints not possible \(id)")
            Drops.show(Drop(title: "getDailyChallengePoints not possible \(id)"))
            return 0
        }
    }
    
    // MARK: updateWeeklyChallenge
    func updateWeeklyChallenge(id: String, points: Int = 1) {
        let calendar = Calendar.current
        let now = Date()
        let week = calendar.component(.weekOfYear, from: now)
        if id == "1" {
            let poin = UserDefaults.standard.integer(forKey: "weeklyChallenge1Points\(week)") + points
            if poin <= weeklyChallenges?.challenge1Value ?? 6 {
                UserDefaults.standard.set(poin, forKey: "weeklyChallenge1Points\(week)")
            }
        } else if id == "2" {
            let poin = UserDefaults.standard.integer(forKey: "weeklyChallenge2Points\(week)") + points
            if poin <= weeklyChallenges?.challenge2Value ?? 6 {
                UserDefaults.standard.set(poin, forKey: "weeklyChallenge2Points\(week)")
            }
        } else if id == "3" {
            let poin = UserDefaults.standard.integer(forKey: "weeklyChallenge3Points\(week)") + points
            if poin <= weeklyChallenges?.challenge3Value ?? 6 {
                UserDefaults.standard.set(poin, forKey: "weeklyChallenge3Points\(week)")
            }
        } else {
            print("updateWeeklyChallenge not possible \(id)")
            Drops.show(Drop(title: "updateWeeklyChallenge not possible \(id)"))
        }
        var points = 0
        if UserDefaults.standard.integer(forKey: "weeklyChallenge1Points\(week)") == weeklyChallenges?.challenge1Value {
            points += WeeklyChallengeType(rawValue: "1")!.points
        }
        if UserDefaults.standard.integer(forKey: "weeklyChallenge2Points\(week)") == weeklyChallenges?.challenge2Value {
            points += WeeklyChallengeType(rawValue: "2")!.points
        }
        if UserDefaults.standard.integer(forKey: "weeklyChallenge3Points\(week)") == weeklyChallenges?.challenge3Value {
            points += WeeklyChallengeType(rawValue: "3")!.points
        }
        weeklyPoints = points
        UserDefaults.standard.set(weeklyPoints, forKey: "weeklyPoints\(week)")
        checkWeeklyChallengeStatus()
    }
    
    // MARK: getWeeklyChallengePoints
    func getWeeklyChallengePoints(id: String) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let week = calendar.component(.weekOfYear, from: now)
        if id == "1" {
            return UserDefaults.standard.integer(forKey: "weeklyChallenge1Points\(week)")
        } else if id == "2" {
            return UserDefaults.standard.integer(forKey: "weeklyChallenge2Points\(week)")
        } else if id == "3" {
            return UserDefaults.standard.integer(forKey: "weeklyChallenge3Points\(week)")
        } else {
            print("getWeeklyChallengePoints not possible \(id)")
            Drops.show(Drop(title: "getWeeklyChallengePoints not possible \(id)"))
            return 0
        }
    }
    
    // MARK: checkWeeklyChallengeStatus
    func checkWeeklyChallengeStatus() {
        let calendar = Calendar.current
        let now = Date()
        let week = calendar.component(.weekOfYear, from: now)
        var points = 0
        if UserDefaults.standard.integer(forKey: "weeklyChallenge1Points\(week)") == weeklyChallenges?.challenge1Value {
            if !UserDefaults.standard.bool(forKey: "weeklyChallenge1Done\(week)") {
                points = WeeklyChallengeType(rawValue: "1")!.points
                UserDefaults.standard.set(true, forKey: "weeklyChallenge1Done\(week)")

            }
        }
        if UserDefaults.standard.integer(forKey: "weeklyChallenge2Points\(week)") == weeklyChallenges?.challenge2Value {
            if !UserDefaults.standard.bool(forKey: "weeklyChallenge2Done\(week)") {
                points = WeeklyChallengeType(rawValue: "2")!.points
                UserDefaults.standard.set(true, forKey: "weeklyChallenge2Done\(week)")

            }
        }
        if UserDefaults.standard.integer(forKey: "weeklyChallenge3Points\(week)") == weeklyChallenges?.challenge3Value {
            if !UserDefaults.standard.bool(forKey: "weeklyChallenge3Done\(week)") {
                points = WeeklyChallengeType(rawValue: "3")!.points
                UserDefaults.standard.set(true, forKey: "weeklyChallenge3Done\(week)")
            }
        }
        
        if points > 0 {
            updatePoints(amount: points) { result in
                switch result {
                case .success(let points):
                    print("Points added now: \(points)")
                case .failure(let error):
                    print("Error adding points: \(error)")
                    Drops.show(Drop(title: "Error adding points: \(error)"))
                }
            }
        }
    }
    
    // MARK: deleteOldDailyWeeklyPoints
    func deleteOldDailyWeeklyPoints() {
        let calendar = Calendar.current
        var weekday = calendar.component(.weekday, from: Date()) - 1
        if weekday == 0 {
            weekday = 7
        }
        let now = Date()
        var week = calendar.component(.weekOfYear, from: now) - 1
        if week == 0 {
            week = 52
        }
        UserDefaults.standard.removeObject(forKey: "dailyPoints\(weekday)")
        UserDefaults.standard.removeObject(forKey: "weeklyPoints\(week)")
        
        UserDefaults.standard.removeObject(forKey: "dailyChallenge1Points\(weekday)")
        UserDefaults.standard.removeObject(forKey: "dailyChallenge2Points\(weekday)")
        UserDefaults.standard.removeObject(forKey: "dailyChallenge3Points\(weekday)")
        UserDefaults.standard.removeObject(forKey: "weeklyChallenge1Points\(week)")
        UserDefaults.standard.removeObject(forKey: "weeklyChallenge2Points\(week)")
        UserDefaults.standard.removeObject(forKey: "weeklyChallenge3Points\(week)")
        
        UserDefaults.standard.removeObject(forKey: "dailyChallenge1Done\(weekday)")
        UserDefaults.standard.removeObject(forKey: "dailyChallenge2Done\(weekday)")
        UserDefaults.standard.removeObject(forKey: "dailyChallenge3Done\(weekday)")
        UserDefaults.standard.removeObject(forKey: "weeklyChallenge1Done\(week)")
        UserDefaults.standard.removeObject(forKey: "weeklyChallenge2Done\(week)")
        UserDefaults.standard.removeObject(forKey: "weeklyChallenge3Done\(week)")        
    }
    
}
