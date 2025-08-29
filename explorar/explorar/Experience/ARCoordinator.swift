//
//  ARCoordinator.swift
//  explorar
//
//  Created by Fabian Kuschke on 29.07.25.
//

import SceneKit
import ARKit
import ImageIO
import SwiftUI
import Drops

class ARCoordinator: NSObject, ObservableObject, ARSCNViewDelegate, ARSessionDelegate {
    weak var sceneView: ARSCNView?
    @Published var sessionInfo: String = "Initializing AR..."
    @Published var saveEnabled = false
    @Published var loadEnabled = false
    @Published var snapshotImage: UIImage?
    @Published var tempMessage: String?
    @Published var isRelocalizingMap = false
    @Published var objectIsPlaced: Bool = false
    
    @Published var isLoading: Bool = false
    @Published var loadingProgress: Double = 0.0
    var localSceneDir: URL?
    var localModelURL: URL?
    var localMapURL: URL?
    var name = ""
    var placeName = ""
    var creationModeIsOn = false
    
    
    private(set) var virtualObjectAnchor: ARAnchor?
    private let virtualObjectAnchorName = "virtualObject"
    
    func pauseSession() {
        sceneView?.session.pause()
        print("Debug: ARSession paused")
    }
    
    func defaultConfiguration() -> ARWorldTrackingConfiguration {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        return config
    }
    
    @objc func handleSceneTap(_ sender: UITapGestureRecognizer) {
        guard let sceneView = sceneView else {
            print("Debug: handleSceneTap failed - sceneView is nil")
            return
        }
        if isRelocalizingMap && virtualObjectAnchor == nil {
            print("Debug: Tap ignored while relocalizing")
            return
        }
        
        let location = sender.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(location, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
        guard let hitResult = hitTestResults.first else {
            print("Debug: Tap location did not hit any plane")
            return
        }
        
        if let existingAnchor = virtualObjectAnchor {
            sceneView.session.remove(anchor: existingAnchor)
            print("Debug: Removed existing virtual object anchor")
        }
        creationModeIsOn = true
        let newAnchor = ARAnchor(name: virtualObjectAnchorName, transform: hitResult.worldTransform)
        sceneView.session.add(anchor: newAnchor)
        virtualObjectAnchor = newAnchor
        print("Debug: Virtual object placed at new anchor")
        showTempMessage("Virtual object placed.")
    }
    func resetScene() {
        guard let sceneView = sceneView else { return }
        print("Debug: Resetting AR session")
        let config = defaultConfiguration()
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        isRelocalizingMap = false
        virtualObjectAnchor = nil
        snapshotImage = nil
        tempMessage = "Scene reset. Tap to place the object"
        sessionInfo = "Tap the screen to place a virtual object."
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Unter Tische etc
        /*
         if let planeAnchor = anchor as? ARPlaneAnchor {
         let occlusionPlane: SCNPlane
         let occlusionNode = SCNNode()
         
         if planeAnchor.alignment == .horizontal {
         // For floor
         occlusionPlane = SCNPlane(
         width: CGFloat(planeAnchor.extent.x),
         height: CGFloat(planeAnchor.extent.z)
         )
         occlusionNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
         occlusionNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
         } else if planeAnchor.alignment == .vertical {
         // For walls
         occlusionPlane = SCNPlane(
         width: CGFloat(planeAnchor.extent.x),
         height: CGFloat(planeAnchor.extent.y)
         )
         occlusionNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
         occlusionNode.eulerAngles = SCNVector3(0, 0, 0)
         } else {
         return
         }
         
         let mat = SCNMaterial()
         mat.colorBufferWriteMask = []
         mat.isDoubleSided = true
         occlusionPlane.materials = [mat]
         occlusionNode.geometry = occlusionPlane
         occlusionNode.name = "occlusionPlane"
         node.addChildNode(occlusionNode)
         }*/
        guard anchor.name == virtualObjectAnchorName else { return }
        DispatchQueue.main.async {
            if self.isRelocalizingMap {
                self.isRelocalizingMap = false
                self.snapshotImage = nil
                self.tempMessage = nil
            }
            self.virtualObjectAnchor = anchor
            node.addChildNode(self.virtualObject())
            self.objectIsPlaced = true
            print("Debug: Virtual object added to scene")
        }
    }
    // Unter Tische etc
    /*
     func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
     guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
     for child in node.childNodes where child.name == "occlusionPlane" {
     if let plane = child.geometry as? SCNPlane {
     if planeAnchor.alignment == .horizontal {
     plane.width = CGFloat(planeAnchor.extent.x)
     plane.height = CGFloat(planeAnchor.extent.z)
     child.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
     child.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
     } else if planeAnchor.alignment == .vertical {
     plane.width = CGFloat(planeAnchor.extent.x)
     plane.height = CGFloat(planeAnchor.extent.y)
     child.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
     child.eulerAngles = SCNVector3(0, 0, 0)
     }
     }
     }
     }*/
    
    func showTempMessage(_ message: String, duration: TimeInterval = 2.5) {
        DispatchQueue.main.async {
            self.tempMessage = message
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation { self.tempMessage = nil }
            }
        }
    }
    
