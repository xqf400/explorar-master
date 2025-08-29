//
//  MapARView.swift
//  explorar
//
//  Created by Fabian Kuschke on 04.08.25.
//


import UIKit
import CoreMotion
import ARKit
import RealityKit
import MapKit

class CustomPointAnnotation: MKPointAnnotation {
    var image: UIImage!
    var id: Int!
    var place: Place?
}

import SwiftUI

struct MapARView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MapARViewController {
        return MapARViewController()
    }
    
    func updateUIViewController(_ uiViewController: MapARViewController, context: Context) {
        // Update as needed
    }
}

class MapARViewController: UIViewController {
    
    private let arBackgroundView = UIView()
    private let mapBackgroundView = UIView()
    private let mapView = MKMapView()
    private let motionManager = CMMotionManager()
    private var compassIcon: MKCompassButton!
    private var switchViewToMap = false
    private let switchAngel: Double = 50.0
    private var refreshTimer: Timer?
    var sceneLocationView = SceneLocationView()
    private let headingManager = CLLocationManager()
    
    // MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureInitialValues()
        headingManager.delegate = self
        headingManager.startUpdatingHeading()
        mapView.delegate = self
        
        // Sorgt dafür, dass man checken kann ob das Gerät eher horizontal ist oder vertical
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { deviceManager, error in
                guard let manager = deviceManager else {return}
                let angle = manager.attitude.pitch * 180 / Double.pi
                if angle < self.switchAngel {
                    if !self.switchViewToMap {
                        self.switchToMapAnim()
                    }
                    self.switchViewToMap = true
                } else {
                    if self.switchViewToMap {
                        self.switchToARAnim()
                    }
                    self.switchViewToMap = false
                }
            }
        }
        let tapped = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        sceneLocationView.isUserInteractionEnabled = true
        sceneLocationView.addGestureRecognizer(tapped)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        sceneLocationView.frame = arBackgroundView.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneLocationView.session.pause()
    }
    
    // MARK: UI setup
    private func setupUI() {
        view.backgroundColor = .white
        arBackgroundView.backgroundColor = .black
        arBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        mapBackgroundView.backgroundColor = .white
        mapBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(arBackgroundView)
        view.addSubview(mapBackgroundView)
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapBackgroundView.addSubview(mapView)
        
        sceneLocationView.translatesAutoresizingMaskIntoConstraints = false
        arBackgroundView.addSubview(sceneLocationView)
        
        compassIcon = MKCompassButton(mapView: mapView)
        compassIcon.translatesAutoresizingMaskIntoConstraints = false
        compassIcon.compassVisibility = .visible
        view.addSubview(compassIcon)
        
        sceneLocationView.run()
        
        NSLayoutConstraint.activate([
            arBackgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            arBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            arBackgroundView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1.0),
            
            mapBackgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapBackgroundView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1.0),
            
            mapView.topAnchor.constraint(equalTo: mapBackgroundView.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: mapBackgroundView.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: mapBackgroundView.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: mapBackgroundView.bottomAnchor),
            
            sceneLocationView.topAnchor.constraint(equalTo: arBackgroundView.topAnchor),
            sceneLocationView.leadingAnchor.constraint(equalTo: arBackgroundView.leadingAnchor),
            sceneLocationView.trailingAnchor.constraint(equalTo: arBackgroundView.trailingAnchor),
            sceneLocationView.bottomAnchor.constraint(equalTo: arBackgroundView.bottomAnchor),
            
        ])
        NSLayoutConstraint.activate([
            compassIcon.trailingAnchor.constraint(equalTo: mapBackgroundView.trailingAnchor, constant: -40),
            compassIcon.topAnchor.constraint(equalTo: mapBackgroundView.bottomAnchor, constant: -80)
        ])
        
        arBackgroundView.isHidden = true
        arBackgroundView.alpha = 0
        mapBackgroundView.isHidden = false
        mapBackgroundView.alpha = 1
    }
    
    private func configureInitialValues() {
        mapView.mapType = .standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsScale = true
        mapView.showsTraffic = false
        mapView.showsCompass = false
    }
    
    // MARK: activateAR
    private func activateAR() {
        // print("activateAR")
        sceneLocationView.run()
        placePlacesInAR()
    }
    
    // MARK: deactivateAR
    private func deactivateAR() {
        // print("deactivateAR")
        sceneLocationView.pause()
        self.placeAllInterestPlacesOnMap()
    }
    
    // MARK: Switch to AR
    private func switchToARAnim() {
        activateAR()
        DispatchQueue.main.async {
            self.arBackgroundView.isHidden = false
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: .curveEaseInOut, animations: {
                self.mapBackgroundView.alpha = 0
                self.arBackgroundView.alpha = 1
            }) { _ in
                self.mapBackgroundView.isHidden = true
            }
        }
    }
    
    // MARK: Switch to Map
    private func switchToMapAnim() {
        DispatchQueue.main.async {
            self.mapBackgroundView.isHidden = false
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: .curveEaseInOut, animations: {
                self.arBackgroundView.alpha = 0
                self.mapBackgroundView.alpha = 1
            }) { _ in
                self.arBackgroundView.isHidden = true
                self.deactivateAR()
            }
        }
    }
    
    // MARK: Tap Gesture
    @objc func tapped(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            let location: CGPoint = sender.location(in: sceneLocationView)
            let hits = self.sceneLocationView.hitTest(location, options: nil)
            if !hits.isEmpty{
                guard let tappedNode = hits.first?.node else {return}
                guard let name = tappedNode.name else {return}
                if tappedNode.name != nil {
                    guard let placeId = Int(name) else {return}
                    for place1 in SharedPlaces.shared.interestingPlaces where place1.id == placeId {
                        showInfosAboutPlace(place: place1)
                    }
                } else {
                    print("tapped node is nil")
                }
            }
        }
    }
    
    // MARK: placeAllInterestPlacesOnMap
    private func placeAllInterestPlacesOnMap() {
        self.mapView.removeAnnotations(self.mapView.annotations)
        for place in SharedPlaces.shared.interestingPlaces {
            let annotation = CustomPointAnnotation()
            annotation.title = place.item.name
            annotation.place = place
            annotation.id = place.id
            let image = place.image == nil ? UIImage(systemName: "mappin.and.ellipse.circle")! : place.image
            let size = CGSize(width: 50, height: 50)
            UIGraphicsBeginImageContext(size)
            image!.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            annotation.image = resizedImage ?? image
            annotation.coordinate = place.item.placemark.coordinate
            self.mapView.addAnnotation(annotation)
        }
    }
    
    //MARK: Show Alert
    private func showInfosAboutPlace(place: Place) {
        // Navigation not needed
//        let vc = UIHostingController(
//            rootView: PointOfInterestView(pointOfInterest: place.pointOfInterest!) { value in
//                if !value {
//                    SharedPlaces.shared.locationManager.startUpdatingLocation()
//                    self.navigationController?.popViewController(animated: true)
//                }
//            }
//        )
//        self.navigationController?.pushViewController(vc, animated: true)
        var message = NSLocalizedString("Infos", comment: "")
        var title =  NSLocalizedString("About the location", comment: "")
        let distance = SharedPlaces.shared.getDistance(from: place)
        let distanceStr = "\(NSLocalizedString("Distance", comment: "")): \(String(format: "%.2f m", distance))"

        if let poi = place.pointOfInterest {
            title = "\(poi.name)"
            message = "\(NSLocalizedString("Distance", comment: "")): \(distanceStr)"
            for info in poi.shortInfos {
                message += "\n\(info)"
            }
        } else {
            guard let name = place.item.name else { return }
            title = name
            let telefon = place.item.phoneNumber ?? ""
            let postCode = place.item.placemark.postalCode ?? ""
            let city = place.item.placemark.locality ?? ""
            let street = place.item.placemark.thoroughfare ?? ""
            let streetNumber = place.item.placemark.subThoroughfare ?? ""
 
            message = "\(NSLocalizedString("Phonenumber", comment: "")).: \(telefon)\n\(NSLocalizedString("Adress", comment: "")): \(postCode) \(city)\n\(street) \(streetNumber)\n\(NSLocalizedString("Distance", comment: "")): \(distanceStr)"
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Start navigation", comment: ""), style: .default, handler: { action in
            SharedPlaces.shared.openInAppleMaps(coordinate: place.item.placemark.coordinate, name:title)
        }))
        present(alert, animated: true)
    }
    
    // MARK: Place places in AR
    private func placePlacesInAR() {
        // print("placePlaces")
        guard let currentLocation = SharedPlaces.shared.currentLocation else { return }
        sceneLocationView.removeAllNodes()
        // print("currentLocation not nil \(interestingPlaces.count)")
        for place in SharedPlaces.shared.interestingPlaces {
            let coordinate = place.item.placemark.coordinate
            let location = CLLocation(coordinate: coordinate, altitude: currentLocation.altitude)
            var distanceInMeters = SharedPlaces.shared.getDistance(from: place)
            
            var stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: 150, height: 60))
            if distanceInMeters < 200 {
                let image = place.image == nil ? UIImage(systemName: "mappin.and.ellipse.circle") : place.image
                let imageView = UIImageView(image: image)
                imageView.frame = CGRect(x: 0, y: 0, width: 100, height: 200)
                imageView.contentMode = .scaleAspectFit
                imageView.clipsToBounds = true
                stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: 150, height: 200))
                stackView.addArrangedSubview(imageView)
                stackView.backgroundColor = .clear
            } else {
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
                label.text = NSLocalizedString("Move closer", comment: "")
                label.layer.masksToBounds = true
                label.numberOfLines = 0
                label.layer.cornerRadius = 10
                label.textAlignment = .center
                label.textColor = .white
                label.backgroundColor = .black
                label.font = UIFont.boldSystemFont(ofSize: 18.0)
                stackView.addArrangedSubview(label)
                stackView.backgroundColor = .black
            }
            let distanceLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
            distanceLabel.backgroundColor = .black
            var distanceString = ""
            if distanceInMeters > 1000 {
                distanceInMeters /= 1000
                distanceString = String(format: "\(place.item.name ?? "") %.2f km", distanceInMeters)
            } else {
                distanceString = String(format: "\(place.item.name ?? "") %.2f m", distanceInMeters)
            }
            distanceLabel.text = distanceString
            distanceLabel.numberOfLines = 0
            distanceLabel.textColor = .white
            distanceLabel.textAlignment = .center
            distanceLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
            stackView.addArrangedSubview(distanceLabel)
            stackView.axis = .vertical
            stackView.layer.masksToBounds = true
            stackView.layer.cornerRadius = 10
            stackView.tag = place.id
            
            let annotationNode = LocationAnnotationNode(location: location, view: stackView)
            annotationNode.annotationNode.name = "\(place.id)"
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        }
    }
}

