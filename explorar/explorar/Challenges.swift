//
//  Challenges.swift
//  explorar
//
//  Created by Fabian Kuschke on 23.07.25.
//

import Foundation

enum DailyChallengeType: String, CaseIterable {
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    
    var challenge: String {
        switch self {
        case .one:
            return NSLocalizedString("Sehenswürdigkeiten besucht (40 Punkte)", comment: "")
        case .two:
            return NSLocalizedString("Lächelndes Selfie erstellt (30 Punkte)", comment: "")
        case .three:
            return NSLocalizedString("Quizfrage richtig beantwortet (20 Punkte)", comment: "")
            case .four:
            return NSLocalizedString("Galgenmänchen Spiel richtig gelöst (20 Punkte)", comment: "")
        }
    }
    var points: Int {
        switch self {
        case .one:
            return 40
        case .two:
            return 30
        case .three:
            return 20
        case .four:
            return 20
        }
    }
}
enum WeeklyChallengeType: String, CaseIterable {
    case one = "1"
    case two = "2"
    case three = "3"
    
    var challenge: String {
        switch self {
        case .one:
            return NSLocalizedString("Sehenswürdigkeiten besucht (80 Punkte)", comment: "")
        case .two:
            return NSLocalizedString("Bilder hochgeladen (100 Punkte)", comment: "")
        case .three:
            return NSLocalizedString("2 Tage infolge eine Sehenswürdigkeit besucht (30 Punkte)", comment: "")
        }
    }
    var points: Int {
        switch self {
        case .one:
            return 80
        case .two:
            return 100
        case .three:
            return 30
        }
    }
}

func getWeeklyChallengeText(id: String) -> String {
    return WeeklyChallengeType(rawValue: id)!.challenge
}
func getDailyChallengeText(id: String) -> String {
    return DailyChallengeType(rawValue: id)!.challenge
}

struct WeeklyChallenge: Identifiable, Codable {
    var id: String
    var challenge1: String
    var challenge2: String
    var challenge3: String
    var challenge1Value: Int
    var challenge2Value: Int
    var challenge3Value: Int
}

struct DailyChallenge: Identifiable, Codable {
    var id: String
    var challenge1: String
    var challenge2: String
    var challenge3: String
    var challenge1Value: Int
    var challenge2Value: Int
    var challenge3Value: Int
    
}
