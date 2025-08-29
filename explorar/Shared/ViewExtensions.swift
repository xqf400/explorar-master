//
//  ViewExtensions.swift
//  explorar
//
//  Created by Fabian Kuschke on 06.08.25.
//

import SwiftUI
extension View {
    // MARK: Placeholder Textfield
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
            
            ZStack(alignment: alignment) {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
    func cardStyle(color: Color, opacity: Double = 0.8, paddingHorizontal: CGFloat = 16) -> some View {
        self
            .padding(.horizontal, paddingHorizontal)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(opacity))
                    .shadow(radius: 4, y: 2)
            )
    }
    
    @ViewBuilder
    func shine(toggle: Bool, duration: Double, clipShape: some Shape = .capsule) -> some View {
        if #available(iOS 17.0, *) {
            self
                .overlay {
                    GeometryReader {
                        let size = $0.size
                        Rectangle()
                            .fill(.linearGradient(
                                colors: [
                                    .clear,
                                    .clear,
                                    .white.opacity(0.1),
                                    .white.opacity(0.3),
                                    .white.opacity(0.5),
                                    .white.opacity(1),
                                    .white.opacity(0.5),
                                    .white.opacity(0.3),
                                    .white.opacity(0.1),
                                    .clear,
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .scaleEffect(y: 8)
                            .keyframeAnimator(initialValue: 0, trigger: toggle, content: { content, progress in
                                content
                                    .offset(x: -size.width + (progress * (size.width * 2)))
                            }, keyframes: { _ in
                                CubicKeyframe(.zero, duration: 0.1)
                                CubicKeyframe(1, duration: max(0.3, duration))
                            })
                            .rotationEffect(.init(degrees: 45))
                            .scaleEffect(x: 1)
                    }
                }
                .clipShape(clipShape)
                .contentShape(clipShape)
        } else {
            self
        }
    }
}
