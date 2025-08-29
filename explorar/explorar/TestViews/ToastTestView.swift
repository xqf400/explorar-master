//
//  ToastTestView.swift
//  explorar
//
//  Created by Fabian Kuschke on 07.08.25.
//

import SwiftUI

struct ToastTestView: View {
    //@State private var toasts: [Toast] = []
    var body: some View {
        VStack {
            Button("HUD") {
                withAnimation(.bouncy) {
//                    toasts.append(.init { id in
//                        HUDView(text: "Yeah!")
//                    })
                }
            }
        }
        //.interactiveToasts($toasts)
    }
}

#Preview {
    ToastTestView()
}
