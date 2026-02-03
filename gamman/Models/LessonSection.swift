//
//  LessonSection.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation
import SwiftData

@available(iOS 17.0, *)
enum SectionStatus: String, Codable, Sendable {
    case pending
    case writing
    case factChecking
    case curating
    case illustrating
    case completed
    case failed
}

@Model
@available(iOS 17.0, *)
final class LessonSection {
    var id: UUID = UUID()
    var lessonID: UUID = UUID()
    var orderIndex: Int = 0

    // Content
    var heading: String = ""
    var learningObjective: String?
    var content: String?
    var revisedContent: String?
    var factCheckNotes: String?

    // Resources (from Curator Agent)
    var externalResourcesData: Data?

    // Illustration (from Illustrator Agent)
    // Note: For scalability, imageData should be moved to filesystem storage
    // keeping only imageURL reference here. Current approach works for MVP scale.
    var imageURL: String?
    var imageData: Data?
    var imagePrompt: String?
    var imageSystemName: String?

    // Status tracking
    var status: String = SectionStatus.pending.rawValue
    var errorMessage: String?
    var createdAt: Date = Date()
    var completedAt: Date?

    // Practice prompt
    var practicePrompt: String?

    init(
        lessonID: UUID,
        orderIndex: Int,
        heading: String,
        learningObjective: String? = nil
    ) {
        self.id = UUID()
        self.lessonID = lessonID
        self.orderIndex = orderIndex
        self.heading = heading
        self.learningObjective = learningObjective
        self.status = SectionStatus.pending.rawValue
        self.createdAt = Date()
    }

    var sectionStatus: SectionStatus {
        get { SectionStatus(rawValue: status) ?? .pending }
        set { status = newValue.rawValue }
    }

    var resources: [ExternalResource] {
        get {
            guard let data = externalResourcesData else { return [] }
            return (try? JSONDecoder().decode([ExternalResource].self, from: data)) ?? []
        }
        set {
            externalResourcesData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Returns the best available content (revised if available, otherwise original)
    var displayContent: String? {
        revisedContent ?? content
    }

    /// Converts to legacy LessonSectionData for compatibility
    func toLegacySectionData() -> LessonSectionData {
        LessonSectionData(
            heading: heading,
            content: displayContent ?? "",
            imageSystemName: imageSystemName,
            practicePrompt: practicePrompt
        )
    }
}
