//
//  ListView.swift
//  explorar
//
//  Created by Fabian Kuschke on 04.08.25.
//

import SwiftUI
import CoreLocation

struct ListView: View {
    @ObservedObject private var sharedPlaces = SharedPlaces.shared
    @State private var showAlert = false
    @State private var selectedPlace: Place?
    @State private var pois: [Place] = []
    
    var rowBackgroundGradient: LinearGradient {
        let color1 = Color(red: 80 / 255, green: 201 / 255, blue: 222 / 255)
        return LinearGradient(gradient: Gradient(colors: [color1, .green]),
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var row2BackgroundGradient: LinearGradient {
        let color1 = Color(red: 80 / 255, green: 201 / 255, blue: 222 / 255)
        return LinearGradient(gradient: Gradient(colors: [.green, color1]),
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    private func alertTitle(place: Place?) -> String {
        guard let place = place else { return "" }
        if let poi = place.pointOfInterest {
            return poi.name
        } else {
            return place.item.name ?? ""
        }
    }
    private func alertMessage(place: Place?) -> String {
        guard let place = place else { return "No Place" }
        var message = ""
        let distanceStr = SharedPlaces.shared.getDistanceStr(from: place)
        if let poi = place.pointOfInterest {
            message = "\(NSLocalizedString("Distance", comment: "")): \(distanceStr)"
            for info in poi.shortInfos {
                message += "\n\(info)"
            }
        } else {
            let telefon = place.item.phoneNumber ?? "Not available"
            let postCode = place.item.placemark.postalCode ?? "-"
            let city = place.item.placemark.locality ?? "-"
            let street = place.item.placemark.thoroughfare ?? "-"
            let streetNumber = place.item.placemark.subThoroughfare ?? "-"
            message = "\(NSLocalizedString("Phonenumber", comment: "")).: \(telefon)\n\(NSLocalizedString("Adress", comment: "")): \(postCode) \(city)\n\(street) \(streetNumber)\n\(NSLocalizedString("Distance", comment: "")): \(distanceStr)"
        }
        return message
    }
    
    private func getBackgroundColor(place: Place)-> LinearGradient {
        if let poi = place.pointOfInterest {
            if poi.name.contains("(AI)") {
                return LinearGradient(colors: [Color.green, Color.yellow], startPoint: .leading, endPoint: .trailing)
            } else {
                return rowBackgroundGradient
            }
        } else {
            return LinearGradient(gradient: Gradient(colors: [.green, .gray]),
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
            //row2BackgroundGradient
        }
    }
    
    private func generatePoiTitle(place : Place) -> String {
        guard let poi = place.pointOfInterest else {
            return "\(sharedPlaces.getDistanceStr(from: place)), \(place.item.name ?? "")"
        }
        if poi.creator == "Test" {
            return "\(sharedPlaces.getDistanceStr(from: place)) \(poi.name) (\(getChallengeName(challengeId: poi.challengeId)))"
        } else {
            if !isInTestMode {
                let distance = sharedPlaces.getDistance(from: place)
                if distance > 1000 {
                    return "\(poi.name)"
                }
            }
            return "\(sharedPlaces.getDistanceStr(from: place)) \(poi.name)"
        }
    }
    
    private func getChallengeName(challengeId: Int) -> String {
        
        switch challengeId {
        case 1:
            return "Lächelndes Selfie"
        case 2:
            return "AR-Suche"
        case 3:
            return "Quiz"
        case 4:
            return "Worträstel"
        case 5:
            return "Objekterkennung"
        case 6:
            return "Zeichnen"
        default:
            return ""
        }
    }
    
    // MARK: View
    var body: some View {
        VStack {
            List(Array(pois.enumerated()), id: \.element) { index, place in
                HStack {
                    Text(generatePoiTitle(place: place))
                        //.minimumScaleFactor(0.5)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.3), radius: 12)
                .onTapGesture {
                    selectedPlace = place
                    if !FirestoreService.shared.settings.listClickable && selectedPlace?.pointOfInterest?.creator != "AI" {
                        showAlert = true
                    } else {
                        if place.pointOfInterest == nil {
                            showAlert = true
                        }
                    }
                }
                .listRowBackground(
                    getBackgroundColor(place: place)
                )
            }
            .scrollContentBackground(.hidden)
            .listStyle(InsetGroupedListStyle())
            .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.3), radius: 12)
        }
        //MARK: Just For Testing
        .if(FirestoreService.shared.settings.listClickable || selectedPlace?.pointOfInterest?.creator == "AI") { view in
                view.navigationDestination(item: $selectedPlace) { place in
                    if place.pointOfInterest != nil {
                        PointOfInterestView(pointOfInterest: place.pointOfInterest!) {value in
                            if !value {
                                selectedPlace = nil
                                sharedPlaces.locationManager.startUpdatingLocation()
                            }
                        }
                    }
                }
        }

        .onChange(of: sharedPlaces.interestingPlaces) { oldValue, newValue in
            let withPOI = newValue
                .filter { $0.pointOfInterest != nil }
                .sorted { sharedPlaces.getDistance(from: $0) < sharedPlaces.getDistance(from: $1) }
            let withoutPOI = newValue
                .filter { $0.pointOfInterest == nil }
                .sorted { sharedPlaces.getDistance(from: $0) < sharedPlaces.getDistance(from: $1) }
            pois = withPOI + withoutPOI
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle(place: selectedPlace)),
                  message: Text(alertMessage(place: selectedPlace)),
                  primaryButton: .default(Text(NSLocalizedString("Start navigation", comment: "")), action: {
                SharedPlaces.shared.openInAppleMaps(coordinate: selectedPlace!.item.placemark.coordinate, name:alertTitle(place: selectedPlace))
                selectedPlace = nil
            }),
                  secondaryButton: .default(Text(NSLocalizedString("Cancel", comment: "")), action: {
                selectedPlace = nil
            }))
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool,
                             transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
