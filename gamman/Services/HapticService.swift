//
//  HapticService.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import UIKit

enum HapticService {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // Convenience methods
    static func success() {
        notification(.success)
    }

    static func error() {
        notification(.error)
    }

    static func warning() {
        notification(.warning)
    }

    static func lightTap() {
        impact(.light)
    }

    static func heavyTap() {
        impact(.heavy)
    }
}
