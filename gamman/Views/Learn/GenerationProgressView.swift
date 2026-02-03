//
//  GenerationProgressView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct GenerationProgressView: View {
    @Bindable var service: LessonGeneratorService
    let onStartReading: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Progress ring
                progressRing
                    .padding(.top, 40)

                // Section status
                if let lesson = service.currentLesson {
                    SectionStatusList(
                        lessonID: lesson.id,
                        sectionProgress: service.sectionProgress
                    )
                }

                // Start reading button
                if let lesson = service.currentLesson, lesson.completedSections > 0 {
                    startReadingButton(lesson: lesson)
                }

                // Errors
                if !service.errors.isEmpty {
                    GlassErrorList(errors: service.errors)
                        .padding(.horizontal)
                }

                Spacer(minLength: 50)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 10)
                    .frame(width: 140, height: 140)

                // Progress ring
                Circle()
                    .trim(from: 0, to: service.overallProgress)
                    .stroke(
                        LinearGradient.purpleBlueRecap,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: service.overallProgress)

                // Center content
                VStack(spacing: 4) {
                    Text("\(Int(service.overallProgress * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient.purpleBlueRecap)

                    if service.overallProgress < 1.0 {
                        GlassLoadingSpinner(size: 16, lineWidth: 2)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            // Current task
            Text(service.currentTask)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .animation(.easeInOut, value: service.currentTask)
        }
    }

    // MARK: - Start Reading Button

    private func startReadingButton(lesson: Lesson) -> some View {
        Button {
            HapticService.impact(.medium)
            onStartReading()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "book.fill")

                Text(lesson.completedSections == lesson.totalSections
                     ? "View Lesson"
                     : "Start Reading")

                if lesson.completedSections < lesson.totalSections {
                    Text("(\(lesson.completedSections)/\(lesson.totalSections))")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(LinearGradient.purpleBlueRecap)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.appPurple.opacity(0.3), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

// MARK: - Section Status List

@available(iOS 17.0, *)
struct SectionStatusList: View {
    let lessonID: UUID
    let sectionProgress: [UUID: SectionStatus]

    @Query private var sections: [LessonSection]

    init(lessonID: UUID, sectionProgress: [UUID: SectionStatus]) {
        self.lessonID = lessonID
        self.sectionProgress = sectionProgress
        self._sections = Query(
            filter: #Predicate<LessonSection> { section in
                section.lessonID == lessonID
            },
            sort: \.orderIndex
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Sections")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(completedCount)/\(sections.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(sections) { section in
                    GlassSectionRow(
                        section: section,
                        status: sectionProgress[section.id] ?? section.sectionStatus
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private var completedCount: Int {
        sections.filter { sectionProgress[$0.id] == .completed || $0.sectionStatus == .completed }.count
    }
}

// MARK: - Glass Section Row

@available(iOS 17.0, *)
struct GlassSectionRow: View {
    let section: LessonSection
    let status: SectionStatus

    var body: some View {
        HStack(spacing: 14) {
            // Status indicator
            statusIndicator
                .frame(width: 36, height: 36)

            // Section info
            VStack(alignment: .leading, spacing: 2) {
                Text(section.heading)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }

            Spacer()

            // Completion checkmark
            if status == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 14, tint: status == .completed ? .green : .clear)
        .animation(.easeInOut(duration: 0.3), value: status)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.15))

            switch status {
            case .pending:
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 20, height: 20)

            case .writing, .factChecking, .curating, .illustrating:
                GlassLoadingSpinner(size: 20, lineWidth: 2)

            case .completed:
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundStyle(.green)

            case .failed:
                Image(systemName: "exclamationmark")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            }
        }
    }

    private var statusText: String {
        switch status {
        case .pending: return "Waiting"
        case .writing: return "Writing..."
        case .factChecking: return "Verifying..."
        case .curating: return "Finding resources..."
        case .illustrating: return "Creating image..."
        case .completed: return "Ready"
        case .failed: return section.errorMessage ?? "Failed"
        }
    }

    private var statusColor: Color {
        switch status {
        case .pending: return .gray
        case .writing, .factChecking, .curating, .illustrating: return Color.appPurple
        case .completed: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Glass Error List

@available(iOS 17.0, *)
struct GlassErrorList: View {
    let errors: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                Text("Issues")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            ForEach(errors, id: \.self) { error in
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard(cornerRadius: 14, tint: .orange)
    }
}

#Preview {
    GenerationProgressView(
        service: LessonGeneratorService.shared,
        onStartReading: {}
    )
}