    func virtualObject() -> SCNNode {
        let lightNode = SCNNode()
        let light = SCNLight()
        light.type = .ambient
        light.intensity = 100
        light.color = UIColor.white
        lightNode.light = light
        lightNode.position = SCNVector3(0, 5, 0)
        let scale = 0.002
        if self.creationModeIsOn {
            guard let sceneURL = getModelURL(),
                  let referenceNode = SCNReferenceNode(url: sceneURL) else  {
                print("Model file not found in bundle \(name)")
                Drops.show(Drop(title: "Model file not found in bundle \(name)"))
                // fatalError("can't load local virtual object")
                return SCNNode()
            }

            referenceNode.load()
            referenceNode.scale = SCNVector3(scale, scale, scale)
            referenceNode.addChildNode(lightNode)
            self.creationModeIsOn = false
            return referenceNode
        } else {
            guard let referenceNode = SCNReferenceNode(url: self.localModelURL!) else {
                fatalError("Can't load virtual object from local URL: \(self.localModelURL!)")
            }
            referenceNode.load()
            referenceNode.scale = SCNVector3(scale, scale, scale)
            referenceNode.addChildNode(lightNode)
            return referenceNode
        }
    }
    
    func getLocalSceneDirectory(for sceneName: String) throws -> URL {
        let libraryDir = try FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true)
        let sceneDir = libraryDir.appendingPathComponent("Places").appendingPathComponent(sceneName)
        
