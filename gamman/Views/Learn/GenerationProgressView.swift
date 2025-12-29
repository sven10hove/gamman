//
//  GenerationProgressView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

struct GenerationProgressView: View {
    @Bindable var service: LessonGeneratorService
    let onStartReading: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overall progress
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 120, height: 120)

                        Circle()
                            .trim(from: 0, to: service.overallProgress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: service.overallProgress)

                        Text("\(Int(service.overallProgress * 100))%")
                            .font(.title)
                            .fontWeight(.bold)
                    }

                    Text(service.currentTask)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut, value: service.currentTask)
                }
                .padding(.top, 32)

                // Section status list
                if let lesson = service.currentLesson {
                    SectionStatusList(
                        lessonID: lesson.id,
                        sectionProgress: service.sectionProgress
                    )
                }

                // Start reading button
                if let lesson = service.currentLesson, lesson.completedSections > 0 {
                    Button {
                        HapticService.impact(.medium)
                        onStartReading()
                    } label: {
                        Label(
                            lesson.completedSections == lesson.totalSections
                                ? "View Lesson"
                                : "Start Reading (\(lesson.completedSections)/\(lesson.totalSections) ready)",
                            systemImage: "book.fill"
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }

                // Error list
                if !service.errors.isEmpty {
                    ErrorListView(errors: service.errors)
                        .padding(.horizontal)
                }

                Spacer(minLength: 50)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

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
            Text("Lesson Sections")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ForEach(sections) { section in
                SectionStatusRow(
                    section: section,
                    status: sectionProgress[section.id] ?? section.sectionStatus
                )
            }
        }
        .padding(.horizontal)
    }
}

struct SectionStatusRow: View {
    let section: LessonSection
    let status: SectionStatus

    var body: some View {
        HStack(spacing: 12) {
            statusIcon
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(section.heading)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if status == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.3), value: status)
    }

    @ViewBuilder
    var statusIcon: some View {
        switch status {
        case .pending:
            Image(systemName: "circle")
                .foregroundStyle(.gray)
        case .writing:
            ProgressView()
                .scaleEffect(0.8)
        case .factChecking:
            Image(systemName: "checkmark.shield")
                .foregroundStyle(.orange)
                .symbolEffect(.pulse)
        case .curating:
            Image(systemName: "link")
                .foregroundStyle(.purple)
                .symbolEffect(.pulse)
        case .illustrating:
            Image(systemName: "photo.artframe")
                .foregroundStyle(.pink)
                .symbolEffect(.pulse)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    var statusText: String {
        switch status {
        case .pending:
            return "Waiting..."
        case .writing:
            return "Writing content..."
        case .factChecking:
            return "Fact-checking..."
        case .curating:
            return "Finding resources..."
        case .illustrating:
            return "Creating illustration..."
        case .completed:
            return "Ready to read"
        case .failed:
            return section.errorMessage ?? "Failed"
        }
    }
}

struct ErrorListView: View {
    let errors: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Issues", systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(.orange)

            ForEach(errors, id: \.self) { error in
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    GenerationProgressView(
        service: LessonGeneratorService.shared,
        onStartReading: {}
    )
}
