//
//  LessonContentProvider.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation
import SwiftData
import os

@available(iOS 17.0, *)
struct BundledLesson: Codable {
    let id: String
    let title: String
    let subtitle: String
    let category: String
    let estimatedMinutes: Int
    let sections: [LessonSectionData]
}

@MainActor
@available(iOS 17.0, *)
class LessonContentProvider {
    static let shared = LessonContentProvider()

    private let lessonFiles = [
        "lesson_polyvagal_basics",
        "lesson_fight_flight_freeze",
        "lesson_vagal_tone",
        "lesson_window_of_tolerance",
        "lesson_coregulation"
    ]

    /// Validates that all expected lesson files exist in the bundle
    func validateLessonFiles() -> [String] {
        var missingFiles: [String] = []

        for filename in lessonFiles {
            if Bundle.main.url(forResource: filename, withExtension: "json") == nil {
                missingFiles.append(filename)
                AppLogger.lessons.logWarning("Missing lesson file: \(filename).json")
            }
        }

        if missingFiles.isEmpty {
            AppLogger.lessons.info("All \(self.lessonFiles.count) lesson files validated successfully")
        } else {
            AppLogger.lessons.logError("Missing \(missingFiles.count) lesson files")
        }

        return missingFiles
    }

    func loadPrebuiltLessons(into context: ModelContext) {
        // Validate lesson files first
        let missingFiles = validateLessonFiles()
        if !missingFiles.isEmpty {
            AppLogger.lessons.logWarning("Some lesson files are missing, loading available lessons only")
        }

        // Check if lessons already exist
        let descriptor = FetchDescriptor<Lesson>(predicate: #Predicate { $0.isPrebuilt == true })
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        if existingCount > 0 {
            AppLogger.lessons.debug("Pre-built lessons already loaded (\(existingCount) found)")
            return
        }

        // Load lessons from JSON files
        var loadedCount = 0
        for filename in lessonFiles {
            if let lesson = loadLesson(from: filename) {
                context.insert(lesson)
                loadedCount += 1
            }
        }

        do {
            try context.save()
            AppLogger.lessons.info("Loaded \(loadedCount) pre-built lessons")
        } catch {
            AppLogger.lessons.logError("Failed to save pre-built lessons", error: error)
        }
    }

    private func loadLesson(from filename: String) -> Lesson? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            AppLogger.lessons.logWarning("Lesson file not found: \(filename).json")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let bundled = try JSONDecoder().decode(BundledLesson.self, from: data)

            AppLogger.lessons.debug("Loaded lesson: \(bundled.title) with \(bundled.sections.count) sections")

            return Lesson(
                title: bundled.title,
                subtitle: bundled.subtitle,
                category: bundled.category,
                sections: bundled.sections,
                estimatedMinutes: bundled.estimatedMinutes,
                isPrebuilt: true
            )
        } catch {
            AppLogger.lessons.logError("Failed to decode lesson: \(filename)", error: error)
            return nil
        }
    }
}
