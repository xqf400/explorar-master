//
//  TicTacToeView.swift
//  explorar
//
//  Created by Fabian Kuschke on 18.08.25.
//

import SwiftUI

enum Player { case human, computer }
enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    var id: String { rawValue }
    
    var localized: String {
        NSLocalizedString(self.rawValue, comment: "")
    }
}

struct Move: Equatable {
    let player: Player
    let index: Int
}

struct TicTacToeView: View {
    @State private var moves: [Move?] = Array(repeating: nil, count: 9)
    @State private var isGameOver = false
    @State private var winner: Player?
    @State private var difficulty: Difficulty = .easy
    @State private var isComputersTurn = false
    
    let winPatterns: Set<Set<Int>> = [
        [0,1,2],[3,4,5],[6,7,8], // rows
        [0,3,6],[1,4,7],[2,5,8], // columns
        [0,4,8],[2,4,6]          // diagonals
    ]
    init() {
        UISegmentedControl.appearance().selectedSegmentTintColor = .blue.withAlphaComponent(0.5)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
    }
    
    // MARK: View
    var body: some View {
        VStack {
            Spacer().frame(height: 10)
            Picker("Difficulty", selection: $difficulty) {
                ForEach(Difficulty.allCases) { diff in
                    Text(diff.localized).tag(diff)
                }
            }
            .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
            .frame(height: 30)
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            Spacer().frame(height: 10)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                ForEach(0..<9) { i in
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundStyle(.blue.opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
                            .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)

                        Text(symbol(at: i))
                            .font(.largeTitle)
                    }
                    .onTapGesture {
                        playerTap(at: i)
                    }
                    .disabled(moves[i] != nil || isComputersTurn || isGameOver)
                }
            }
            .frame(width: 260, height: 260)
            .padding()
            
            if isGameOver {
                HStack {
                    Spacer().frame(width:20)
                    Button {
                        resetGame()
                    } label: {
                        Text("\(gameOverMessage()) Restart")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.3)
                            .foregroundColor(Color.blue)
                    }
                    Spacer().frame(width:20)
                }
                .frame(height: 30)
                .background(Color.white)
                .cornerRadius(30)
                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 4, y: 4)
            } else {
                Spacer().frame(height: 30)
            }
            Spacer().frame(height: 10)
        }
        .onChange(of: moves) { _, _ in
            checkGameOver()
            if !isGameOver && isComputersTurn {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    computerMove()
                }
            }
        }
        .onAppear { resetGame() }
    }
    
    func symbol(at index: Int) -> String {
        guard let move = moves[index] else { return "" }
        return move.player == .human ? "X" : "O"
    }
    
    // MARK: player tap
    func playerTap(at index: Int) {
        guard moves[index] == nil, !isGameOver else { return }
        moves[index] = Move(player: .human, index: index)
        isComputersTurn = true
    }
    
    // MARK: Computer move
    func computerMove() {
        guard !isGameOver else { return }
        let position: Int
        switch difficulty {
        case .easy:
            position = availableMoves().randomElement() ?? 0
        case .medium:
            if Bool.random(), let win = findWinningMove(for: .computer) {
                position = win
            } else if let block = findWinningMove(for: .human) {
                position = block
            } else {
                position = availableMoves().randomElement() ?? 0
            }
        case .hard:
            position = bestMove(for: .computer)
        }
        moves[position] = Move(player: .computer, index: position)
        isComputersTurn = false
    }
    
    func availableMoves() -> [Int] {
        moves.enumerated().compactMap { $0.element == nil ? $0.offset : nil }
    }
    
    // MARK:  find winning move
    func findWinningMove(for player: Player) -> Int? {
        for pattern in winPatterns {
            let playerMoves = moves.enumerated().compactMap { $1?.player == player ? $0 : nil }
            let set = Set(playerMoves)
            let diff = pattern.subtracting(set)
            if diff.count == 1, let move = diff.first, moves[move] == nil {
                return move
            }
        }
        return nil
    }
    
    // MARK: check game over
    func checkGameOver() {
        if let winnerPlayer = checkWin() {
            winner = winnerPlayer
            isGameOver = true
        } else if availableMoves().isEmpty {
            winner = nil
            isGameOver = true
        }
    }
    
    // MARK: check win
    func checkWin() -> Player? {
        for pattern in winPatterns {
            let players = pattern.compactMap { moves[$0]?.player }
            if players.count == 3, Set(players).count == 1 {
                return players.first
            }
        }
        return nil
    }
    
    // MARK: game over message
    func gameOverMessage() -> String {
        if let winner = winner {
            return winner == .human ? NSLocalizedString("You Win!", comment: "") : NSLocalizedString("Computer Wins!", comment: "")
        } else {
            return NSLocalizedString("It's a Draw!", comment: "")
        }
    }
    
    // MARK: Reset game
    func resetGame() {
        moves = Array(repeating: nil, count: 9)
        isGameOver = false
        winner = nil
        isComputersTurn = Bool.random()
        if isComputersTurn {
            computerMove()
        }
    }

    func bestMove(for player: Player) -> Int {
        // Minimax for hard mode
        func minimax(_ board: [Move?], current: Player) -> (score: Int, index: Int?) {
            if let winPlayer = winningPlayer(on: board) {
                if winPlayer == .computer { return (1, nil) }
                if winPlayer == .human { return (-1, nil) }
            }
            let available = board.enumerated().compactMap { $1 == nil ? $0 : nil }
            if available.isEmpty { return (0, nil) }
            
            var movesAndScores: [(Int, Int)] = []
            for move in available {
                var newBoard = board
                newBoard[move] = Move(player: current, index: move)
                let result = minimax(newBoard, current: current == .computer ? .human : .computer)
                movesAndScores.append((result.score, move))
            }
            
            if current == .computer {
                let maxMove = movesAndScores.max(by: { $0.0 < $1.0 })!
                return (maxMove.0, maxMove.1)
            } else {
                let minMove = movesAndScores.min(by: { $0.0 < $1.0 })!
                return (minMove.0, minMove.1)
            }
        }
        
        let (_, move) = minimax(moves, current: player)
        return move ?? availableMoves().randomElement()!
    }
    
    // MARK: winning player
    func winningPlayer(on board: [Move?]) -> Player? {
        for pattern in winPatterns {
            let players = pattern.compactMap { board[$0]?.player }
            if players.count == 3, Set(players).count == 1 {
                return players.first
            }
        }
        return nil
    }
}

#Preview {
    TicTacToeView()
}
