//
//  DetailImageView.swift
//  explorar
//
//  Created by Fabian Kuschke on 10.08.25.
//

import SwiftUI

struct DetailImage: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var image: UIImage?
    var previewImage: UIImage?
    var appeared: Bool = false
}
struct HeroKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String : Anchor<CGRect>], nextValue: () -> [String : Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

struct Detail: View {
    @Environment(UICoordinator.self) private var coordinator
    @State private var isZooming = false
    
    private func isKi (name:String) -> Bool{
        if name.contains("1920") || name.contains("2120") {
            return true
        }
        return false
    }
    var body: some View {
        VStack(spacing: 0) {
            NavigationBar()
            GeometryReader {
                let size = $0.size
                
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(coordinator.items) { item in
                            if let image = item.image {
                                ZoomableImageView(image: image, size: size, isKI: isKi(name: item.title), isZoomingAnyItem: $isZooming)
                                    .frame(width: size.width, height: size.height) // important for paging
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .scrollPosition(id: .init(get: {
                    return coordinator.detailScrollPosition
                }, set: {
                    coordinator.detailScrollPosition = $0
                }))
                .scrollDisabled(isZooming)
                .onChange(of: coordinator.detailScrollPosition, { oldValue, newValue in
                    coordinator.didDetailPageChanged()
                })
                .background {
                    if let selectedItem = coordinator.selectedItem {
                        Rectangle()
                            .fill(.clear)
                            .anchorPreference(key: HeroKey.self, value: .bounds, transform: { anchor in
                                return [selectedItem.id + "DEST": anchor]
                            })
                    }
                }
                .offset(coordinator.offset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            guard !isZooming else { return }
                            guard abs(value.translation.height) > abs(value.translation.width),
                                  value.translation.height > 0 else { return }
                            
                            coordinator.offset = value.translation
                            coordinator.dragProgress = max(min(value.translation.height / 200, 1), 0)
                        }
                        .onEnded { value in
                            guard !isZooming else { return }
                            guard abs(value.translation.height) > abs(value.translation.width),
                                  value.translation.height > 0 else { return }
                            
                            let height = value.translation.height + (value.velocity.height / 5)
                            if height > size.height * 0.25 {
                                coordinator.toggleView(show: false)
                            } else {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    coordinator.offset = .zero
                                    coordinator.dragProgress = 0
                                }
                            }                        }
                )
                
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(width: 10)
                    .allowsHitTesting(!isZooming)
                    .contentShape(.rect)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let translation = value.translation
                                coordinator.offset = translation
                                let heightProgress = max(min(translation.height / 200, 1), 0)
                                coordinator.dragProgress = heightProgress
                            }.onEnded { value in
                                let translation = value.translation
                                let velocity = value.velocity
                                let height = translation.height + (velocity.height / 5)
                                
                                if height > (size.height * 0.5) {
                                    coordinator.toggleView(show: false)
                                } else {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        coordinator.offset = .zero
                                        coordinator.dragProgress = 0
                                    }
                                }
                            }
                    )
            }
            .opacity(coordinator.showDetailView ? 1 : 0)
            
            BottomIndicatorView()
                .offset(y: coordinator.showDetailView ? (120 * coordinator.dragProgress) : 120)
                .animation(.easeInOut(duration: 0.15), value: coordinator.showDetailView)
        }
        .onAppear {
            coordinator.toggleView(show: true)
        }
    }
    
    @ViewBuilder
    func NavigationBar() -> some View {
        HStack {
            Spacer(minLength: 0)
            Button(action: { coordinator.toggleView(show: false) }, label: {
                HStack(spacing: 2) {
                    Image(systemName: "x.circle")
                        .font(.title3)
                        .foregroundStyle(Color.white)
                }
            })
        }
        .padding([.top, .horizontal], 15)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .offset(y: coordinator.showDetailView ? (-120 * coordinator.dragProgress) : -120)
        .animation(.easeInOut(duration: 0.15), value: coordinator.showDetailView)
    }
    
    // Bottom Indicator View
    @ViewBuilder
    func BottomIndicatorView() -> some View {
        GeometryReader {
            let size = $0.size
            
            ScrollView(.horizontal) {
                LazyHStack(spacing: 5) {
                    ForEach(coordinator.items) { item in
                        /// Preview Image View
                        if let image = item.previewImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(.rect(cornerRadius: 10))
                                .scaleEffect(0.97)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        coordinator.detailIndicatorPosition = item.id
                                        coordinator.detailScrollPosition = item.id
                                    }
                                }
                        }
                    }
                }
                .padding(.vertical, 10)
                .scrollTargetLayout()
            }
            /// 50 - Item Size Inside ScrollView
            .safeAreaPadding(.horizontal, (size.width - 50) / 2)
            .overlay {
                /// Active Indicator Icon
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary, lineWidth: 2)
                    .frame(width: 50, height: 50)
                    .allowsHitTesting(false)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: .init(get: {
                return coordinator.detailIndicatorPosition
            }, set: {
                coordinator.detailIndicatorPosition = $0
            }))
            .scrollIndicators(.hidden)
            .onChange(of: coordinator.detailIndicatorPosition) { oldValue, newValue in
                coordinator.didDetailIndicatorPageChanged()
            }
        }
        .frame(height: 70)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}


@Observable
class UICoordinator {
    var items: [DetailImage] = []
    
    var selectedItem: DetailImage?
    var animateView: Bool = false
    var showDetailView: Bool = false
    
    var detailScrollPosition: String?
    var detailIndicatorPosition: String?
    
