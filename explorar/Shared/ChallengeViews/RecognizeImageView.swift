//
//  RecognizeImageView.swift
//  explorar
//
//  Created by Fabian Kuschke on 07.08.25.
//

import SwiftUI
import Combine
import ConfettiSwiftUI
import Drops

struct FadePoint: Identifiable {
    let id = UUID()
    var location: CGPoint
    var timestamp: Date
}

struct RecognizeItem {
    let question: String
    let image: UIImage
    let answers: [String]
}

struct RecognizeImageView: View {
    @State private var fadePoints: [FadePoint] = []
    @State var fadingTimer: Timer?
    let radius: CGFloat = 35
    let recognizeItem: RecognizeItem
    @State var recognizeName = ""
    @StateObject private var keyboard = KeyboardResponder()
    @State private var showConfetti: Int = 0
    let poiID: String
#if !APPCLIP
@ObservedObject var userFire = UserFire.shared
#endif
    
    func normalizeAnswer(_ str: String) -> String {
        let lowered = str.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: .diacriticInsensitive, locale: .current)

        let allowed = CharacterSet.alphanumerics
        let filtered = lowered.unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }
    
    func checkName() {
        var found = false
        for answer in recognizeItem.answers {
            if normalizeAnswer(recognizeName) ==
                normalizeAnswer(answer) {
                found = true
                let haptics = Haptics()
                haptics?.playPattern()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showConfetti += 1
                }
                #if !APPCLIP
                let points = 10
                if !UserDefaults.standard.bool(forKey: poiID) {
                    let res = LocalizedStringResource(
                        "points_awarded",
                        defaultValue: "Yeah correct, you got \(points) points! 🎉",
                        table: "Localizable",
                        comment: ""
                    )
                    Drops.show(Drop(title: String(localized: res),duration: 4.0))
                    userFire.updatePoints(amount: points) { result in
                        switch result {
                        case .success(let points):
                            print("Points added now: \(points)")
                            UserDefaults.standard.set(true, forKey: poiID)

                        case .failure(let error):
                            print("Error adding points: \(error)")
                        }
                    }
                } else {
                    Drops.show(Drop(title: NSLocalizedString("Yeah correct! 🎉", comment: ""),duration: 4.0))
                }
                #else
                Drops.show(Drop(title: NSLocalizedString("Yeah correct! 🎉", comment: ""),duration: 4.0))
                #endif
            }
        }
        if !found {
            print("Wrong Name \(recognizeItem.answers) \(recognizeName.lowercased())")
            Drops.show(Drop(title:NSLocalizedString("Wrong answer! Correct was: \(recognizeItem.answers)", comment: "")))
        }

    }

    func startFadingTimer() {
        fadingTimer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { _ in
            let now = Date()
            fadePoints.removeAll { now.timeIntervalSince($0.timestamp) > 0.25 }
        }
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(recognizeItem.question)
                    .font(.system(size: 28).bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .padding(.top, 10)
                    .frame(height: 30)
                Text("Wische auf dem schwarzen Bildschirm um die richtige Antwort herauszufinden.")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)
                    .frame(height: 30)
                //MARK: Image
                ZStack {
                    LinearGradient(colors: [.black, .black.opacity(0.95)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                    Image(uiImage: recognizeItem.image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 600)
                        .clipped()
                        .mask(
                            Canvas { context, size in
                                for (ix, point) in fadePoints.enumerated() {
                                    let gradient = Gradient(stops: [
                                        .init(color: .white, location: 0),
                                        .init(color: .white.opacity(0), location: 1)
                                    ])
                                    context.fill(
                                        Path(ellipseIn: CGRect(
                                            x: point.location.x - radius,
                                            y: point.location.y - radius,
                                            width: radius * 2,
                                            height: radius * 2)
                                        ),
                                        with: .radialGradient(gradient,
                                                              center: point.location,
                                                              startRadius: 0,
                                                              endRadius: radius + CGFloat(ix + 1)))
                                }
                            }
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    fadePoints.append(FadePoint(location: value.location, timestamp: Date()))
                                }
                        )
                }
                .frame(height: 600)
                // Spacer().frame(height:10)

                //MARK: TextField + Button
                HStack {
                    TextField("Name", text: $recognizeName)
                        .placeholder(when: recognizeName.isEmpty) {
                            Text("Name")
                                .minimumScaleFactor(0.5)
                                .foregroundColor(.gray)
                        }
                        .foregroundColor(.blue)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .submitLabel(.done)
                    Button {
                        checkName()
                    } label: {
                        Image(systemName: "arrow.forward.circle")
                            .resizable()
                            .foregroundColor(recognizeName.isEmpty ? .gray : .white)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .padding(.leading, 8)
                    }
                    .disabled(recognizeName.isEmpty)
                    .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                }
                .frame(height: 50)
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                // Spacer().frame(height:10)
            }
            .padding(.bottom, keyboard.currentHeight)
            .animation(.easeOut(duration: 0.25), value: keyboard.currentHeight)
        }
        .onAppear {
            startFadingTimer()
        }
        .confettiCannon(trigger: $showConfetti, num: 50, confettiSize: 15)
    }
}

// MARK: Keyboard Responder to see Textfield in View with Keyboard
class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0

    private var cancellables: Set<AnyCancellable> = []

    init() {
        let willShow = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .map { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0 }

        let willHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        Publishers.Merge(willShow, willHide)
            .receive(on: RunLoop.main)
            .assign(to: \.currentHeight, on: self)
            .store(in: &cancellables)
    }
}
