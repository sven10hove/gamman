//
//  NervousSystemState.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation
import SwiftUI

enum NervousSystemState: String, Codable, CaseIterable, Identifiable {
    case ventral = "ventral"
    case sympathetic = "sympathetic"
    case dorsalVagal = "dorsalVagal"
    case blended = "blended"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ventral: return "Safe & Connected"
        case .sympathetic: return "Activated"
        case .dorsalVagal: return "Withdrawn"
        case .blended: return "Mixed"
        }
    }

    var description: String {
        switch self {
        case .ventral:
            return "Feeling safe, calm, and socially engaged"
        case .sympathetic:
            return "Fight or flight response - mobilized energy"
        case .dorsalVagal:
            return "Shutdown, freeze, or dissociation"
        case .blended:
            return "Experiencing multiple states simultaneously"
        }
    }

    var color: Color {
        switch self {
        case .ventral: return .green
        case .sympathetic: return .orange
        case .dorsalVagal: return .blue
        case .blended: return .purple
        }
    }

    var systemImage: String {
        switch self {
        case .ventral: return "heart.fill"
        case .sympathetic: return "bolt.fill"
        case .dorsalVagal: return "snowflake"
        case .blended: return "circle.hexagongrid.fill"
        }
    }

    var emoji: String {
        switch self {
        case .ventral: return "🌿"
        case .sympathetic: return "⚡"
        case .dorsalVagal: return "❄️"
        case .blended: return "🔄"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .ventral: return .ventral
        case .sympathetic: return .sympathetic
        case .dorsalVagal: return .dorsalVagal
        case .blended: return .blended
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .ventral:
            return [Color(red: 0.2, green: 0.78, blue: 0.35), Color(red: 0.18, green: 0.65, blue: 0.42)]
        case .sympathetic:
            return [Color(red: 1.0, green: 0.58, blue: 0.0), Color(red: 1.0, green: 0.27, blue: 0.23)]
        case .dorsalVagal:
            return [Color(red: 0.35, green: 0.34, blue: 0.84), Color(red: 0.0, green: 0.48, blue: 1.0)]
        case .blended:
            return [Color(red: 0.69, green: 0.32, blue: 0.87), Color(red: 1.0, green: 0.18, blue: 0.33)]
        }
    }
}