        if !FileManager.default.fileExists(atPath: sceneDir.path) {
            try FileManager.default.createDirectory(at: sceneDir, withIntermediateDirectories: true)
            print("Debug: Created directory: \(sceneDir.path)")
        }
        return sceneDir
    }
    
    func loadScene(modelName: String, place: String) {
        isLoading = true
        loadingProgress = 0
        
        print("Debug: 1Retrieved modelName: \(modelName), mapName: \(modelName).arexperience")
        
        do {
            self.localSceneDir = try self.getLocalSceneDirectory(for: place)
            
            guard let sceneDir = self.localSceneDir else {
                throw NSError(domain: "FolderCreation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get or create scene dir"])
            }
            
            self.localModelURL = sceneDir.appendingPathComponent("\(modelName).usdz")
            self.localMapURL = sceneDir.appendingPathComponent("\(self.name).arexperience")
            
            let dispatchGroup = DispatchGroup()
            
            // Check and download model file if missing
            if !FileManager.default.fileExists(atPath: self.localModelURL!.path) {
                dispatchGroup.enter()
                print("Debug: Model file missing locally, starting download...")
                downloadFileFromFireBase(name: modelName, folder: "Places/\(place)", safeFile: false) { data in
                    print("Debug: Model downloaded successfully.")
                    do {
                        try data.write(to: self.localModelURL!)
                        print("Wrote model to \(self.localModelURL!)")
                    } catch let error{
                        print("Error writing file1 \(error)")
                        Drops.show(Drop(title: "Error writing file1 \(error)"))
                    }
                    dispatchGroup.leave()
                } failure: { error in
                    print("Error1 downloading \(error)")
                    Drops.show(Drop(title: "Error1 downloading \(error)"))
                    dispatchGroup.leave()
                }
            } else {
                print("Debug: Model file found locally at \(self.localModelURL!.path)")
            }
            
            // Check and download map file if missing
            if !FileManager.default.fileExists(atPath: self.localMapURL!.path) {
                dispatchGroup.enter()
                print("Debug: Map file missing locally, starting download...")
                
                downloadFileFromFireBase(name: "\(modelName).arexperience", folder: "Places/\(place)", safeFile: false) { data in
                    print("Debug: Map downloaded successfully.")
                    do {
                        try data.write(to: self.localMapURL!)
                        print("Wrote map to \(self.localMapURL!)")
                    } catch let error{
                        print("Error writing file2 \(error)")
                        Drops.show(Drop(title: "Error writing file2 \(error)"))
                    }
                    dispatchGroup.leave()
                } failure: { error in
                    print("Error1 downloading \(error)")
                    Drops.show(Drop(title: "Error1 downloading \(error)"))
                    dispatchGroup.leave()
                }
            } else {
                print("Debug: Map file found locally at \(self.localMapURL!.path)")
            }
            
            dispatchGroup.notify(queue: .main) {
                self.isLoading = false
                self.loadExperienceFromLocalFiles(mapURL: self.localMapURL!)
            }
            
        } catch {
            print("Debug: Folder creation or file path error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoading = false
                self.showTempMessage("Failed to prepare local scene folder.")
            }
        }
    }
    func getModelURL() -> URL? {
        print("Modelurl: \(name)")
        let docs = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let saved = docs.appendingPathComponent("\(name).usdz")
        
        if FileManager.default.fileExists(atPath: saved.path) {
            return saved
        }
        return nil
    }
    
    func loadExperienceFromLocalFiles(mapURL: URL) {
        guard let sceneView = sceneView else { return }
        
        do {
            let data = try Data(contentsOf: mapURL)
            print("Debug: got data \(data.count)")
            
            // Wichtig für app clip
            NSKeyedUnarchiver.setClass(SnapshotAnchor.self, forClassName: "explorar.SnapshotAnchor")
            let allowedClasses: [AnyClass] = [ARWorldMap.self, SnapshotAnchor.self, ARAnchor.self]
            
            guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedClasses, from: data) else {
                print("Debug: No ARWorldMap in archive")
                showTempMessage("Failed to load world map")
                return
            }
            
            guard let worldMap = worldMap as? ARWorldMap else {
                print("Debug: worldMap is not of type ARWorldMap")
                return
            }
            
            if let snapshotData = worldMap.snapshotAnchor?.imageData,
               let snapshot = UIImage(data: snapshotData) {
                DispatchQueue.main.async {
                    self.snapshotImage = snapshot
                    self.isRelocalizingMap = true
                }
            }
            
            let mutableWorldMap = worldMap
            mutableWorldMap.anchors.removeAll(where: { $0 is SnapshotAnchor })
            
            let config = defaultConfiguration()
            config.initialWorldMap = mutableWorldMap
            
            sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
            isRelocalizingMap = true
            virtualObjectAnchor = nil
            
            showTempMessage("Move device to match image for relocalization.")
            print("Debug: AR session started with downloaded world map")
        } catch {
            print("Decoding error: \(error)")   // <= error details here
            showTempMessage("Failed to load world map: \(error.localizedDescription)")
        }
    }
    
}

