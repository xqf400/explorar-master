//
//  LoadingOverlay.swift
//  explorar
//
//  Created by Fabian Kuschke on 02.09.25.
//

import SwiftUI

public struct LoadingItem: Identifiable {
    public let id = UUID()
    public var name: String
    public var color: Color
    public init(name: String, color: Color) {
        self.name = name
        self.color = color
    }
}

public struct LoadingModifier: ViewModifier {
    @Binding var isPresented: Bool
    var killSwitch: Binding<Bool>? = nil
    let items: [LoadingItem]
    let baseText: String
    
    @State private var currentIndex = 0
    @State private var timer: Timer?
    
    @State private var isAnimatingOut = false
    @State private var playDisintegrate = false
    
    
    public func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented || isAnimatingOut {
                VStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.white)
                            .frame(width: 260, height: 60)
                        
                        HStack(spacing: 4) {
                            Text(baseText)
                                .minimumScaleFactor(0.5)
                                .foregroundStyle(.black)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            ZStack {
                                ForEach(items.indices, id: \.self) { index in
                                    if index == currentIndex {
                                        Text(items[index].name).bold()
                                            .foregroundStyle(items[index].color)
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .transition(
                                                .asymmetric(
                                                    insertion: .move(edge: .top)
                                                        .combined(with: .opacity)
                                                        .combined(with: .scale(scale: 0.98, anchor: .top)),
                                                    removal: .move(edge: .bottom)
                                                        .combined(with: .opacity)
                                                )
                                            )
                                            .id(index)
                                    }
                                }
                            }
                            .frame(width: 130, height: 30, alignment: .topLeading)
                            .clipped()
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .center)),
                        removal: .identity
                    ))
                    .disintegrationEffect(isDeleted: playDisintegrate) {
                        isAnimatingOut = false
                        playDisintegrate = false
                    }
                    Spacer()
                }
                .onAppear {
                    if isPresented {
                        startTimer()
                    }
                }
                .onDisappear { stopTimer() }
            }
        }// Z
        .animation(.easeInOut(duration: 0.35), value: isPresented)
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                isAnimatingOut = false
                playDisintegrate = false
                startTimer()
            } else {
                stopTimer()
                if !isAnimatingOut {
                    isAnimatingOut = true
                    DispatchQueue.main.async { playDisintegrate = true }
                }
            }
        }
        .onChange(of: killSwitch?.wrappedValue) { _, kill in
            if kill == true { hardDismiss(); DispatchQueue.main.async { killSwitch?.wrappedValue = false } }
        }
    }
    
    private func hardDismiss() {
        let time = Date.now.formatted(
            Date.FormatStyle()
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
                .second(.twoDigits)
        )
        print("\(time) Remove Hard")
        stopTimer()
        playDisintegrate = false
        isAnimatingOut = false
        currentIndex = 0
        if isPresented { isPresented = false }
    }
    
    private func startTimer() {
        stopTimer()
        guard !items.isEmpty else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex = (currentIndex+1) % items.count
            }
        }
    }
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: loadingOverlay
public extension View {
    func loadingOverlay(
        isPresented: Binding<Bool>,
        items: [LoadingItem] = [
            LoadingItem(name: NSLocalizedString("texts", comment: ""), color: .green),
            LoadingItem(name: NSLocalizedString("images", comment: ""), color: .yellow),
            LoadingItem(name: NSLocalizedString("challenge", comment: ""), color: .blue)
        ],
        baseText: String = NSLocalizedString("Loading", comment: ""),
        killSwitch: Binding<Bool>? = nil,
    ) -> some View {
        modifier(LoadingModifier(
            isPresented: isPresented, killSwitch: killSwitch,
            items: items,
            baseText: baseText
        ))
    }
}

// Thanks to Balaji Venkatesh
extension View {
    @ViewBuilder
    func disintegrationEffect(isDeleted: Bool, completion: @escaping () -> ()) -> some View {
        self
            .modifier(DisintegrationEffectModifier(isDeleted: isDeleted, completion: completion))
    }
}

