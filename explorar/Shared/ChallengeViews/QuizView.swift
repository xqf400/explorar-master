//
//  QuizView.swift
//  explorar
//
//  Created by Fabian Kuschke on 06.08.25.
//

import SwiftUI
import ConfettiSwiftUI
import Drops
#if !APPCLIP
import TelemetryClient
#endif

struct QuizQuestion {
    let question: String
    let options: [String]
    let correctIndex: Int
}


struct QuizView: View {
    @State var question: QuizQuestion
    @State private var selectedIndex: Int? = nil
    @State private var showResult = false
    @State private var showConfetti: Int = 0
    @Environment(\.dismiss) private var dismiss
    let poiID: String
#if !APPCLIP
    @ObservedObject var userFire = UserFire.shared
#endif
    
    var body: some View {
        VStack(spacing: 24) {
            Text(question.question)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .foregroundColor(Color.white)
                .multilineTextAlignment(.center)
                .padding(.top, 32)
            
            ForEach(0..<question.options.count, id: \.self) { idx in
                Button(action: {
                    selectedIndex = idx
                    if idx == question.correctIndex {
                        showResult = true
                        let haptics = Haptics()
                        haptics?.playPattern()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showConfetti += 1
                        }
    #if !APPCLIP
                        if UserFire.shared.dailyChallenges?.challenge1 == "3" {
                            UserFire.shared.updateDailyChallenge(id: "1")
                        }
                        if UserFire.shared.dailyChallenges?.challenge2 == "3" {
                            UserFire.shared.updateDailyChallenge(id: "2")
                        }
                        if UserFire.shared.dailyChallenges?.challenge3 == "3" {
                            UserFire.shared.updateDailyChallenge(id: "3")
                        }
                        if !UserDefaults.standard.bool(forKey: poiID) {
                            let points = 10
                            let res = LocalizedStringResource(
                                "points_awarded",
                                defaultValue: "Yeah correct, you got \(points) points! 🎉",
                                table: "Localizable",
                                comment: ""
                            )
                            Drops.show(Drop(title: String(localized: res),duration: 4.0))
                            userFire.updatePoints(amount: points) { result in
                                switch result {
                                case .success(let points1):
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
                    } else {
                        Drops.show(Drop(title:NSLocalizedString("Wrong answer!", comment: ""),duration: 4.0))
                    }
                }) {
                    Text(question.options[idx])
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedIndex == idx ? Color.green.opacity(0.3) : Color.gray.opacity(0.2))
                        .cornerRadius(20)
                }
                .cornerRadius(20)
                .shadow(color: Color.white.opacity(0.4), radius: 3, x: -1, y: -2)
                .shadow(color: Color.white.opacity(0.4), radius: 3, x: 4, y: 4)
                .disabled(showResult)
            }
            
            if showResult {
                HStack {
                    Spacer().frame(width: 30)
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Spacer()
                            Text("Zurückkehren")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.5)
                                .foregroundColor(Color.white)
                            Spacer()
                        }
                    }
                    .frame(height: 60)
                    .background(foregroundGradient)
                    .cornerRadius(30)
                    .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
                    Spacer().frame(width: 30)
                }
            } else {
                Spacer().frame(height: 60)
            }
            Spacer()
        }
        
        .onAppear{
#if !APPCLIP
            TelemetryDeck.signal("Quiz")
#endif
        }
        .padding()
        .confettiCannon(trigger: $showConfetti, num: 50, confettiSize: 15)
    }
    
    func resetQuiz() {
        selectedIndex = nil
        showResult = false
    }
}
