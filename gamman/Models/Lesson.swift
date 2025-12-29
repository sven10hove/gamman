//
//  Lesson.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation
import SwiftData

struct LessonSectionData: Codable, Hashable {
    let heading: String
    let content: String
    let imageSystemName: String?
    let practicePrompt: String?
}

@Model
final class Lesson {
    var id: UUID
    var title: String
    var subtitle: String
    var category: String
    var sectionsData: Data
    var estimatedMinutes: Int
    var isPrebuilt: Bool
    var isCompleted: Bool
    var completedDate: Date?
    var createdDate: Date
    var userPrompt: String?

    init(
        title: String,
        subtitle: String,
        category: String,
        sections: [LessonSectionData],
        estimatedMinutes: Int,
        isPrebuilt: Bool = true,
        userPrompt: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.sectionsData = (try? JSONEncoder().encode(sections)) ?? Data()
        self.estimatedMinutes = estimatedMinutes
        self.isPrebuilt = isPrebuilt
        self.isCompleted = false
        self.completedDate = nil
        self.createdDate = Date()
        self.userPrompt = userPrompt
    }

    var sections: [LessonSectionData] {
        get {
            (try? JSONDecoder().decode([LessonSectionData].self, from: sectionsData)) ?? []
        }
        set {
            sectionsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
}
