//
//  MemoryCard.swift
//  explorar
//
//  Created by Fabian Kuschke on 16.08.25.
//


import SwiftUI

struct MemoryCard: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

struct MemoryView: View {
    @State private var cards: [MemoryCard] = []
    @State private var indexOfFirstFlippedCard: Int? = nil
    @State private var matchesFound: Int = 0
    @State private var moves: Int = 0
    @State private var isInteractionLocked: Bool = false

    let emojis = ["🐶", "😎", "🥕", "🍎", "⚽️", "🚗", "🏆", "🎈"]

    var body: some View {
        VStack(spacing: 10) {
            Text("Pairs found: \(matchesFound) / \(emojis.count)")
                .minimumScaleFactor(0.5)
                .font(.headline)
                .padding(.top, 10)

            Text("Moves: \(moves)")
                .minimumScaleFactor(0.5)
                .font(.subheadline)
                .padding(.bottom)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(cards.indices, id: \.self) { index in
                    let card = cards[index]
                    if card.isMatched {
                        Color.clear
                            .frame(height: 60)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(card.isFaceUp ? Color.white : Color.blue)
                                .frame(height: 60)
                                .shadow(radius: 2)
                            if card.isFaceUp {
                                Text(card.emoji)
                                    .font(.largeTitle)
                                    .frame(height: 40)
                            } else {
                                Image("Icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 40)
                                    .cornerRadius(40)
                            }
                        }
                        .onTapGesture {
                            flipCard(at: index)
                        }
                        .disabled(card.isFaceUp || card.isMatched || isInteractionLocked)
                        .transition(.opacity)
                    }
                }
            }
            .padding()

            if matchesFound == emojis.count {
                VStack {
                    Text("You found all pairs in \(moves) moves!")
                        .minimumScaleFactor(0.5)
                        .font(.title2)
                        .padding(.top)
                    Button("Restart") { resetGame() }
                        .padding()
                }
                .frame(height: 40)
            } else {
                Spacer()
                    .frame(height: 40)
            }

            Spacer()
        }
        .animation(.easeInOut, value: cards)
        .onAppear { resetGame() }
    }

    func flipCard(at index: Int) {
        guard !isInteractionLocked, !cards[index].isFaceUp, !cards[index].isMatched else { return }

        if let firstIndex = indexOfFirstFlippedCard {
            // Second card flipped
            cards[index].isFaceUp = true
            moves += 1
            isInteractionLocked = true // lock user input

            if cards[index].emoji == cards[firstIndex].emoji {
                // It's a match!
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    cards[index].isMatched = true
                    cards[firstIndex].isMatched = true
                    indexOfFirstFlippedCard = nil
                    matchesFound += 1
                    isInteractionLocked = false
                }
            } else {
                // Not a match, flip back both after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    cards[index].isFaceUp = false
                    cards[firstIndex].isFaceUp = false
                    indexOfFirstFlippedCard = nil
                    isInteractionLocked = false
                }
            }
        } else {
            // First card flipped
            for i in cards.indices where !cards[i].isMatched {
                cards[i].isFaceUp = false
            }
            cards[index].isFaceUp = true
            indexOfFirstFlippedCard = index
        }
    }

    func resetGame() {
        let allEmojis = (emojis + emojis).shuffled()
        cards = allEmojis.map { emoji in
            MemoryCard(emoji: emoji)
        }
        indexOfFirstFlippedCard = nil
        matchesFound = 0
        moves = 0
        isInteractionLocked = false
    }
}
