//
//  JournalEntry.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation
import SwiftData

@Model
@available(iOS 17.0, *)
final class JournalEntry {
    var id: UUID
    var content: String
    var timestamp: Date
    var nervousSystemState: String
    var stateIntensity: Int
    var triggers: [String]
    var bodyLocations: [String]
    var isAnalyzed: Bool
    var lastModified: Date

    // Future: HealthKit data
    var hrvValue: Double?
    var sleepHours: Double?

    init(
        content: String,
        nervousSystemState: NervousSystemState,
        stateIntensity: Int = 5,
        triggers: [String] = [],
        bodyLocations: [String] = []
    ) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.nervousSystemState = nervousSystemState.rawValue
        self.stateIntensity = stateIntensity
        self.triggers = triggers
        self.bodyLocations = bodyLocations
        self.isAnalyzed = false
        self.lastModified = Date()
    }

    var state: NervousSystemState {
        get { NervousSystemState(rawValue: nervousSystemState) ?? .blended }
        set { nervousSystemState = newValue.rawValue }
    }
}
