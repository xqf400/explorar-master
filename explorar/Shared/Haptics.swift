//
//  Haptics.swift
//  explorar
//
//  Created by Fabian Kuschke on 20.08.25.
//

import CoreHaptics
import UIKit

final class Haptics {
    private var engine: CHHapticEngine?

    init?() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return nil }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch { return nil }
    }

    func playPattern() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        guard let engine else { return }

        // confirmation tap
        let tap1 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            ],
            relativeTime: 0.0
        )

        // very short continuous
        let swell = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [],
            relativeTime: 0.05,
            duration: 0.18
        )
        let curves = [
            CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    .init(relativeTime: 0.0, value: 0.4),
                    .init(relativeTime: 0.09, value: 1.0),
                    .init(relativeTime: 0.18, value: 0.3),
                ],
                relativeTime: 0.05
            ),
            CHHapticParameterCurve(
                parameterID: .hapticSharpnessControl,
                controlPoints: [
                    .init(relativeTime: 0.0, value: 0.5),
                    .init(relativeTime: 0.18, value: 0.8),
                ],
                relativeTime: 0.05
            )
        ]

        // slightly softer
        let tap2 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            ],
            relativeTime: 0.26
        )

        do {
            let pattern = try CHHapticPattern(events: [tap1, swell, tap2], parameterCurves: curves)
            let player = try engine.makeAdvancedPlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptics error: \(error)")
        }
    }
}

