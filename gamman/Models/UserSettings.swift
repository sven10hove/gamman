//
//  UserSettings.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation
import SwiftData

@Model
@available(iOS 17.0, *)
final class UserSettings {
    var id: UUID
    var insightFrequency: String
    var minimumEntriesForInsight: Int
    var hasCompletedOnboarding: Bool
    var preferredAnalysisTimeframe: Int
    var notificationsEnabled: Bool
    var lastInsightGeneratedDate: Date?

    init() {
        self.id = UUID()
        self.insightFrequency = "weekly"
        self.minimumEntriesForInsight = 5
        self.hasCompletedOnboarding = false
        self.preferredAnalysisTimeframe = 7
        self.notificationsEnabled = false
        self.lastInsightGeneratedDate = nil
    }
}
