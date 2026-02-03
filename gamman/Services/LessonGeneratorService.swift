//
//  LessonGeneratorService.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation
import SwiftData
import Observation
import UIKit
import os

@Observable
@MainActor
@available(iOS 17.0, *)
final class LessonGeneratorService {
    static let shared = LessonGeneratorService()

    // Progress tracking (observable for UI)
    var currentLesson: Lesson?
    var currentTask: String = ""
    var overallProgress: Double = 0
    var sectionProgress: [UUID: SectionStatus] = [:]
    var errors: [String] = []
    var isGenerating: Bool = false

    // Agents
    private let architectAgent = ArchitectAgent.shared
    private let writerAgent = WriterAgent.shared
    private let factCheckerAgent = FactCheckerAgent.shared
    private let curatorAgent = CuratorAgent.shared
    private let illustratorAgent = IllustratorAgent.shared

    private init() {}

    func generateLesson(
        prompt: String,
        configuration: AgentConfiguration,
        modelContext: ModelContext
    ) async {
        guard configuration.isConnected else {
            errors.append("No internet connection")
            return
        }

        guard configuration.usesProxy || !configuration.claudeAPIKey.isEmpty else {
            errors.append("AI service is not configured")
            return
        }

        isGenerating = true
        errors = []
        sectionProgress = [:]
        currentTask = "Designing lesson structure..."
        overallProgress = 0

        do {
            // Phase 1: Architecture
            let outline = try await architectAgent.execute(
                prompt: prompt,
                apiKey: configuration.claudeAPIKey,
                isConnected: configuration.isConnected
            )

            // Create lesson and sections in SwiftData
            let lesson = Lesson(
                title: outline.title,
                subtitle: outline.subtitle,
                userPrompt: prompt,
                totalSections: outline.sections.count
            )
            modelContext.insert(lesson)
            currentLesson = lesson

            var sections: [LessonSection] = []
            for (index, sectionOutline) in outline.sections.enumerated() {
                let section = LessonSection(
                    lessonID: lesson.id,
                    orderIndex: index,
                    heading: sectionOutline.heading,
                    learningObjective: sectionOutline.learningObjective
                )
                modelContext.insert(section)
                sections.append(section)
                sectionProgress[section.id] = .pending
            }

            try modelContext.save()
            overallProgress = 0.1  // Architecture complete

            // Phase 2: Process sections in parallel
            currentTask = "Generating content..."
            await processSectionsInParallel(
                sections: sections,
                outline: outline,
                configuration: configuration,
                context: modelContext
            )

            // Finalize
            let hasErrors = !errors.isEmpty
            lesson.lessonGenerationStatus = hasErrors ? .partialFailure : .completed
            lesson.generationCompletedAt = Date()

            // Update legacy sectionsData for compatibility
            let completedSections = sections.filter { $0.sectionStatus == .completed }
            lesson.sections = completedSections.map { $0.toLegacySectionData() }

            try modelContext.save()

            currentTask = ""
            overallProgress = 1.0
            HapticService.success()

        } catch {
            errors.append(error.localizedDescription)
            currentLesson?.lessonGenerationStatus = .failed
            saveContext(modelContext, operation: "generation failed")
            HapticService.error()
        }

        isGenerating = false
    }

    private func processSectionsInParallel(
        sections: [LessonSection],
        outline: LessonOutline,
        configuration: AgentConfiguration,
        context: ModelContext
    ) async {
        // Capture values needed for child tasks before entering TaskGroup
        let lessonTitle = outline.title

        await withTaskGroup(of: Void.self) { group in
            for (index, section) in sections.enumerated() {
                let sectionOutline = outline.sections[index]
                let previousContent = index > 0 ? sections[index - 1].displayContent : nil

                group.addTask {
                    await self.processSingleSection(
                        section: section,
                        sectionOutline: sectionOutline,
                        lessonContext: lessonTitle,
                        previousSummary: previousContent,
                        configuration: configuration,
                        context: context
                    )
                }
            }
        }
    }