fileprivate struct DisintegrationEffectModifier: ViewModifier {
    var isDeleted: Bool
    var completion: () -> ()
    @State private var particles: [SnapParticle] = []
    @State private var animateEffect: Bool = false
    @State private var triggerSnapshot: Bool = false
    @State private var isDeleteCompleted: Bool = false
    func body(content: Content) -> some View {
        content
            .opacity(particles.isEmpty && !isDeleteCompleted ? 1 : 0)
            .overlay(alignment: .topLeading) {
                DisintegrationEffectView(particles: $particles, animateEffect: $animateEffect)
            }
            .snapshot(trigger: triggerSnapshot) { snapshot in
                Task.detached(priority: .high) {
                    try? await Task.sleep(for: .seconds(0))
                    await createParticles(snapshot)
                }
            }
            .onChange(of: isDeleted) { oldValue, newValue in
                if newValue && particles.isEmpty {
                    triggerSnapshot = true
                }
            }
    }
    
    private func createParticles(_ snapshot: UIImage) async {
        var particles: [SnapParticle] = []
        let size = snapshot.size
        let width = size.width
        let height = size.height
        let maxGridCount: Int = 1100
        
        var gridSize: Int = 1
        var rows = Int(height) / gridSize
        var columns = Int(width) / gridSize
        
        while (rows * columns) >= maxGridCount {
            gridSize += 1
            rows = Int(height) / gridSize
            columns = Int(width) / gridSize
        }
                
        for row in 0...rows {
            for column in 0...columns {
                let positionX = column * gridSize
                let positionY = row * gridSize
                
                let cropRect = CGRect(x: positionX, y: positionY, width: gridSize, height: gridSize)
                let croppedImage = cropImage(snapshot, rect: cropRect)
                particles.append(.init(
                    particleImage: croppedImage,
                    particleOffset: .init(width: positionX, height: positionY)
                ))
            }
        }
        
        await MainActor.run { [particles] in
            self.particles = particles
            withAnimation(.easeInOut(duration: 1.5), completionCriteria: .logicallyComplete) {
                animateEffect = true
            } completion: {
                isDeleteCompleted = true
                self.particles = []
                completion()
            }
        }
    }
    
    private func cropImage(_ snapshot: UIImage, rect: CGRect) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)
        return renderer.image { ctx in
            ctx.cgContext.interpolationQuality = .low
            snapshot.draw(at: .init(x: -rect.origin.x, y: -rect.origin.y))
        }
    }
}

fileprivate struct DisintegrationEffectView: View {
    @Binding var particles: [SnapParticle]
    @Binding var animateEffect: Bool
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(particles) { particle in
                Image(uiImage: particle.particleImage)
                    .offset(particle.particleOffset)
                    .offset(
                        x: animateEffect ? .random(in: -60...(-10)) : 0,
                        y: animateEffect ? .random(in: -100...(-10)) : 0
                    )
                    .opacity(animateEffect ? 0 : 1)
            }
        }
        .compositingGroup()
        .blur(radius: animateEffect ? 5 : 0)
    }
}

fileprivate struct SnapParticle: Identifiable {
    var id: String = UUID().uuidString
    var particleImage: UIImage
    var particleOffset: CGSize
}

extension View {
    @ViewBuilder
    func snapshot(trigger: Bool, onComplete: @escaping (UIImage) -> ()) -> some View {
        self
            .modifier(SnaphotModifier(trigger: trigger, onComplete: onComplete))
    }
}

fileprivate struct SnaphotModifier: ViewModifier {
    var trigger: Bool
    var onComplete: (UIImage) -> ()
    @State private var view: UIView = .init(frame: .zero)
    
    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content
                .background(ViewExtractor(view: view))
                .compositingGroup()
                .onChange(of: trigger) { oldValue, newValue in
                    generateSnapshot()
                }
        } else {
            content
                .background(ViewExtractor(view: view))
                .compositingGroup()
                .onChange(of: trigger) { newValue in
                    generateSnapshot()
                }
        }
    }
    
    private func generateSnapshot() {
        if let superView = view.superview?.superview {
            let renderer = UIGraphicsImageRenderer(size: superView.bounds.size)
            let image = renderer.image { _ in
                superView.drawHierarchy(in: superView.bounds, afterScreenUpdates: true)
            }
            
            onComplete(image)
        }
    }
}

fileprivate struct ViewExtractor: UIViewRepresentable {
    var view: UIView
    func makeUIView(context: Context) -> UIView {
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}