// MARK: ARViewContainer
struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var arCoordinator: ARCoordinator
    func makeCoordinator() -> ARCoordinator { arCoordinator }
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.delegate = arCoordinator
        arView.session.delegate = arCoordinator
        arView.autoenablesDefaultLighting = true
        arCoordinator.sceneView = arView
        
        let tapGesture = UITapGestureRecognizer(target: arCoordinator, action: #selector(ARCoordinator.handleSceneTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        let config = arCoordinator.defaultConfiguration()
        arView.session.run(config)
        
        print("Debug: ARSCNView created and session started")
        return arView
    }
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

// MARK: SnapshotAnchor
class SnapshotAnchor: ARAnchor {
    let imageData: Data
    
    init(imageData: Data, transform: simd_float4x4) {
        self.imageData = imageData
        super.init(name: "snapshot", transform: transform)
    }
    
    required init(anchor: ARAnchor) {
        guard let snapshotAnchor = anchor as? SnapshotAnchor else {
            fatalError("Expected SnapshotAnchor type")
        }
        self.imageData = snapshotAnchor.imageData
        super.init(anchor: anchor)
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let snapshot = aDecoder.decodeObject(of: NSData.self, forKey: "snapshot") as Data? else {
            return nil
        }
        self.imageData = snapshot
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(imageData, forKey: "snapshot")
    }
    
    override class var supportsSecureCoding: Bool {
        return true
    }
}


// MARK: EX WorldMappingStatus
extension ARFrame.WorldMappingStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notAvailable: return "Not Available"
        case .limited: return "Limited"
        case .extending: return "Extending"
        case .mapped: return "Mapped"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: EX TrackingState
extension ARCamera.TrackingState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .normal:
            return "Normal"
        case .notAvailable:
            return "Not Available"
        case .limited(.initializing):
            return "Initializing"
        case .limited(.excessiveMotion):
            return "Excessive Motion"
        case .limited(.insufficientFeatures):
            return "Insufficient Features"
        case .limited(.relocalizing):
            return "Relocalizing"
        case .limited:
            return "Unspecified"
        }
    }
    var localizedFeedback: String {
        switch self {
        case .normal:
            return "Move around to map the environment."
        case .notAvailable:
            return "Tracking unavailable."
        case .limited(.excessiveMotion):
            return "Move the device more slowly."
        case .limited(.insufficientFeatures):
            return "Point the device at an area with visible surface detail, or improve lighting."
        case .limited(.relocalizing):
            return "Resuming session — move to where you were when the session was interrupted."
        case .limited(.initializing):
            return "Initializing AR session."
        case .limited:
            return "Tracking limited - unspecified reason"
        }
    }
}

// MARK: EX ARWorldMap
extension ARWorldMap {
    var snapshotAnchor: SnapshotAnchor? {
        anchors.compactMap { $0 as? SnapshotAnchor }.first
    }
}

// MARK: EX CGImagePropertyOrientation
extension CGImagePropertyOrientation {
    init(cameraOrientation: UIDeviceOrientation) {
        switch cameraOrientation {
        case .portrait:
            self = .right
        case .portraitUpsideDown:
            self = .left
        case .landscapeLeft:
            self = .up
        case .landscapeRight:
            self = .down
        default:
            self = .right
        }
    }
}


