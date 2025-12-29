//
//  LessonContentProvider.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation
import SwiftData

struct BundledLesson: Codable {
    let id: String
    let title: String
    let subtitle: String
    let category: String
    let estimatedMinutes: Int
    let sections: [LessonSectionData]
}

@MainActor
class LessonContentProvider {
    static let shared = LessonContentProvider()

    private let lessonFiles = [
        "lesson_polyvagal_basics",
        "lesson_fight_flight_freeze",
        "lesson_vagal_tone",
        "lesson_window_of_tolerance",
        "lesson_coregulation"
    ]

    func loadPrebuiltLessons(into context: ModelContext) {
        // Check if lessons already exist
        let descriptor = FetchDescriptor<Lesson>(predicate: #Predicate { $0.isPrebuilt == true })
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        if existingCount > 0 {
            return // Lessons already loaded
        }

        // Load lessons from JSON files
        for filename in lessonFiles {
            if let lesson = loadLesson(from: filename) {
                context.insert(lesson)
            }
        }

        try? context.save()
    }

    private func loadLesson(from filename: String) -> Lesson? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bundled = try? JSONDecoder().decode(BundledLesson.self, from: data) else {
            print("Failed to load lesson: \(filename)")
            return nil
        }

        return Lesson(
            title: bundled.title,
            subtitle: bundled.subtitle,
            category: bundled.category,
            sections: bundled.sections,
            estimatedMinutes: bundled.estimatedMinutes,
            isPrebuilt: true
        )
    }
}
