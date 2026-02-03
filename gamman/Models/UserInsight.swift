//
//  UserInsight.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation
import SwiftData

@Model
@available(iOS 17.0, *)
final class UserInsight {
    var id: UUID
    var title: String
    var content: String
    var category: String
    var generatedDate: Date
    var entriesAnalyzedCount: Int
    var dateRangeStart: Date
    var dateRangeEnd: Date
    var isRead: Bool
    var isBookmarked: Bool
    var analyzedEntryIDsData: Data

    init(
        title: String,
        content: String,
        category: String,
        entriesAnalyzedCount: Int,
        dateRangeStart: Date,
        dateRangeEnd: Date,
        analyzedEntryIDs: [UUID]
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.category = category
        self.generatedDate = Date()
        self.entriesAnalyzedCount = entriesAnalyzedCount
        self.dateRangeStart = dateRangeStart
        self.dateRangeEnd = dateRangeEnd
        self.isRead = false
        self.isBookmarked = false
        self.analyzedEntryIDsData = (try? JSONEncoder().encode(analyzedEntryIDs)) ?? Data()
    }

    var analyzedEntryIDs: [UUID] {
        get {
            (try? JSONDecoder().decode([UUID].self, from: analyzedEntryIDsData)) ?? []
        }
        set {
            analyzedEntryIDsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
}
