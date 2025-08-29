//
//  FocusScqaure1.swift
//  explorar
//
//  Created by Fabian Kuschke on 08.09.25.
//

import SceneKit
import ARKit

// MARK: - FocusSquare
final class FocusSquare1: SCNNode {
    enum State: Equatable { case initializing, detecting(raycastResult: ARRaycastResult, camera: ARCamera?) }
    static let size: Float = 0.17
    static let thickness: Float = 0.018
    static let scaleForClosedSquare: Float = 0.97
    static let sideLengthForOpenSegments: CGFloat = 0.2
    static let animationDuration = 0.7
    static let primaryColor = UIColor(red: 1, green: 0.8, blue: 0, alpha: 1)
    static let fillColor = UIColor(red: 1, green: 0.92549, blue: 0.41176, alpha: 1)

    var state: State = .initializing { didSet { guard state != oldValue else { return }; switch state {
        case .initializing: displayAsBillboard()
        case let .detecting(r, camera): if let plane = r.anchor as? ARPlaneAnchor { displayAsClosed(for: r, planeAnchor: plane, camera: camera) } else { displayAsOpen(for: r, camera: camera) }
    }}}

    private var isOpen = false
    private var isAnimating = false
    private var isChangingOrientation = false
    private var isPointingDownwards = true
    private var recentPositions: [SIMD3<Float>] = []
    private var visitedPlanes: Set<ARAnchor> = []

    private var segments: [Segment] = []
    private let positioningNode = SCNNode()
    private var counterToNextOrientationUpdate = 0