#if !APPCLIP
import FirebaseFirestore
import FirebaseStorage
import TelemetryClient
extension ARCoordinator {
    // MARK: Create
    func uploadSceneToFirebase(placeName: String, modelName: String) {
        isLoading = true
        self.name = modelName
        self.placeName = placeName
        let storageRef = Storage.storage().reference()
        let firestore = Firestore.firestore()
        guard let modelURL = getModelURL() else  {
            print("Model file not found in bundle \(name)")
            Drops.show(Drop(title: "Model file not found in bundle \(name)"))
            self.isLoading = false
            return
        }
        
        let modelRef = storageRef.child("Places/\(placeName)/\(name)")
        let mapRef = storageRef.child("Places/\(placeName)/\(name).arexperience")
        let poiPlistRef = storageRef.child("Locations/\(placeName).plist")
        
        let uploadGroup = DispatchGroup()
        
        uploadGroup.enter()
        modelRef.putFile(from: modelURL, metadata: nil) { metadata, error in
            if let error = error {
                print("Model upload failed with error: \(error.localizedDescription)")
                self.isLoading = false
                self.showTempMessage("Model upload failed with error: \(error.localizedDescription)")
            } else {
                print("Model uploaded successfully.")
                self.showTempMessage("Model uploaded successfully.")
            }
            uploadGroup.leave()
        }
        
        uploadGroup.enter()
        sceneView?.session.getCurrentWorldMap { worldMap, error in
            if let error = error {
                print("Failed to get current world map: \(error.localizedDescription)")
                self.showTempMessage("Failed to get current world map: \(error.localizedDescription)")
                self.isLoading = false
                uploadGroup.leave()
                return
            }
            guard let map = worldMap else {
                print("World map is nil")
                self.isLoading = false
                self.showTempMessage("World map is nil")
                uploadGroup.leave()
                return
            }
            
            if let frame = self.sceneView?.session.currentFrame {
                let ciImage = CIImage(cvPixelBuffer: frame.capturedImage)
                let orientation = CGImagePropertyOrientation(cameraOrientation: UIDevice.current.orientation)
                let ciImageOriented = ciImage.oriented(orientation)
                let context = CIContext()
                if let cgImage = context.createCGImage(ciImageOriented, from: ciImageOriented.extent) {
                    let uiImage = UIImage(cgImage: cgImage)
                    if let data = uiImage.jpegData(compressionQuality: 0.7) {
                        let snapshotAnchor = SnapshotAnchor(imageData: data, transform: frame.camera.transform)
                        map.anchors.append(snapshotAnchor)
                        print("SnapshotAnchor added to map before upload")
                    } else {
                        self.isLoading = false
                        print("Could not create JPEG data for snapshot anchor")
                        self.showTempMessage("Could not create JPEG data for snapshot anchor")
                    }
                } else {
                    self.isLoading = false
                    print("Could not create CGImage for snapshot anchor")
                    self.showTempMessage("Could not create CGImage for snapshot anchor")
                }
            }
            
            do {
                // Register the class name for SnapshotAnchor so archive is compatible with App Clip unarchiving
                NSKeyedArchiver.setClassName("explorar.SnapshotAnchor", for: SnapshotAnchor.self)
                
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                let metadata = StorageMetadata()
                metadata.contentType = "application/octet-stream"
                
                mapRef.putData(data, metadata: metadata) { metadata, error in
                    if let error = error {
                        print("Debug: Map upload failed with error: \(error.localizedDescription)")
                        self.showTempMessage("Debug: Map upload failed with error: \(error.localizedDescription)")
                        self.isLoading = false
                    } else {
                        print("Map uploaded successfully.")
                        self.showTempMessage("Experience map uploaded.")
                        self.isLoading = false
                    }
                    uploadGroup.leave()
                }
            } catch {
                print("Error archiving world map: \(error.localizedDescription)")
                self.showTempMessage("Error archiving world map: \(error.localizedDescription)")
                uploadGroup.leave()
                self.isLoading = false
            }
        }
        
        /*
        uploadGroup.enter()
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let data = try encoder.encode(poi)
            let metadata = StorageMetadata()
            metadata.contentType = "application/x-plist"
            
            poiPlistRef.putData(data, metadata: metadata) { metadata, error in
                if let error = error {
                    print("Debug: Failed to upload POI plist: \(error.localizedDescription)")
                    self.isLoading = false
                } else {
                    print("Debug: POI plist uploaded successfully to Storage.")
                }
                uploadGroup.leave()
            }
        } catch {
            print("Debug: Error encoding POI to plist: \(error.localizedDescription)")
            self.isLoading = false
            uploadGroup.leave()
        }
        
        //Firestore document
        uploadGroup.notify(queue: .main) {
            do {
                try firestore.collection("pointsOfInterest").document(self.placeName).setData(from: poi) { error in
                    if let error = error {
                        print("Debug: Failed to create Firestore document: \(error.localizedDescription)")
                    } else {
                        print("Debug: Firestore document created/updated successfully.")
                        FirebaseStorageService.shared.createAndUploadFileListJSON() { result in
                            switch result {
                            case .success(let bool):
                                print("success UploadFileListJSON \(bool)")
                                self.isLoading = false
                                self.showTempMessage("Upload & Firestore entry successful!")
                                TelemetryDeck.signal("Saved Experience")
                            case .failure(let error):
                                print("Error2 \(error.localizedDescription)")
                            }
                        }
                    }
                }
            } catch {
                print("Debug: Firestore data encoding error: \(error.localizedDescription)")
                self.isLoading = false
            }
        }*/
    }
    
    
    // MARK: Load
    func loadScene(named sceneName: String) {
        let firestore = Firestore.firestore()
        let storage = Storage.storage()
        
        isLoading = true
        loadingProgress = 0
        
        firestore.collection("pointsOfInterest").document(sceneName).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Debug: Firestore getDocument error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showTempMessage("Failed to load scene info.")
                }
                return
            }
            
            guard let data = snapshot?.data(),
                  let modelName = data["modelName"] as? String else {
                print("Debug: Invalid data in Firestore document")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showTempMessage("Scene info not found.")
                }
                return
            }
            
            print("Debug: 2Retrieved modelName: \(modelName), mapName: \(self.name).arexperience")
            
            do {
                self.localSceneDir = try self.getLocalSceneDirectory(for: sceneName)
                
                guard let sceneDir = self.localSceneDir else {
                    throw NSError(domain: "FolderCreation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get or create scene dir"])
                }
                
                self.localModelURL = sceneDir.appendingPathComponent(modelName)
                self.localMapURL = sceneDir.appendingPathComponent("\(self.name).arexperience")
                
                let dispatchGroup = DispatchGroup()
                
                // Check and download model file if missing
                if !FileManager.default.fileExists(atPath: self.localModelURL!.path) {
                    dispatchGroup.enter()
                    print("Debug: Model file missing locally, starting download...")
                    let modelRef = storage.reference().child("Places/\(sceneName)/\(modelName)")
                    modelRef.write(toFile: self.localModelURL!) { url, error in
                        if let error = error {
                            print("Debug: Model download error: \(error.localizedDescription)")
                            self.showTempMessage("Failed to download model.")
                        } else {
                            print("Debug: Model downloaded successfully.")
                            print("Wrote model to \(self.localModelURL!)")
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    print("Debug: Model file found locally at \(self.localModelURL!.path)")
                }
                
                // Check and download map file if missing
                if !FileManager.default.fileExists(atPath: self.localMapURL!.path) {
                    dispatchGroup.enter()
                    print("Debug: Map file missing locally, starting download...")
                    let mapRef = storage.reference().child("Places/\(sceneName)/\(self.name).arexperience")
                    mapRef.write(toFile: self.localMapURL!) { url, error in
                        if let error = error {
                            print("Debug: Map download error: \(error.localizedDescription)")
                            self.showTempMessage("Failed to download map.")
                        } else {
                            print("Debug: Map downloaded successfully.")
                            print("Wrote map to \(self.localMapURL!)")
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    print("Debug: Map file found locally at \(self.localMapURL!.path)")
                }
                
                // After all downloads complete
                dispatchGroup.notify(queue: .main) {
                    self.isLoading = false
                    self.loadExperienceFromLocalFiles(mapURL: self.localMapURL!)
                }
                
            } catch {
                print("Debug: Folder creation or file path error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showTempMessage("Failed to prepare local scene folder.")
                }
            }
        }
    }
}
#endif