// MARK: - CLLocationManagerDelegate, MKMapViewDelegate
extension MapARViewController: CLLocationManagerDelegate, MKMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        mapView.setUserTrackingMode(.followWithHeading, animated: false)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if(CLLocationCoordinate2DIsValid(mapView.centerCoordinate)) {
            mapView.camera.heading = newHeading.trueHeading
            if self.refreshTimer == nil {
                if self.mapBackgroundView.isHidden {
                    placePlacesInAR()
                } else {
                    placeAllInterestPlacesOnMap()
                    
                }
                self.refreshTimer = Timer.scheduledTimer(withTimeInterval: SharedPlaces.shared.timerInterval, repeats: false, block: { _ in
                    self.refreshTimer = nil
                })
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "MyPin"
        if annotation is MKUserLocation { return nil }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            let cpa = annotation as! CustomPointAnnotation
            annotationView?.image = cpa.image
            annotationView?.tag = cpa.id
            annotationView?.backgroundColor = .clear
            annotationView?.layer.cornerRadius = 50/2
            annotationView?.layer.borderWidth = 0.8
            annotationView?.layer.borderColor = UIColor.black.cgColor
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation else { return }
        if view.tag != -1 && annotation.title != nil {
            if let place = SharedPlaces.shared.interestingPlaces.first(where: { $0.item.name == annotation.title }) {
                showInfosAboutPlace(place: place)
            }
        }
    }
}

