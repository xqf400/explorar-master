//
//  ARSCNViewContainer.swift
//  explorar
//
//  Created by Fabian Kuschke on 08.09.25.
//

import SwiftUI
import ARKit
import SceneKit
import simd


// MARK: ARSCNImageViewContainer
struct ARSCNImageViewContainer: UIViewRepresentable {
    let image: UIImage
    
    func makeCoordinator() -> Coordinator { Coordinator(image: image) }
    
    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.automaticallyUpdatesLighting = true
        view.delegate = context.coordinator
        view.session.delegate = context.coordinator
        
        view.scene.rootNode.addChildNode(context.coordinator.focusSquare)
        
        context.coordinator.installCoachingOverlay(on: view)
        
        context.coordinator.installGestures(on: view)
        
        context.coordinator.startSession(on: view)
        return view
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) { /* no-op */ }
    
    // MARK: Coordinator
    final class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate, UIGestureRecognizerDelegate, ARCoachingOverlayViewDelegate {
        
        private let image: UIImage
        
        private var placedNode: SCNNode?
        private var selectedNode: SCNNode?
        
        var focusSquare = FocusSquare1()
        private var coachingOverlay = ARCoachingOverlayView()
        private var configuration = ARWorldTrackingConfiguration()
        private let updateQueue = DispatchQueue(label: "com.fku.Square")
        
        private let minScale: Float = 0.05
        private let maxScale: Float = 16.0
        
        init(image: UIImage) { self.image = image }
        
        // MARK: startSession
        func startSession(on view: ARSCNView) {
            guard ARWorldTrackingConfiguration.isSupported else { return }
            configuration.planeDetection = [.vertical, .horizontal]
            configuration.environmentTexturing = .automatic
            configuration.isLightEstimationEnabled = true
            view.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        
        // MARK: installCoachingOverlay
        func installCoachingOverlay(on view: ARSCNView) {
            coachingOverlay.session = view.session
            coachingOverlay.delegate = self
            coachingOverlay.activatesAutomatically = true
            coachingOverlay.goal = .anyPlane
            coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(coachingOverlay)
            NSLayoutConstraint.activate([
                coachingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                coachingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                coachingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
                coachingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        // MARK: installGestures
        func installGestures(on view: ARSCNView) {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            [tap, pan, pinch, longPress].forEach {
                $0.delegate = self
                view.addGestureRecognizer($0)
            }
        }
        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
        
        // MARK: Tap/place
        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? ARSCNView else { return }
            let p = gesture.location(in: view)
            guard let hit = raycastBest(at: p, in: view) else { return }
            
            let t = hit.worldTransform
            var pos = SIMD3<Float>(t.columns.3.x, t.columns.3.y, t.columns.3.z)
            
            let n = surfaceNormal(from: t)
            let base = baseFromTransform(t)
            let ori = base
            
            if let node = placedNode {
                node.simdOrientation = ori
                pos += n * 0.002
                node.simdPosition = pos
            } else {
                placeImage(at: pos, normal: n, base: base, in: view)
            }
        }
        
        private func placeImage(at posIn: SIMD3<Float>, normal n: SIMD3<Float>, base: simd_quatf, in view: ARSCNView) {
            let aspect = image.size.height / image.size.width
            let width: CGFloat = 0.5, height: CGFloat = width * aspect
            
            let plane = SCNPlane(width: width, height: height)
            let m = SCNMaterial(); m.diffuse.contents = image; m.isDoubleSided = true
            plane.materials = [m]
            
            let node = SCNNode(geometry: plane)
            node.simdOrientation = base
            node.simdPosition = posIn + n * 0.002
            node.name = "postedImage"
            view.scene.rootNode.addChildNode(node)
            placedNode = node
            focusSquare.isHidden = true
        }
        
        // MARK: Pan/move
        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? ARSCNView else { return }
            let p = gesture.location(in: view)
            
            switch gesture.state {
            case .began:
                if let hit = view.hitTest(p, options: nil).first,
                   let name = hit.node.name, name == "postedImage" {
                    selectedNode = hit.node
                }
            case .changed:
                guard let node = selectedNode,
                      let hit = raycastBest(at: p, in: view) else { return }
                
                let t = hit.worldTransform
                var pos = SIMD3<Float>(t.columns.3.x, t.columns.3.y, t.columns.3.z)
                let n = surfaceNormal(from: t)
                let base = baseFromTransform(t)
                
                node.simdOrientation = base
                pos += n * 0.002
                node.simdPosition = pos
                
            default:
                selectedNode = nil
            }
        }
        
        // MARK: Pinch/scale
        @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let view = gesture.view as? ARSCNView else { return }
            let p0 = gesture.location(ofTouch: 0, in: view)
            let hit = view.hitTest(p0, options: nil).first
            if gesture.state == .began {
                if let node = hit?.node, node.name == "postedImage" { selectedNode = node }
            }
            
            guard let node = selectedNode else { return }
            if gesture.state == .changed {
                let s = Float(gesture.scale)
                let newScale = SCNVector3(node.scale.x * s, node.scale.y * s, node.scale.z * s)
                node.scale.x = max(minScale, min(maxScale, newScale.x))
                node.scale.y = max(minScale, min(maxScale, newScale.y))
                node.scale.z = max(minScale, min(maxScale, newScale.z))
                gesture.scale = 1
            } else if gesture.state == .ended || gesture.state == .cancelled {
                selectedNode = nil
            }
        }
        
        // MARK: Rotation not working well
        /*
        @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let view = gesture.view as? ARSCNView else { return } let p0 = gesture.location(in: view)
            let hit = view.hitTest(p0, options: nil).first
            switch gesture.state {
            case .began:
                if let node = hit?.node,let name = node.name, name.hasPrefix("postedImage_") {
                    selectedNode = node
                    startingZRotation = userZRotation
                }
            case .changed: guard let view = gesture.view as? ARSCNView, let node = selectedNode else { return }
                userZRotation = startingZRotation - Float(gesture.rotation)
            let t = node.simdTransform let n = surfaceNormal(from: t) let base = baseFromTransform(t)
                node.simdOrientation = applyTwist(base: base, normal: n, angle: userZRotation) default: selectedNode = nil }
        }*/
        
        // MARK: Long press delete
        @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let view = gesture.view as? ARSCNView else { return }
            let p = gesture.location(in: view)
            guard gesture.state == .began,
                  let hit = view.hitTest(p, options: nil).first,
                  let node = hit.node as SCNNode?,
                  node.name == "postedImage" else { return }
            
            let alert = UIAlertController(title: NSLocalizedString("Delete image?", comment: ""), message: "Remove this image from the scene.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { _ in
                node.removeFromParentNode()
                if self.placedNode === node {
                    self.placedNode = nil
                    self.focusSquare.isHidden = false
                }
            }))
            view.window?.rootViewController?.present(alert, animated: true)
        }
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            guard let view = (renderer as? ARSCNView) else { return }
            DispatchQueue.main.async { [weak self] in self?.updateFocusSquare(in: view) }
        }
        
        // MARK: updateFocusSquare
        private func updateFocusSquare(in view: ARSCNView) {
            if coachingOverlay.isActive { focusSquare.hide(); return }
            guard let camera = view.session.currentFrame?.camera, case .normal = camera.trackingState,
                  let query = view.getRaycastQuery(),
                  let result = view.castRay(for: query).first else {
                updateQueue.async {
                    self.focusSquare.state = .initializing
                    view.pointOfView?.addChildNode(self.focusSquare)
                }
                return
            }
            updateQueue.async {
                view.scene.rootNode.addChildNode(self.focusSquare)
                self.focusSquare.state = .detecting(raycastResult: result, camera: camera)
            }
        }
        
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {}
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {}
        
        // MARK: Helpers
        private func surfaceNormal(from t: simd_float4x4) -> SIMD3<Float> {
            simd_normalize(SIMD3<Float>(t.columns.1.x, t.columns.1.y, t.columns.1.z))
        }
        
        private func baseFromTransform(_ t: simd_float4x4) -> simd_quatf {
            let n = surfaceNormal(from: t)             // world-space normal
            return quatAlign(from: SIMD3<Float>(0,0,1), to: n)
        }
        
        private func quatAlign(from a: SIMD3<Float>, to b: SIMD3<Float>) -> simd_quatf {
            let v1 = simd_normalize(a), v2 = simd_normalize(b)
            let d = simd_dot(v1, v2)
            if d > 0.9999 { return simd_quatf(angle: 0, axis: SIMD3<Float>(0,1,0)) }
            if d < -0.9999 {
                let ortho: SIMD3<Float> = abs(v1.x) < 0.9 ? SIMD3<Float>(1,0,0) : SIMD3<Float>(0,1,0)
                let axis = simd_normalize(simd_cross(v1, ortho))
                return simd_quatf(angle: .pi, axis: axis)
            }
            let axis = simd_normalize(simd_cross(v1, v2))
            let angle = acos(max(-1.0, min(1.0, d)))
            return simd_quatf(angle: angle, axis: axis)
        }
        
        private func raycastBest(at pt: CGPoint, in view: ARSCNView) -> ARRaycastResult? {
            if let q = view.raycastQuery(from: pt, allowing: .existingPlaneGeometry, alignment: .any),
               let r = view.session.raycast(q).first { return r }
            if let q = view.raycastQuery(from: pt, allowing: .estimatedPlane, alignment: .any),
               let r = view.session.raycast(q).first { return r }
            return nil
        }
    }
}

extension ARSCNView {
    func castRay(for query: ARRaycastQuery) -> [ARRaycastResult] { session.raycast(query) }
    func getRaycastQuery(allowing target: ARRaycastQuery.Target = .estimatedPlane, alignment: ARRaycastQuery.TargetAlignment = .any) -> ARRaycastQuery? {
        raycastQuery(from: CGPoint(x: bounds.midX, y: bounds.midY), allowing: target, alignment: alignment)
    }
}
