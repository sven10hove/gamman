//
//  AppGradients.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

// MARK: - App Gradient Definitions

extension LinearGradient {
    // MARK: - Input & Action Gradients

    /// Orange to yellow gradient for text input areas (Ask a Question style)
    static let orangeYellowInput = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.58, blue: 0.0),   // #FF9500
            Color(red: 1.0, green: 0.8, blue: 0.0)     // #FFCC00
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Purple to blue gradient for recap cards
    static let purpleBlueRecap = LinearGradient(
        colors: [
            Color(red: 0.345, green: 0.337, blue: 0.839),  // #5856D6
            Color(red: 0.0, green: 0.478, blue: 1.0)       // #007AFF
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Nervous System State Gradients

    /// Ventral vagal - Safe & Connected (Green tones)
    static let ventral = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.78, blue: 0.35),   // Bright green
            Color(red: 0.18, green: 0.65, blue: 0.42)  // Teal green
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Sympathetic - Activated (Orange-red tones)
    static let sympathetic = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.58, blue: 0.0),    // Orange
            Color(red: 1.0, green: 0.27, blue: 0.23)   // Red-orange
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Dorsal Vagal - Withdrawn (Blue-purple tones)
    static let dorsalVagal = LinearGradient(
        colors: [
            Color(red: 0.35, green: 0.34, blue: 0.84),  // Purple-blue
            Color(red: 0.0, green: 0.48, blue: 1.0)    // Blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Blended - Mixed states (Purple-pink tones)
    static let blended = LinearGradient(
        colors: [
            Color(red: 0.69, green: 0.32, blue: 0.87),  // Purple
            Color(red: 1.0, green: 0.18, blue: 0.33)   // Pink-red
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Utility Gradients

    /// Subtle glass overlay gradient
    static let glassOverlay = LinearGradient(
        colors: [
            Color.white.opacity(0.25),
            Color.white.opacity(0.05)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Dark overlay for text readability on gradients
    static let darkOverlay = LinearGradient(
        colors: [
            Color.black.opacity(0.0),
            Color.black.opacity(0.3)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Color Extensions for Gradients

extension Color {
    // App accent colors
    static let appOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let appYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let appPurple = Color(red: 0.345, green: 0.337, blue: 0.839)
    static let appBlue = Color(red: 0.0, green: 0.478, blue: 1.0)

    // State colors (brighter versions)
    static let ventralGreen = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let sympatheticOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let dorsalBlue = Color(red: 0.35, green: 0.34, blue: 0.84)
    static let blendedPurple = Color(red: 0.69, green: 0.32, blue: 0.87)
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Group {
                Text("Orange Yellow Input")
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient.orangeYellowInput)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Purple Blue Recap")
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient.purpleBlueRecap)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Divider()

            Group {
                Text("Ventral - Safe & Connected")
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient.ventral)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Sympathetic - Activated")
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient.sympathetic)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Dorsal Vagal - Withdrawn")
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient.dorsalVagal)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Blended - Mixed")
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient.blended)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
}
