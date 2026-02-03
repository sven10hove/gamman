//
//  Lesson.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation
import SwiftData

@available(iOS 17.0, *)
struct LessonSectionData: Codable, Hashable {
    let heading: String
    let content: String
    let imageSystemName: String?
    let practicePrompt: String?
}

@available(iOS 17.0, *)
enum LessonGenerationStatus: String, Codable, Sendable {
    case notStarted
    case generating
    case completed
    case partialFailure
    case failed
}

@Model
@available(iOS 17.0, *)
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

    // Multi-agent generation tracking
    var generationStatus: String = LessonGenerationStatus.notStarted.rawValue
    var totalSections: Int = 0
    var completedSections: Int = 0
    var currentAgentTask: String?
    var generationStartedAt: Date?
    var generationCompletedAt: Date?

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
        self.generationStatus = LessonGenerationStatus.notStarted.rawValue
        self.totalSections = sections.count
        self.completedSections = sections.count
    }

    /// Initializer for multi-agent generated lessons
    init(
        title: String,
        subtitle: String,
        userPrompt: String,
        totalSections: Int
    ) {
        self.id = UUID()
        self.title = title
        self.subtitle = subtitle
        self.category = "custom"
        self.sectionsData = Data()
        self.estimatedMinutes = max(5, totalSections * 3)
        self.isPrebuilt = false
        self.isCompleted = false
        self.createdDate = Date()
        self.userPrompt = userPrompt
        self.generationStatus = LessonGenerationStatus.generating.rawValue
        self.totalSections = totalSections
        self.completedSections = 0
        self.generationStartedAt = Date()
    }

    /// Legacy sections accessor for pre-built lessons loaded from JSON.
    /// Generated lessons use LessonSection model directly; this property
    /// is populated at generation completion for backward compatibility.
    var sections: [LessonSectionData] {
        get {
            (try? JSONDecoder().decode([LessonSectionData].self, from: sectionsData)) ?? []
        }
        set {
            sectionsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var lessonGenerationStatus: LessonGenerationStatus {
        get { LessonGenerationStatus(rawValue: generationStatus) ?? .notStarted }
        set { generationStatus = newValue.rawValue }
    }

    var isGenerating: Bool {
        lessonGenerationStatus == .generating
    }

    var generationProgress: Double {
        guard totalSections > 0 else { return 0 }
        return Double(completedSections) / Double(totalSections)
    }
}
