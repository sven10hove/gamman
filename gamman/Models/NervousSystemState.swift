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
}