    private func processSingleSection(
        section: LessonSection,
        sectionOutline: LessonOutline.SectionOutline,
        lessonContext: String,
        previousSummary: String?,
        configuration: AgentConfiguration,
        context: ModelContext
    ) async {
        let sectionId = section.id
        let claudeKey = configuration.claudeAPIKey
        let exaKey = configuration.exaAPIKey
        let imageKey = configuration.imageAPIKey
        let isConnected = configuration.isConnected

        do {
            // Step 1: Write content
            await MainActor.run {
                section.sectionStatus = .writing
                sectionProgress[sectionId] = .writing
                currentTask = "Writing: \(section.heading)..."
                saveContext(context, operation: "writing status")
            }

            let writerInput = WriterInput(
                sectionOutline: sectionOutline,
                lessonContext: lessonContext,
                previousSectionSummary: previousSummary
            )

            let written = try await writerAgent.execute(
                input: writerInput,
                apiKey: claudeKey,
                isConnected: isConnected
            )

            await MainActor.run {
                section.content = written.content
                section.practicePrompt = written.practicePrompt
                saveContext(context, operation: "content")
            }

            // Step 2: Fact check
            await MainActor.run {
                section.sectionStatus = .factChecking
                sectionProgress[sectionId] = .factChecking
                currentTask = "Fact-checking: \(section.heading)..."
            }

            let factCheckInput = FactCheckerInput(
                originalContent: written.content,
                sectionHeading: section.heading,
                learningObjective: section.learningObjective ?? ""
            )

            let factChecked = try await factCheckerAgent.execute(
                input: factCheckInput,
                apiKey: claudeKey,
                isConnected: isConnected
            )

            await MainActor.run {
                section.revisedContent = factChecked.revisedContent
                section.factCheckNotes = factChecked.corrections.isEmpty
                    ? nil
                    : factChecked.corrections.joined(separator: "; ")
                saveContext(context, operation: "fact-check")
            }

            // Step 3: Curate and Illustrate in parallel
            await MainActor.run {
                section.sectionStatus = .curating
                sectionProgress[sectionId] = .curating
                currentTask = "Finding resources: \(section.heading)..."
            }

            async let resourcesTask = curateResources(
                section: section,
                lessonContext: lessonContext,
                exaKey: exaKey,
                isConnected: isConnected
            )

            async let illustrationTask = generateIllustration(
                section: section,
                sectionOutline: sectionOutline,
                imageKey: imageKey,
                isConnected: isConnected
            )

            let (resources, illustration) = await (resourcesTask, illustrationTask)

            // Save final results
            await MainActor.run {
                if let resources = resources {
                    section.resources = resources
                }

                section.imageURL = illustration.imageURL
                section.imageData = illustration.imageData
                section.imagePrompt = illustration.prompt
                section.imageSystemName = illustration.fallbackSystemImage

                section.sectionStatus = .completed
                section.completedAt = Date()
                sectionProgress[sectionId] = .completed

                if let lesson = currentLesson {
                    lesson.completedSections += 1
                    overallProgress = 0.1 + (0.9 * lesson.generationProgress)
                }

                saveContext(context, operation: "section complete")
                HapticService.impact(.light)
            }

        } catch {
            await MainActor.run {
                section.sectionStatus = .failed
                section.errorMessage = error.localizedDescription
                sectionProgress[sectionId] = .failed
                errors.append("Section '\(section.heading)': \(error.localizedDescription)")
                saveContext(context, operation: "section error")
            }
        }
    }

    private func curateResources(
        section: LessonSection,
        lessonContext: String,
        exaKey: String?,
        isConnected: Bool
    ) async -> [ExternalResource]? {
        let key = exaKey ?? ""
        guard APIAccess.usesProxy || !key.isEmpty else { return nil }

        let input = CuratorInput(
            sectionContent: section.displayContent ?? "",
            sectionHeading: section.heading,
            lessonTopic: lessonContext
        )

        do {
            return try await curatorAgent.execute(
                input: input,
                apiKey: key,
                isConnected: isConnected
            )
        } catch {
            // Non-critical failure - continue without resources
            return nil
        }
    }

    private func generateIllustration(
        section: LessonSection,
        sectionOutline: LessonOutline.SectionOutline,
        imageKey: String?,
        isConnected: Bool
    ) async -> IllustratorOutput {
        let input = IllustratorInput(
            sectionHeading: section.heading,
            sectionContent: section.displayContent ?? "",
            suggestedConcept: sectionOutline.suggestedImageConcept
        )

        do {
            return try await illustratorAgent.execute(
                input: input,
                apiKey: imageKey ?? "",
                isConnected: isConnected
            )
        } catch {
            // Return fallback - illustrator handles this gracefully
            return IllustratorOutput(
                imageURL: nil,
                imageData: nil,
                prompt: "",
                fallbackSystemImage: "sparkles"
            )
        }
    }

    func reset() {
        currentLesson = nil
        currentTask = ""
        overallProgress = 0
        sectionProgress = [:]
        errors = []
        isGenerating = false
    }

    /// Safely saves the context, logging any errors
    private func saveContext(_ context: ModelContext, operation: String) {
        do {
            try context.save()
        } catch {
            let errorMessage = "Save failed (\(operation)): \(error.localizedDescription)"
            errors.append(errorMessage)
            AppLogger.database.logError(errorMessage, error: error)
        }
    }
}