    var offset: CGSize = .zero
    var dragProgress: CGFloat = 0
    
    init(sampleItems: [DetailImage]) {
        items = sampleItems.compactMap({
            DetailImage(title: $0.title, image: $0.image, previewImage: $0.previewImage)
        })
    }
    
    func didDetailPageChanged() {
        if let updatedItem = items.first(where: { $0.id == detailScrollPosition }) {
            selectedItem = updatedItem
            withAnimation(.easeInOut(duration: 0.1)) {
                detailIndicatorPosition = updatedItem.id
            }
        }
    }
    
    func didDetailIndicatorPageChanged() {
        if let updatedItem = items.first(where: { $0.id == detailIndicatorPosition }) {
            selectedItem = updatedItem
            detailScrollPosition = updatedItem.id
        }
    }
    
    func toggleView(show: Bool) {
        if show {
            detailScrollPosition = selectedItem?.id
            detailIndicatorPosition = selectedItem?.id
            withAnimation(.easeInOut(duration: 0.2), completionCriteria: .removed) {
                animateView = true
            } completion: {
                self.showDetailView = true
            }
        } else {
            showDetailView = false
            withAnimation(.easeInOut(duration: 0.2), completionCriteria: .removed) {
                animateView = false
                offset = .zero
            } completion: {
                self.resetAnimationProperties()
            }
        }
    }
    
    func resetAnimationProperties() {
        selectedItem = nil
        detailScrollPosition = nil
        offset = .zero
        dragProgress = 0
        detailIndicatorPosition = nil
    }
}


extension View {
    @ViewBuilder
    func didFrameChange(result: @escaping (CGRect, CGRect) -> ()) -> some View {
        self
            .overlay {
                GeometryReader {
                    let frame = $0.frame(in: .scrollView(axis: .vertical))
                    let bounds = $0.bounds(of: .scrollView(axis: .vertical)) ?? .zero
                    
                    Color.clear
                        .preference(key: FrameKey.self, value: .init(frame: frame, bounds: bounds))
                        .onPreferenceChange(FrameKey.self, perform: { value in
                            result(value.frame, value.bounds)
                        })
                }
            }
    }
}

struct ViewFrame: Equatable {
    var frame: CGRect = .zero
    var bounds: CGRect = .zero
}

struct FrameKey: PreferenceKey {
    static var defaultValue: ViewFrame = .init()
    static func reduce(value: inout ViewFrame, nextValue: () -> ViewFrame) {
        value = nextValue()
    }
}



struct ZoomableImageView: View {
    let image: UIImage
    let size: CGSize
    let isKI: Bool
    @Binding var isZoomingAnyItem: Bool
    
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 12
    
    var body: some View {
        let baseFitted = fittedSize(container: size, image: image.size)
        
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size.width, height: size.height)
            .scaleEffect(scale)
            .offset(offset)
            .clipped()
            .contentShape(Rectangle())
            .overlay(alignment: .topTrailing) {
                if isKI {
                    Text("KI")
                        .font(.caption2)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(6)
                }
            }
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScale
                        scale = min(max(scale * delta, minScale), maxScale)
                        lastScale = value
                        isZoomingAnyItem = (scale > 1.001)
                        
                        let m = maxOffsets(container: size, baseFitted: baseFitted, scale: scale)
                        offset = clamped(offset, maxX: m.x, maxY: m.y)
                    }
                    .onEnded { _ in
                        lastScale = 1
                        withAnimation(.spring()) {
                            if scale <= minScale {
                                scale = minScale
                                offset = .zero
                                lastOffset = .zero
                                isZoomingAnyItem = false
                            } else {
                                let m = maxOffsets(container: size, baseFitted: baseFitted, scale: scale)
                                offset = clamped(offset, maxX: m.x, maxY: m.y)
                                lastOffset = offset
                            }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        guard scale > 1 else { return } // only pan when zoomed
                        let proposed = CGSize(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                        let m = maxOffsets(container: size, baseFitted: baseFitted, scale: scale)
                        offset = clamped(proposed, maxX: m.x, maxY: m.y)
                    }
                    .onEnded { _ in
                        guard scale > 1 else { return }
                        lastOffset = offset
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    if scale > 1 {
                        scale = 1
                        offset = .zero
                        lastOffset = .zero
                        isZoomingAnyItem = false
                    } else {
                        scale = 4
                        let m = maxOffsets(container: size, baseFitted: baseFitted, scale: 4)
                        offset = clamped(offset, maxX: m.x, maxY: m.y)
                        lastOffset = offset
                        isZoomingAnyItem = true
                    }
                }
            }
    }
    
    private func fittedSize(container: CGSize, image: CGSize) -> CGSize {
        guard image.width > 0, image.height > 0 else { return container }
        let s = min(container.width / image.width, container.height / image.height)
        return CGSize(width: image.width * s, height: image.height * s)
    }
    private func maxOffsets(container: CGSize, baseFitted: CGSize, scale: CGFloat) -> (x: CGFloat, y: CGFloat) {
        let scaled = CGSize(width: baseFitted.width * scale, height: baseFitted.height * scale)
        let maxX = max(0, (scaled.width - container.width) / 2)
        let maxY = max(0, (scaled.height - container.height) / 2)
        return (maxX, maxY)
    }
    private func clamped(_ o: CGSize, maxX: CGFloat, maxY: CGFloat) -> CGSize {
        CGSize(width: min(max(o.width, -maxX), maxX), height: min(max(o.height, -maxY), maxY))
    }
}

