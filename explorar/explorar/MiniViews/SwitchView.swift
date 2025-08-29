//
//  SwitchView.swift
//  explorar
//
//  Created by Fabian Kuschke on 06.08.25.
//

import SwiftUI

// MARK: Selections
enum TabSelections: String, CaseIterable {
    case list = "List"
    case map = "Map"
    
    var systemImage: String {
        switch self {
        case .list:
            return "list.bullet.circle"
        case .map:
            return "map.circle"
        }
    }
    var localized: String {
        NSLocalizedString(self.rawValue, comment: "")
    }
}

struct SwitchView: View {
    @Binding var currentIndex: CGFloat
    @Environment(\.colorScheme) private var scheme
    
    init(_ currentIndex: Binding<CGFloat>) {
        self._currentIndex = currentIndex
        UISegmentedControl.appearance().selectedSegmentTintColor = .systemGreen
        UISegmentedControl.appearance().backgroundColor =
        UIColor(Color.clear)
    }
    
    var body: some View {
        HStack {
            Spacer(minLength: 30)
            customSegmentedPicker()
                .frame(height: 10)
            
            Spacer(minLength: 30)
        }
    }
    
    
    @ViewBuilder
    func customSegmentedPicker() -> some View {
        HStack(spacing: 0) {
            ForEach(Array(TabSelections.allCases.enumerated()), id: \.1.rawValue) { index, selection in
                HStack(spacing: 8) {
                    Image(systemName: selection.systemImage)
                    
                    Text(selection.localized)
                        .font(.callout)
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                        .foregroundStyle(Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .contentShape(.capsule)
                .onTapGesture {
                    withAnimation(.snappy) {
                        currentIndex = CGFloat(index)
                    }
                }
            }
        }
        .tabMask(currentIndex)
        // Scrollable Active Tab Indicator
        .background {
            GeometryReader {
                let size = $0.size
                let capusleWidth = size.width / CGFloat(TabSelections.allCases.count)
                
                Capsule()
                    .fill(
                        withAnimation {
                            currentIndex == 0 ? allRadientGreenBlue : allRadientBlueGreen
                        }
                    )
                    .frame(width: capusleWidth)
                    .offset(x: currentIndex * (size.width - capusleWidth))
            }
        }
        .background(.black.opacity(0.3), in: .capsule)
        .padding(.horizontal, 16)
    }
}
extension View {
    @ViewBuilder
    func tabMask(_ tabIndex: CGFloat) -> some View {
        ZStack {
            self
                .foregroundStyle(.white.opacity(0.6))
            
            self
                .symbolVariant(.fill)
                .mask {
                    GeometryReader {
                        let size = $0.size
                        let width = size.width / CGFloat(TabSelections.allCases.count)
                        
                        Capsule()
                            .frame(width: width)
                            .offset(x: tabIndex * (size.width - width))
                    }
                }
        }
    }
}
