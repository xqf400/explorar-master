//
//  Hangman.swift
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

struct HangmanQuestion {
    var secretWord: String
    let helpText: String
}

struct HangmanView: View {
    @State var hangmanQuestion: HangmanQuestion
    @State private var displayWord: [String] = []
    @State private var guessedLetters: Set<String> = []
    @State private var wrongGuesses: Int = 0
    @State private var gameOver: Bool = false
    @State private var showConfetti: Int = 0
    @Environment(\.dismiss) private var dismiss

    let poiID: String
#if !APPCLIP
@ObservedObject var userFire = UserFire.shared
#endif
    
    // Possible in Localizable.xstrings i think
    private func getAlphabet() -> [String] {
        let englishAlphabet = [
            "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
            "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
        ]
        if let languageCode = Locale.current.language.languageCode?.identifier {
            switch languageCode {
            case "de":
                let germanAlphabet = [
                    "A","Ä","B","C","D","E","F","G","H","I","J","K","L","M",
                    "N","O","Ö","P","Q","R","S","ß","T","U","Ü","V","W","X","Y","Z"
                ]
                return germanAlphabet
            case "fr":
                let frenchAlphabet = [
                    "A", "Â", "B", "C", "Ç", "D", "E", "É", "È", "Ê", "Ë", "F", "G", "H", "I", "Î", "Ï",
                    "J", "K", "L", "M", "N", "O", "Ô", "P", "Q", "R", "S", "T", "U", "Ù", "Û", "Ü", "V", "W", "X", "Y", "Z"
                ]
                return frenchAlphabet
            case "tr":
                let turkishAlphabet = [
                    "A", "B", "C", "Ç", "D", "E", "F", "G", "Ğ", "H", "I", "İ", "J", "K", "L", "M",
                    "N", "O", "Ö", "P", "R", "S", "Ş", "T", "U", "Ü", "V", "Y", "Z"
                ]
                return turkishAlphabet
            case "it":
                let italianAlphabet = [
                    "A", "B", "C", "D", "E", "F", "G", "H", "I", "L", "M", "N", "O", "P",
                    "Q", "R", "S", "T", "U", "V", "Z"
                ]
                return italianAlphabet
            default:
                print("Other language take english: \(languageCode)")
                return englishAlphabet
            }
        }
        return englishAlphabet
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Galgenmännchen")
                .minimumScaleFactor(0.5)
                .font(.largeTitle)
                .padding(.top)
            Spacer()
            VStack(spacing: 10) {
                Text(hangmanQuestion.helpText)
                    .minimumScaleFactor(0.5)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Falsche Versuche: \(wrongGuesses) / 10")
                    .minimumScaleFactor(0.5)
                    .font(.headline)
                    .foregroundColor(.orange)
                
                HStack(spacing: 6) {
                    ForEach(displayWord, id: \.self) { letter in
                        Text(letter)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .frame(width: 32, height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(5)
                    }
                }
                .padding(.vertical)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(getAlphabet(), id: \.self) { letter in
                        Button(action: { guess(letter: letter) }) {
                            Text(letter)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(guessedLetters.contains(letter) ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(guessedLetters.contains(letter) || gameOver)
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                startGame()
                #if !APPCLIP
                TelemetryDeck.signal("Hangman")
                #endif
            }
            
            if gameOver {

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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            backgroundGradient
                .ignoresSafeArea(.all)
        }
        .confettiCannon(trigger: $showConfetti, num: 50, confettiSize: 15)
    }
    
    func startGame() {
        let upperWord = hangmanQuestion.secretWord.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        hangmanQuestion.secretWord = upperWord
        displayWord = upperWord.map { $0 == " " ? " " : "_" }
        guessedLetters = []
        wrongGuesses = 0
        gameOver = false
    }
    
    func guess(letter: String) {
        guard !gameOver else { return }
        guessedLetters.insert(letter)
        let charArray = Array(hangmanQuestion.secretWord)
        var found = false
        for (idx, c) in charArray.enumerated() {
            if String(c) == letter {
                displayWord[idx] = letter
                found = true
            }
        }
        if !found {
            wrongGuesses += 1
            if wrongGuesses >= 10 {
                gameOver = true
                Drops.show(Drop(title: "Leider verloren! Das Wort war: \(hangmanQuestion.secretWord)"))
            }
        } else if !displayWord.contains("_") {
            gameOver = true
            let haptics = Haptics()
            haptics?.playPattern()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti += 1
            }

            #if !APPCLIP
            if UserFire.shared.dailyChallenges?.challenge1 == "4" {
                UserFire.shared.updateDailyChallenge(id: "1")
            }
            if UserFire.shared.dailyChallenges?.challenge2 == "4" {
                UserFire.shared.updateDailyChallenge(id: "2")
            }
            if UserFire.shared.dailyChallenges?.challenge3 == "4" {
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
    
    func resetGame() {
        displayWord = []
        guessedLetters = []
        wrongGuesses = 0
        gameOver = false
    }
}
