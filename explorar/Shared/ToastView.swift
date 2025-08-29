//
//  ToastView.swift
//  explorar
//
//  Created by Fabian Kuschke on 07.08.25.
//
/*
import SwiftUI

@ViewBuilder
func HUDView(text: String) -> some View {
    HStack(spacing: 12) {
        Image(systemName: "heart")
        
        Text(text)
            .font(.callout)
    }
    .foregroundStyle(Color.primary)
    .padding(.vertical, 12)
    .padding(.horizontal, 15)
    .background {
        Capsule()
            .fill(.background)
            .shadow(color: .black.opacity(0.06), radius: 3, x: -1, y: -3)
            .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 3)
    }
}

struct Toast: Identifiable {
    private(set) var id: String = UUID().uuidString
    var content: AnyView
    
    init(@ViewBuilder content: @escaping (String) -> some View) {
        self.content = .init(content(id))
    }
    
    var offsetX: CGFloat = 0
    var isDeleting: Bool = false
}

extension View {
    @ViewBuilder
    func interactiveToasts(_ toasts: Binding<[Toast]>) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                ToastsView(toasts: toasts)
            }
    }
}

fileprivate struct ToastsView: View {
    @Binding var toasts: [Toast]
    @State private var isExpanded: Bool = false
    var body: some View {
        ZStack(alignment: .top) {
            if isExpanded {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isExpanded = false
                    }
            }
            
            let layout = isExpanded ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(ZStackLayout())
            
            layout {
                ForEach($toasts) { $toast in
                    let index = (toasts.count - 1) - (toasts.firstIndex(where: { $0.id == toast.id }) ?? 0)
                    
                    toast.content
                        .offset(x: toast.offsetX)
                        .onAppear {
                            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                                $toasts.delete(toast.id)
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let xOffset = value.translation.width < 0 ? value.translation.width : 0
                                    toast.offsetX = xOffset
                                }.onEnded { value in
                                    let xOffset = value.translation.width + (value.velocity.width / 2)
                                    
                                    if -xOffset > 200 {
                                        $toasts.delete(toast.id)
                                    } else {
                                        withAnimation(.bouncy) {
                                            toast.offsetX = 0
                                        }
                                    }
                                }
                        )
                        .visualEffect { [isExpanded] content, proxy in
                            content
                                .scaleEffect(isExpanded ? 1 : scale(index), anchor: .top)
                                .offset(y: isExpanded ? 0 : offsetY(index))
                        }
                        .zIndex(toast.isDeleting ? 1000 : 0)
                        .frame(maxWidth: .infinity)
                        .transition(.asymmetric(insertion: .offset(y: -150), removal: .move(edge: .leading)))
                }
            }
            .onTapGesture {
                isExpanded.toggle()
            }
            .padding(.top, 15)
        }
        .animation(.bouncy, value: isExpanded)
        .onChange(of: toasts.isEmpty) { oldValue, newValue in
            if newValue {
                isExpanded = false
            }
        }
    }
    
    nonisolated func offsetY(_ index: Int) -> CGFloat {
        let offset = min(CGFloat(index) * 15, 30)
        
        return offset
    }
    
    nonisolated func scale(_ index: Int) -> CGFloat {
        let scale = min(CGFloat(index) * 0.1, 1)
        
        return 1 - scale
    }
}

extension Binding<[Toast]> {
    func delete(_ id: String) {
        if let toast = first(where: { $0.id == id }) {
            toast.wrappedValue.isDeleting = true
        }
        
        withAnimation(.bouncy) {
            self.wrappedValue.removeAll(where: { $0.id == id })
        }
    }
}
*/