    override init() {
        super.init(); opacity = 0
        let s1 = Segment(name: "s1", corner: .topLeft, alignment: .horizontal)
        let s2 = Segment(name: "s2", corner: .topRight, alignment: .horizontal)
        let s3 = Segment(name: "s3", corner: .topLeft, alignment: .vertical)
        let s4 = Segment(name: "s4", corner: .topRight, alignment: .vertical)
        let s5 = Segment(name: "s5", corner: .bottomLeft, alignment: .vertical)
        let s6 = Segment(name: "s6", corner: .bottomRight, alignment: .vertical)
        let s7 = Segment(name: "s7", corner: .bottomLeft, alignment: .horizontal)
        let s8 = Segment(name: "s8", corner: .bottomRight, alignment: .horizontal)
        segments = [s1,s2,s3,s4,s5,s6,s7,s8]

        let sl: Float = 0.5
        let c: Float = FocusSquare1.thickness / 2
        s1.simdPosition += [-(sl / 2 - c), -(sl - c), 0]
        s2.simdPosition += [sl / 2 - c, -(sl - c), 0]
        s3.simdPosition += [-sl, -sl / 2, 0]
        s4.simdPosition += [sl, -sl / 2, 0]
        s5.simdPosition += [-sl, sl / 2, 0]
        s6.simdPosition += [sl, sl / 2, 0]
        s7.simdPosition += [-(sl / 2 - c), sl - c, 0]
        s8.simdPosition += [sl / 2 - c, sl - c, 0]

        positioningNode.eulerAngles.x = .pi / 2
        positioningNode.simdScale = [1,1,1] * (FocusSquare1.size * FocusSquare1.scaleForClosedSquare)
        for s in segments { positioningNode.addChildNode(s) }
        positioningNode.addChildNode(fillPlane)
        displayNodeHierarchyOnTop(true)
        addChildNode(positioningNode)
        displayAsBillboard()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func hide() { guard action(forKey: "hide") == nil else { return }; displayNodeHierarchyOnTop(false); runAction(.fadeOut(duration: 0.5), forKey: "hide") }
    func unhide() { guard action(forKey: "unhide") == nil else { return }; displayNodeHierarchyOnTop(true); runAction(.fadeIn(duration: 0.5), forKey: "unhide") }

    private func displayAsBillboard() { simdTransform = matrix_identity_float4x4; eulerAngles.x = .pi/2; simdPosition = [0,0,-0.8]; unhide(); performOpenAnimation() }
    private func displayAsOpen(for r: ARRaycastResult, camera: ARCamera?) { performOpenAnimation(); setPosition(with: r, camera) }
    private func displayAsClosed(for r: ARRaycastResult, planeAnchor: ARPlaneAnchor, camera: ARCamera?) { performCloseAnimation(flash: !visitedPlanes.contains(planeAnchor)); visitedPlanes.insert(planeAnchor); setPosition(with: r, camera) }

    private func setPosition(with r: ARRaycastResult, _ camera: ARCamera?) { let pos = r.worldTransform.translation1; recentPositions.append(pos); updateTransform(for: r, camera: camera) }

    private func updateTransform(for r: ARRaycastResult, camera: ARCamera?) {
        recentPositions = Array(recentPositions.suffix(10))
        let avg = recentPositions.reduce([0,0,0], +) / Float(max(1, recentPositions.count))
        self.simdPosition = avg
        self.simdScale = [1,1,1] * scaleBasedOnDistance(camera: camera)
        guard let camera = camera else { return }
        let tilt = abs(camera.eulerAngles.x)
        let threshold: Float = .pi/2 * 0.75
        if tilt > threshold {
            if !isChangingOrientation {
                let yaw = atan2f(camera.transform.columns.0.x, camera.transform.columns.1.x)
                isChangingOrientation = true
                SCNTransaction.begin(); SCNTransaction.completionBlock = { self.isChangingOrientation = false; self.isPointingDownwards = true }
                SCNTransaction.animationDuration = isPointingDownwards ? 0.0 : 0.5
                self.simdOrientation = simd_quatf(angle: yaw, axis: [0,1,0])
                SCNTransaction.commit()
            }
        } else {
            if counterToNextOrientationUpdate == 30 || isPointingDownwards { counterToNextOrientationUpdate = 0; isPointingDownwards = false; SCNTransaction.begin(); SCNTransaction.animationDuration = 0.5; self.simdOrientation = r.worldTransform.orientation; SCNTransaction.commit() }
            counterToNextOrientationUpdate += 1
        }
    }

    private func scaleBasedOnDistance(camera: ARCamera?) -> Float {
        guard let camera = camera else { return 1 }
        let d = simd_length(simdWorldPosition - camera.transform.translation1)
        return d < 0.7 ? d/0.7 : 0.25 * d + 0.825
    }

    private func performOpenAnimation() {
        guard !isOpen, !isAnimating else { return }; isOpen = true; isAnimating = true
        SCNTransaction.begin(); SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut); SCNTransaction.animationDuration = FocusSquare1.animationDuration/4
        positioningNode.opacity = 1
        segments.forEach { $0.open() }
        SCNTransaction.completionBlock = { self.positioningNode.runAction(pulseAction(), forKey: "pulse"); self.isAnimating = false }
        SCNTransaction.commit()
        SCNTransaction.begin(); SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut); SCNTransaction.animationDuration = FocusSquare1.animationDuration/4
        positioningNode.simdScale = [1,1,1] * FocusSquare1.size
        SCNTransaction.commit()
    }

    private func performCloseAnimation(flash: Bool = false) {
        guard isOpen, !isAnimating else { return }; isOpen = false; isAnimating = true
        positioningNode.removeAction(forKey: "pulse"); positioningNode.opacity = 1
        SCNTransaction.begin(); SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut); SCNTransaction.animationDuration = FocusSquare1.animationDuration/2
        positioningNode.opacity = 0.99
        SCNTransaction.completionBlock = {
            SCNTransaction.begin(); SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut); SCNTransaction.animationDuration = FocusSquare1.animationDuration/4
            self.segments.forEach { $0.close() }
            SCNTransaction.completionBlock = { self.isAnimating = false }
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
        positioningNode.addAnimation(scaleAnimation(for: "transform.scale.x"), forKey: "transform.scale.x")
        positioningNode.addAnimation(scaleAnimation(for: "transform.scale.y"), forKey: "transform.scale.y")
        positioningNode.addAnimation(scaleAnimation(for: "transform.scale.z"), forKey: "transform.scale.z")
        if flash {
            let wait = SCNAction.wait(duration: FocusSquare1.animationDuration * 0.75)
            let fadeIn = SCNAction.fadeOpacity(to: 0.25, duration: FocusSquare1.animationDuration * 0.125)
            let fadeOut = SCNAction.fadeOpacity(to: 0.0, duration: FocusSquare1.animationDuration * 0.125)
            fillPlane.runAction(.sequence([wait, fadeIn, fadeOut]))
            let flashAct = flashAnimation(duration: FocusSquare1.animationDuration * 0.25)
            segments.forEach { $0.runAction(.sequence([wait, flashAct])) }
        }
    }

    private func scaleAnimation(for keyPath: String) -> CAKeyframeAnimation {
        let a = CAKeyframeAnimation(keyPath: keyPath)
        let easeOut = CAMediaTimingFunction(name: .easeOut)
        let easeInOut = CAMediaTimingFunction(name: .easeInEaseOut)
        let linear = CAMediaTimingFunction(name: .linear)
        let size = FocusSquare1.size
        let ts = FocusSquare1.size * FocusSquare1.scaleForClosedSquare
        a.values = [size, size * 1.15, size * 1.15, ts * 0.97, ts]
        a.keyTimes = [0, 0.25, 0.5, 0.75, 1]
        a.timingFunctions = [easeOut, linear, easeOut, easeInOut]
        a.duration = FocusSquare1.animationDuration
        return a
    }

    func displayNodeHierarchyOnTop(_ onTop: Bool) {
        func update(_ n: SCNNode) {
            n.renderingOrder = onTop ? 2 : 0
            for m in n.geometry?.materials ?? [] { m.readsFromDepthBuffer = !onTop }
            for c in n.childNodes { update(c) }
        }
        update(positioningNode)
    }

    private lazy var fillPlane: SCNNode = {
        let corr = FocusSquare1.thickness / 2
        let length = CGFloat(1 - FocusSquare1.thickness * 2 + corr)
        let plane = SCNPlane(width: length, height: length)
        let node = SCNNode(geometry: plane)
        node.name = "fillPlane"; node.opacity = 0
        let mat = plane.firstMaterial!
        mat.diffuse.contents = FocusSquare1.fillColor
        mat.isDoubleSided = true
        mat.ambient.contents = UIColor.black
        mat.lightingModel = .constant
        mat.emission.contents = FocusSquare1.fillColor
        return node
    }()

    // MARK: Segment
    enum Corner { case topLeft, topRight, bottomRight, bottomLeft }
    enum Alignment { case horizontal, vertical }
    final class Segment: SCNNode {
        static let thickness: CGFloat = 0.018
        static let length: CGFloat = 0.5
        static let openLength: CGFloat = 0.2
        let corner: Corner; let alignment: Alignment; let plane: SCNPlane
        init(name: String, corner: Corner, alignment: Alignment) {
            self.corner = corner; self.alignment = alignment
            plane = alignment == .vertical ? SCNPlane(width: Segment.thickness, height: Segment.length) : SCNPlane(width: Segment.length, height: Segment.thickness)
            super.init(); self.name = name
            let m = plane.firstMaterial!; m.diffuse.contents = FocusSquare1.primaryColor; m.isDoubleSided = true; m.ambient.contents = UIColor.black; m.lightingModel = .constant; m.emission.contents = FocusSquare1.primaryColor
            geometry = plane
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        var openDirection: Direction { switch (corner, alignment) {
            case (.topLeft, .horizontal): return .left
            case (.topLeft, .vertical): return .up
            case (.topRight, .horizontal): return .right
            case (.topRight, .vertical): return .up
            case (.bottomLeft, .horizontal): return .left
            case (.bottomLeft, .vertical): return .down
            case (.bottomRight, .horizontal): return .right
            case (.bottomRight, .vertical): return .down } }
        func open() { if alignment == .horizontal { plane.width = Segment.openLength } else { plane.height = Segment.openLength }; let off = Segment.length/2 - Segment.openLength/2; updatePosition(withOffset: Float(off), for: openDirection) }
        func close() { let old: CGFloat = (alignment == .horizontal ? plane.width : plane.height); if alignment == .horizontal { plane.width = Segment.length } else { plane.height = Segment.length }; let off = Segment.length/2 - old/2; updatePosition(withOffset: Float(off), for: openDirection.reversed) }
        private func updatePosition(withOffset o: Float, for d: Direction) { switch d { case .left: position.x -= o; case .right: position.x += o; case .up: position.y -= o; case .down: position.y += o } }
    }
    enum Direction { case up, down, left, right; var reversed: Direction { switch self { case .up: return .down; case .down: return .up; case .left: return .right; case .right: return .left } } }
}

// MARK: animations
fileprivate func pulseAction() -> SCNAction {
    let out = SCNAction.fadeOpacity(to: 0.4, duration: 0.5)
    let `in` = SCNAction.fadeOpacity(to: 1.0, duration: 0.5)
    out.timingMode = .easeInEaseOut; `in`.timingMode = .easeInEaseOut
    return .repeatForever(.sequence([out, `in`]))
}

fileprivate func flashAnimation(duration: TimeInterval) -> SCNAction {
    SCNAction.customAction(duration: duration) { node, elapsed in
        let p = elapsed / CGFloat(duration)
        let saturation = 2.8 * (p - 0.5) * (p - 0.5) + 0.3
        if let m = node.geometry?.firstMaterial { m.diffuse.contents = UIColor(hue: 0.1333, saturation: saturation, brightness: 1.0, alpha: 1.0) }
    }
}

extension float4x4 {
    var translation1: SIMD3<Float> { [columns.3.x, columns.3.y, columns.3.z] }
    var orientation: simd_quatf { simd_quaternion(self) }
}
