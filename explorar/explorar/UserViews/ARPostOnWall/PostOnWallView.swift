//
//  PostOnWall.swift
//  explorar
//
//  Created by Fabian Kuschke on 08.09.25.
//

import SwiftUI
import ARKit
import SceneKit

struct PostOnWallView : View {
    let image: UIImage
    
    var body: some View {
        ZStack {
            ARSCNImageViewContainer(image: image)
                .ignoresSafeArea()
            VStack {
                HStack {
                    Label("Move: drag; scale: pinch;\ndelete: long‑press", systemImage: "hand.draw")
                        .font(.footnote)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding([.top, .horizontal])
                }
                Spacer()
            }
        }
    }
}
