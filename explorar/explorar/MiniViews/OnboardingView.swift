//
//  OnboardingView.swift
//  explorar
//
//  Created by Fabian Kuschke on 07.08.25.
//

import SwiftUI
import Photos

struct AppleOnBoardingCard: Identifiable {
    var id: String = UUID().uuidString
    var symbol: String
    var title: String
    var subTitle: String
}

@resultBuilder
struct OnBoardingCardResultBuilder {
    static func buildBlock(_ components: AppleOnBoardingCard...) -> [AppleOnBoardingCard] {
        components.compactMap { $0 }
    }
}

struct OnboardingView<Icon: View, Footer: View>: View {
    var tint: Color
    var title: String
    var icon: Icon
    var cards: [AppleOnBoardingCard]
    var footer: Footer
    var onContinue: () -> ()
    
    init(
        tint: Color,
        title: String,
        @ViewBuilder icon: @escaping () -> Icon,
        @OnBoardingCardResultBuilder cards: @escaping () -> [AppleOnBoardingCard],
        @ViewBuilder footer: @escaping () -> Footer,
        onContinue: @escaping () -> Void
    ) {
        self.tint = tint
        self.title = title
        self.icon = icon()
        self.cards = cards()
        self.footer = footer()
        self.onContinue = onContinue
        
        self._animateCards = .init(initialValue: Array(repeating: false, count: self.cards.count))
    }
    
    @State private var animateIcon: Bool = false
    @State private var animateTitle: Bool = false
    @State private var animateCards: [Bool]
    @State private var animateFooter: Bool = false
    @State private var shine: Bool = false
    

    func requestPhotoAddPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async { completion(newStatus == .authorized) }
            }
        default:
            completion(false)
        }
    }
    func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("requestCameraPermission authorized")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                print("requestCameraPermission notDetermined \(granted)")
            }
        case .denied, .restricted:
            print("requestCameraPermission .denied, .restricted")
        @unknown default:
            print("requestC ameraPermissiondefault")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 20) {
                        icon
                            .frame(maxWidth: .infinity)
                            .blurSlide(animateIcon)
                        
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .blurSlide(animateTitle)
                        
                        CardsView()
                    }
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
                
                VStack(spacing: 0) {
                    footer
                    
                    Button(action: onContinue) {
                        Text("Continue")
                            .minimumScaleFactor(0.8)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .frame(height: 50)
                    .background(foregroundGradient)
                    .shine(toggle: shine, duration: 3.0)
                    .cornerRadius(30)
                    .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                    .shadow(color: Color.white.opacity(0.3), radius: 3, x: -1, y: -2)
                    Spacer().frame(height: 20)
                }
                .blurSlide(animateFooter)
            }
            .frame(maxWidth: 330)
            .onAppear {
                shine.toggle()
                Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                    shine.toggle()
                }
                requestPhotoAddPermission { access in
                    print("access \(access)")
                }
                Task {
                    let ok = await requestCameraPermission()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(foregroundGradient.ignoresSafeArea())
        .interactiveDismissDisabled()
        .allowsHitTesting(animateFooter)
        .task {
            guard !animateIcon else { return }
            
            await delayedAnimation(0.35) {
                animateIcon = true
            }
            
            await delayedAnimation(0.2) {
                animateTitle = true
            }
            
            try? await Task.sleep(for: .seconds(0.2))
            
            for index in animateCards.indices {
                let delay = Double(index) * 0.1
                await delayedAnimation(delay) {
                    animateCards[index] = true
                }
            }
            
            await delayedAnimation(0.2) {
                animateFooter = true
            }
        }
        .setUpOnBoarding()
    }
    
    /// Cards View
    @ViewBuilder
    func CardsView() -> some View {
        Group {
            ForEach(cards.indices, id: \.self) { index in
                let card = cards[index]
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: card.symbol)
                        .font(.title2)
                        .foregroundStyle(tint)
                        .symbolVariant(.fill)
                        .frame(width: 45)
                        .offset(y: 10)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(card.title)
                            .font(.title3)
                            .lineLimit(1)
                        
                        Text(card.subTitle)
                            .lineLimit(2)
                    }
                }
                .blurSlide(animateCards[index])
            }
        }
    }
    
    func delayedAnimation(_ delay: Double, action: @escaping () -> ()) async {
        try? await Task.sleep(for: .seconds(delay))
        
        withAnimation(.smooth) {
            action()
        }
    }
}

extension View {
    @ViewBuilder
    func blurSlide(_ show: Bool) -> some View {
        self
            .compositingGroup()
            .blur(radius: show ? 0 : 10)
            .opacity(show ? 1 : 0)
            .offset(y: show ? 0 : 100)
    }
    
    @ViewBuilder
    fileprivate func setUpOnBoarding() -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if #available(iOS 18, *) {
                self
                    .presentationSizing(.fitted)
                    .padding(.horizontal, 25)
            } else {
                self
                    .padding(.bottom, 15)
            }
        } else {
            self
        }
        
    }
}
