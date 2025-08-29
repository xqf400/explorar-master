//
//  SharedPlaces.swift
//  explorar
//
//  Created by Fabian Kuschke on 04.08.25.
//

import Foundation
import CoreLocation
import MapKit
import Drops

struct Place:Equatable, Identifiable, Hashable {
    let id: Int
    let item: MKMapItem
    let image: UIImage?
    let pointOfInterest: PointOfInterest?
}


class SharedPlaces: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = SharedPlaces()
    
    @Published var interestingPlaces: [Place] = []
    @Published var aIPlaces: [Place] = []
    @Published var currentLocation: CLLocation?
    @Published var currentCity: String = "Unknown City"
    @Published var currentCountry: String = "Unknown Country"
    @Published var currentStreet: String = ""
    @Published var currentHouse: String = ""
    @Published var searchRadius = 600.0
    private var refreshTimer: Timer?
    var timerInterval = 8.0
    
    private let geocoder = CLGeocoder()
    let locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        if self.refreshTimer == nil {
            self.searchInterestLocations()
            self.fetchAddress(from: location)
            self.refreshTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: false, block: { _ in
                self.refreshTimer = nil
            })
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    private func fetchAddress(from location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                print("Geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
                Drops.show(Drop(title: "Geocoding failed: \(error?.localizedDescription ?? "Unknown error")"))
                return
            }
            DispatchQueue.main.async {
                self.currentCity = placemark.locality ?? "Unknown City"
                self.currentStreet = placemark.thoroughfare ?? "Unknown Street"
                self.currentHouse = placemark.subThoroughfare ?? "Unkown House"
                self.currentCountry = placemark.country ?? "Unknown country"
                if isInTestMode {
                    self.currentStreet = "Königstraße"
                    self.currentHouse = "26"
                    self.currentCity = "Stuttgart"
                    self.currentCountry = "Germany"
                }
            }
        }
    }
    
    func addAiPlaces(pois: [PointOfInterest]) {
        if pois.count > 0 {
            aIPlaces = []
        }
        for poi in pois {
            let coordiante = CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude)
            let placemark = MKPlacemark(coordinate: coordiante)
            let item = MKMapItem(placemark: placemark)
            item.name = poi.name
            let numberString = String(poi.latitude)
            let cleanedString = numberString.replacingOccurrences(of: ".", with: "")
            if let id = Int(cleanedString) {
                let place = Place(id: id, item: item, image: UIImage(systemName: "mappin.circle"), pointOfInterest: poi)
                // print("Name1: \(poi.name) Distance: \(SharedPlaces.shared.getDistance(from: place))")
                aIPlaces.append(place)
            }
        }
    }
    
    // MARK: searchInterestLocations
    func searchInterestLocations() {
        guard let userLocation = self.currentLocation else { return }
        var region = MKCoordinateRegion()
        region.center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        
        let request = MKLocalPointsOfInterestRequest(center: region.center, radius: searchRadius)
        var categories: [MKPointOfInterestCategory] = [.cafe, .restaurant, .amusementPark, .aquarium, .museum, .park, .library]
        if #available(iOS 18.0, *) {
            categories = [.restaurant, .amusementPark, .aquarium, .bowling, .museum, .park, .library, .bakery, .castle, .zoo]
        }
        request.pointOfInterestFilter = .some(MKPointOfInterestFilter(including: categories))
        
        let search = MKLocalSearch(request: request)
        self.interestingPlaces.removeAll()
        search.start { (response, error) in
            if let response = response {
                for (count, item) in response.mapItems.enumerated() {
                    let place = Place(id: count, item: item, image: nil, pointOfInterest: nil)
                    self.interestingPlaces.append(place)
                }
            }
        }
        if aIPlaces.count == 0 {
            if let cachedPOIs = AIService.shared.loadAIPOIs(for: currentCity) {
                addAiPlaces(pois: cachedPOIs)
            }
        }

        if FirestoreService.shared.pois.count == 0 {
            FirestoreService.shared.getPOIsFromCity(city: SharedPlaces.shared.currentCity) { result in
            }
        }
        // für später falls zu wenig pois gefunden wurden
        /*
        if self.interestingPlaces.count < 5 {
            self.interestingPlaces.removeAll()
            let request2 = MKLocalPointsOfInterestRequest(center: region.center, radius: 600)
            request2.pointOfInterestFilter = .some(MKPointOfInterestFilter(including: categories))
            let search2 = MKLocalSearch(request: request)
            search2.start { (response, error) in
                if let response = response {
                    for (count, item) in response.mapItems.enumerated() {
                        let place = Place(id: count, item: item, image: nil, pointOfInterest: nil)
                        self.interestingPlaces.append(place)
                    }
                }
            }
        }*/

        self.interestingPlaces = self.interestingPlaces + FirestoreService.shared.pois + aIPlaces
        print("Radius: \(request.radius), Count: \(self.interestingPlaces.count)")
    }
    
    // MARK: Get Distance
    func getDistance(from place: Place) -> Double {
        let coordinate = place.item.placemark.coordinate
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distanceInMeters = self.locationManager.location?.distance(from: location) ?? 0.0
        return distanceInMeters
    }
    func getDistanceStr(from place: Place) -> String {
        let coordinate = place.item.placemark.coordinate
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var distanceInMeters = self.locationManager.location?.distance(from: location) ?? 0.0
        var distanceString = ""
        if distanceInMeters > 1000 {
            distanceInMeters /= 1000
            distanceString = String(format: "%.2f km", distanceInMeters)
        } else {
            distanceString = String(format: "%.2f m", distanceInMeters)
        }
        return distanceString
    }
    
    
    
    // MARK: open Maps
    func openInAppleMaps(coordinate: CLLocationCoordinate2D, name: String) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name

        // Optional: Set a region distance for how zoomed in the map will be
        let regionDistance: CLLocationDistance = 1000
        let regionSpan = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        mapItem.openInMaps(launchOptions: options)
    }
}

