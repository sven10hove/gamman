//
//  LiveLessonDetailView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

struct LiveLessonDetailView: View {
    @Bindable var lesson: Lesson
    @Query private var allSections: [LessonSection]
    @State private var currentSectionIndex = 0

    private var sections: [LessonSection] {
        allSections
            .filter { $0.lessonID == lesson.id && $0.sectionStatus == .completed }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    init(lesson: Lesson) {
        self.lesson = lesson
        let lessonID = lesson.id
        self._allSections = Query(
            filter: #Predicate<LessonSection> { $0.lessonID == lessonID }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            progressHeader

            // Section content
            if sections.isEmpty {
                EmptyStateView(
                    icon: "hourglass",
                    title: "Generating...",
                    description: "Your lesson is being created. Sections will appear here as they complete."
                )
            } else {
                TabView(selection: $currentSectionIndex) {
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        LiveSectionView(section: section)
                            .tag(index)
                    }

                    // "More coming" placeholder
                    if lesson.isGenerating && sections.count < lesson.totalSections {
                        MoreSectionsLoadingView(
                            remaining: lesson.totalSections - sections.count
                        )
                        .tag(sections.count)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentSectionIndex) { _, _ in
                    HapticService.selection()
                }
            }

            // Navigation bar
            if !sections.isEmpty {
                navigationBar
            }
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                if lesson.isGenerating {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Generating...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Section \(currentSectionIndex + 1) of \(sections.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if lesson.isGenerating {
                    Text("\(lesson.completedSections)/\(lesson.totalSections) ready")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            ProgressView(
                value: Double(currentSectionIndex + 1),
                total: Double(max(sections.count, 1))
            )
            .tint(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var navigationBar: some View {
        HStack {
            Button {
                withAnimation {
                    currentSectionIndex = max(0, currentSectionIndex - 1)
                }
                HapticService.impact(.light)
            } label: {
                Label("Previous", systemImage: "chevron.left")
            }
            .disabled(currentSectionIndex == 0)

            Spacer()

            if currentSectionIndex == sections.count - 1 && !lesson.isGenerating {
                Button {
                    lesson.isCompleted = true
                    lesson.completedDate = Date()
                    HapticService.success()
                } label: {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    withAnimation {
                        currentSectionIndex = min(sections.count - 1, currentSectionIndex + 1)
                    }
                    HapticService.impact(.light)
                } label: {
                    Label("Next", systemImage: "chevron.right")
                }
                .disabled(currentSectionIndex >= sections.count - 1)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct LiveSectionView: View {
    let section: LessonSection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with image
                sectionHeader

                // Content
                Text(section.displayContent ?? "")
                    .font(.body)
                    .lineSpacing(6)

                // Practice prompt
                if let practicePrompt = section.practicePrompt {
                    PracticePromptCard(prompt: practicePrompt)
                }

                // External resources
                if !section.resources.isEmpty {
                    ResourcesSection(resources: section.resources)
                }

                // Fact-check notes (collapsible)
                if let notes = section.factCheckNotes, !notes.isEmpty {
                    FactCheckNotesView(notes: notes)
                }

                Spacer(minLength: 100)
            }
            .padding()
        }
    }

    private var sectionHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            // Image or fallback icon
            if let imageData = section.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let systemName = section.imageSystemName {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: systemName)
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(section.heading)
                    .font(.title2)
                    .fontWeight(.bold)

                if let objective = section.learningObjective {
                    Text(objective)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct PracticePromptCard: View {
    let prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Practice", systemImage: "sparkles")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)

            Text(prompt)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ResourcesSection: View {
    let resources: [ExternalResource]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Learn More", systemImage: "link")
                .font(.headline)

            ForEach(resources) { resource in
                if let url = URL(string: resource.url) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: resource.resourceType.systemImage)
                                .foregroundStyle(.blue)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(resource.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)

                                if let snippet = resource.snippet {
                                    Text(snippet)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(.top)
    }
}

struct FactCheckNotesView: View {
    let notes: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Label("Fact-Check Notes", systemImage: "checkmark.shield")
                        .font(.caption)
                        .foregroundStyle(.green)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MoreSectionsLoadingView: View {
    let remaining: Int

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Generating \(remaining) more section\(remaining == 1 ? "" : "s")...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("You can continue reading while we prepare the rest of your lesson.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        LiveLessonDetailView(
            lesson: Lesson(
                title: "Understanding Your Nervous System",
                subtitle: "Learn about polyvagal theory",
                userPrompt: "test",
                totalSections: 4
            )
        )
    }
    .modelContainer(for: [Lesson.self, LessonSection.self], inMemory: true)
}
