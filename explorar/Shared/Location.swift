//
//  Location.swift
//  explorar
//
//  Created by Fabian Kuschke on 30.07.25.
//

import Foundation
import Drops

struct PointOfInterest:Hashable, Codable {
    var id: String
    var shortInfos: [String]
    var text: String
    var images: [String]
    var name: String
    var city: String

    var challenge: String
    var challengeId: Int
    //Location
    var latitude: Double
    var longitude: Double
    // LoadExperience
    var modelName: String
    // QuizView
    var question: String
    var answers: [String]
    var correctIndex: Int
    var poiLanguage: String
    var creator: String
}

func decodePointOfInterest(from plistData: Data) -> PointOfInterest? {
    let decoder = PropertyListDecoder()
    do {
        let poi = try decoder.decode(PointOfInterest.self, from: plistData)
        return poi
    } catch {
        print("Decoding error: \(error)")
        Drops.show(Drop(title: "Decoding error: \(error)"))
        return nil
    }
}
