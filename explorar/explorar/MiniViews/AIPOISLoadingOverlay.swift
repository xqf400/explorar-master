//
//  AIPOISLoadingOverlay.swift
//  explorar
//
//  Created by Fabian Kuschke on 17.08.25.
//
import SwiftUI

struct AIPOISLoadingOverlay: View {
    @Binding var loading: Bool
    var onDismiss: () -> Void
    
    @State private var isAnimatingOut = false
    @State private var playDisintegrate = false
    @State private var appear = false
    
    @State private var foundPOIs = 0;
    
    private func startDismiss() {
        UIApplication.shared.isIdleTimerDisabled = false
        guard !isAnimatingOut else { return }
        isAnimatingOut = true
        DispatchQueue.main.async { playDisintegrate = true }
    }
    
    private func getFoundPois() {
        if let cachedPOIs = AIService.shared.loadAIPOIs(for: SharedPlaces.shared.currentCity){
            DispatchQueue.main.async {
                foundPOIs = cachedPOIs.count
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer().frame(height: 10)
            HStack(spacing: 12) {
                Spacer().frame(width: 8)
                if loading {
                    ProgressView()
                }
                Text(loading ? "The AI is looking for sightseeing attractions. While you wait, you can play a game of memory." : "Generation successful! Found: \(foundPOIs)")
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)
                    .font(.headline)
                Spacer().frame(width: 8)
            }
            .frame(height: 30)
            MemoryView()
                .frame(height: 500)
            if !loading {
                HStack {
                    Spacer().frame(width:20)
                    Button {
                        withAnimation {
                            startDismiss()
                        }
                    } label: {
                        Spacer()
                        Text("Show places")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .foregroundColor(Color.white)
                        Spacer()
                    }
                    .frame(width: 200)
                    Spacer().frame(width:20)
                }
                .frame(height: 40)
                .background(Color.green)
                .cornerRadius(30)
                .shadow(color: Color.white.opacity(0.4), radius: 3, x: 4, y: 4)
                //.shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
            } else {
                Spacer().frame(height: 40)
            }
            Spacer().frame(height: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(foregroundGradient)
        .cornerRadius(24)
        .shadow(radius: 10)
        .padding(.top, UIScreen.main.bounds.height * 0.10)
        .padding(.bottom, UIScreen.main.bounds.height * 0.10)
        .padding(.horizontal, UIScreen.main.bounds.width * 0.05)
        .animation(.easeInOut(duration: 0.35), value: appear)
        .disintegrationEffect(isDeleted: playDisintegrate) {
            isAnimatingOut = false
            playDisintegrate = false
            onDismiss()
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            appear = false
            DispatchQueue.main.async { appear = true }
        }
        .onChange(of: loading) { oldValue, newValue in
            getFoundPois()
        }
    }
}
