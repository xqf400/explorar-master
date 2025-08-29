//
//  Gamification.swift
//  explorar
//
//  Created by Fabian Kuschke on 23.08.25.
//
import SwiftUI

public struct Gamification {
    public static let pointsPerLevel = 200
    public static let maxLevel = 10
    public static let maxPointsInclusive = maxLevel * pointsPerLevel - 1 // 1999

    public struct RankDef {
        public let name: String
        public let minPoints: Int
    }

    public static let ranks: [RankDef] = [
        .init(name: "Beginner",        minPoints:   0),
        .init(name: "Fortgeschritten", minPoints: 400),
        .init(name: "Kenner",          minPoints: 800),
        .init(name: "Experte",         minPoints: 1200),
        .init(name: "Meister",         minPoints: 1600)
    ]

    public struct ProgressInfo {
        public let points: Int

        public let level: Int
        public let levelRange: ClosedRange<Int>
        public let pointsToNextLevel: Int?
        public let levelProgress: Double

        public let rankName: String
        public let rankIndex: Int
        public let rankRange: ClosedRange<Int>
        public let pointsToNextRank: Int?
        public let rankProgress: Double
    }

    public static func evaluate(points rawPoints: Int) -> ProgressInfo {
        let p = max(0, rawPoints)

        // --- Level ---
        let uncappedLevel = p / pointsPerLevel + 1
        let level = min(maxLevel, uncappedLevel)
        let levelMin = (level - 1) * pointsPerLevel
        let levelMax = min(level * pointsPerLevel - 1, maxPointsInclusive)
        let inLevel = min(p, levelMax) - levelMin
        let levelWidth = max(1, levelMax - levelMin + 1)
        let levelProgress = Double(inLevel) / Double(levelWidth - 1)
        let pointsToNextLevel: Int? = (level < maxLevel) ? (level * pointsPerLevel - p) : nil

        // --- Rang ---
        let (rankIdx, currentRank) = currentRankDef(for: p)
        let nextRank = (rankIdx < ranks.count - 1) ? ranks[rankIdx + 1] : nil
        let rankMin = currentRank.minPoints
        let rankMax = nextRank?.minPoints ?? (maxPointsInclusive + 1)
        let rankRange = rankMin...(rankMax - 1)
        let inRank = min(p, rankMax - 1) - rankMin
        let rankWidth = max(1, (rankMax - rankMin))
        let rankProgress = Double(inRank) / Double(rankWidth - 1)
        let pointsToNextRank: Int? = nextRank.map { max(0, $0.minPoints - p) }

        return ProgressInfo(
            points: p,
            level: level,
            levelRange: levelMin...levelMax,
            pointsToNextLevel: pointsToNextLevel,
            levelProgress: levelProgress,
            rankName: currentRank.name,
            rankIndex: rankIdx + 1,
            rankRange: rankRange,
            pointsToNextRank: pointsToNextRank,
            rankProgress: rankProgress
        )
    }

    public static func level(for points: Int) -> Int {
        min(maxLevel, max(0, points) / pointsPerLevel + 1)
    }

    public static func rankName(for points: Int) -> String {
        currentRankDef(for: max(0, points)).def.name
    }

    private static func currentRankDef(for points: Int) -> (idx: Int, def: RankDef) {
        var idx = 0
        for i in 0..<ranks.count {
            if points >= ranks[i].minPoints { idx = i } else { break }
        }
        return (idx, ranks[idx])
    }
}

// MARK: View
struct GamificationMiniView: View {
    @ObservedObject var userFire = UserFire.shared
    let points: Int
    private var info: Gamification.ProgressInfo { Gamification.evaluate(points: points) }
    
    private func timeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        let greeting: String
        switch hour {
        case 5..<12:
            greeting =  NSLocalizedString("Guten Morgen", comment: "")
        case 12..<17:
            greeting = NSLocalizedString("Guten Tag", comment: "")
        case 17..<22:
            greeting = NSLocalizedString("Guten Abend", comment: "")
        default:
            greeting = NSLocalizedString("Gute Nacht", comment: "")
        }
        
        return "\(greeting) \(userFire.userFirebase?.userName ?? "Username")"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(timeBasedGreeting())
                    .minimumScaleFactor(0.6)
                    .font(.title).bold()
                    .foregroundStyle(Color.blue)
                Spacer()
                Text("\(info.points) Punkte")
                    .minimumScaleFactor(0.6)
                    .font(.title)
                    .foregroundStyle(Color.blue)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Level \(info.level)")
                        .minimumScaleFactor(0.9)
                        .font(.subheadline).bold()
                    Spacer()
                    Text("\(info.levelRange.lowerBound)–\(info.levelRange.upperBound) Punkte")
                        .minimumScaleFactor(0.9)
                        .font(.caption).foregroundStyle(.secondary)
                }
                MiniProgressBar(progress: info.levelProgress, height: 8)
                HStack {
                    if let left = info.pointsToNextLevel {
                        Label("Bis Level \(min(info.level + 1, Gamification.maxLevel))", systemImage: "arrow.up.right")
                        Spacer()
                        Text("\(left) Punkte")
                            .minimumScaleFactor(0.9)
                    } else {
                        Label("Max-Level erreicht", systemImage: "checkmark.seal")
                        Spacer()
                        Text("100%")
                            .minimumScaleFactor(0.9)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Rang: \(info.rankName)")
                        .minimumScaleFactor(0.9)
                        .font(.subheadline).bold()
                    Spacer()
                    Text("\(info.rankRange.lowerBound)–\(info.rankRange.upperBound) Punkte")
                        .minimumScaleFactor(0.9)
                        .font(.caption).foregroundStyle(.secondary)
                }
                MiniProgressBar(progress: info.rankProgress, height: 8)
                HStack {
                    if let left = info.pointsToNextRank {
                        Label("Bis nächster Rang", systemImage: "arrow.up.right")
                        Spacer()
                        Text("\(left) Punkte")
                            .minimumScaleFactor(0.9)
                    } else {
                        Label("Höchster Rang erreicht", systemImage: "checkmark.seal")
                        Spacer()
                        Text("100%")
                            .minimumScaleFactor(0.9)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .accessibilityElement(children: .contain)
    }
}

// MARK: MiniProgressBar
private struct MiniProgressBar: View {
    let progress: Double
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            let clamped = max(0, min(1, progress))
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height/2)
                    .fill(Color.secondary.opacity(0.25))
                RoundedRectangle(cornerRadius: height/2)
                    .fill(Color.green)
                    .frame(width: clamped * geo.size.width)
                    .animation(.easeInOut(duration: 0.35), value: clamped)
            }
        }
        .frame(height: height)
        .accessibilityHidden(false)
        .accessibilityLabel(Text("Fortschritt"))
        .accessibilityValue(Text("\(Int(round(max(0, min(1, progress)) * 100))) Prozent"))
    }
}
