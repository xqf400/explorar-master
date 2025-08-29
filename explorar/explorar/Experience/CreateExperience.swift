//
//  CreateExperience.swift
//  explorar
//
//  Created by Fabian Kuschke on 29.07.25.
//

import SwiftUI

struct CreateExperienceView: View {
    @StateObject private var arCoordinator = ARCoordinator()
    @State var placeName: String
    @State var modelName: String
    
    var body: some View {
        ZStack {
            ARViewContainer(arCoordinator: arCoordinator)
                .edgesIgnoringSafeArea(.all)
                .onDisappear {
                    arCoordinator.pauseSession()
                }
            
            VStack {
                if arCoordinator.isLoading {
                    ProgressView("Loading Scene...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }
                Spacer()
                if let tempMsg = arCoordinator.tempMessage {
                    Text(tempMsg)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .padding(12)
                        .background(Color.green.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.opacity)
                        .padding(.bottom, 40)
                }
                if !placeName.isEmpty {
                    Button("Save Experience") {
                        print("Debug: Save button tapped")
                        arCoordinator.uploadSceneToFirebase(placeName: placeName, modelName: modelName)
                    }
                    .background(Color.white)
                    .cornerRadius(30)
                    .padding()
                }
                Spacer().frame(height: 30)
                // .disabled(!arCoordinator.saveEnabled)
                
            }
        }
        .onAppear {
            print("appear \(modelName)")
            arCoordinator.name = modelName
            arCoordinator.resetScene()
            // Show prompt initially
            arCoordinator.sessionInfo = "Tap to place the object on a surface."
        }
        .navigationTitle("Place & Save")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                NavigationLink(destination: QRCodeView(url: "https://explor-ar.fun/?id=\(placeName)")) {
//                    Image(systemName: "photo.on.rectangle")
//                }
//            }
//            ToolbarItem(placement: .navigationBarTrailing) {
//                NavigationLink(destination: QRCodeView(url: "https://explorarweb-59b6c.web.app/?id=\(placeName)")) {
//                    Image(systemName: "photo.on.rectangle")
//                }
//                
//            }
        }
    }
}
