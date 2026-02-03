//
//  LearnTabView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct LearnTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var lessons: [Lesson]
    @Query private var lessonSections: [LessonSection]
    @State private var showingCustomLesson = false
    @State private var lessonToDelete: Lesson?

    var prebuiltLessons: [Lesson] {
        lessons.filter { $0.isPrebuilt }
    }

    var customLessons: [Lesson] {
        lessons.filter { !$0.isPrebuilt }.sorted { $0.createdDate > $1.createdDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Pre-built lessons section
                    if !prebuiltLessons.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Foundations")
                                .font(.headline)
                                .padding(.horizontal)

                            LazyVStack(spacing: 12) {
                                ForEach(prebuiltLessons) { lesson in
                                    NavigationLink(destination: LessonDetailView(lesson: lesson)) {
                                        GlassLessonCard(lesson: lesson)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Custom lessons section
                    if !customLessons.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Your Lessons")
                                    .font(.headline)
                                Spacer()
                                Text("Long press to delete")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)

                            LazyVStack(spacing: 12) {
                                ForEach(customLessons) { lesson in
                                    NavigationLink(destination: LiveLessonDetailView(lesson: lesson)) {
                                        GlassLessonCard(lesson: lesson, style: .compact)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            lessonToDelete = lesson
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Empty state
                    if lessons.isEmpty {
                        ContentUnavailableView(
                            "No Lessons Yet",
                            systemImage: "lightbulb",
                            description: Text("Lessons about your nervous system will appear here.")
                        )
                        .padding(.top, 50)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Learn")
            .glassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCustomLesson = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.appPurple)
                    }
                }
            }
            .sheet(isPresented: $showingCustomLesson) {
                LessonGenerationView()
            }
            .confirmationDialog(
                "Delete Lesson?",
                isPresented: Binding(
                    get: { lessonToDelete != nil },
                    set: { if !$0 { lessonToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let lesson = lessonToDelete {
                        deleteLesson(lesson)
                    }
                }
                Button("Cancel", role: .cancel) {
                    lessonToDelete = nil
                }
            } message: {
                Text("This will permanently delete this lesson and all its sections.")
            }
        }
    }

    private func deleteLesson(_ lesson: Lesson) {
        // Delete associated sections first
        let lessonID = lesson.id
        let sectionsToDelete = lessonSections.filter { $0.lessonID == lessonID }
        for section in sectionsToDelete {
            modelContext.delete(section)
        }

        // Delete the lesson
        modelContext.delete(lesson)

        try? modelContext.save()
        HapticService.impact(.medium)
        lessonToDelete = nil
    }
}

// MARK: - Glass Lesson Card

@available(iOS 17.0, *)
struct GlassLessonCard: View {
    let lesson: Lesson
    var style: CardStyle = .standard

    enum CardStyle {
        case standard
        case compact
    }

    private var iconSize: CGFloat { style == .standard ? 56 : 48 }
    private var cornerRadius: CGFloat { style == .standard ? 16 : 14 }

    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius - 4)
                    .fill(categoryGradient)
                    .frame(width: iconSize, height: iconSize)

                Image(systemName: categoryIcon)
                    .font(style == .standard ? .title2 : .title3)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(lesson.title)
                        .font(.headline)
                        .lineLimit(1)

                    if lesson.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }

                Text(lesson.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(style == .standard ? 2 : 1)

                HStack(spacing: 8) {
                    Label("\(lesson.estimatedMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if lesson.isGenerating {
                        HStack(spacing: 4) {
                            GlassLoadingSpinner(size: 12, lineWidth: 1.5)
                            Text("Generating...")
                        }
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Capsule())
                    } else if !lesson.isPrebuilt {
                        Text("AI Generated")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(LinearGradient.blended.opacity(0.3))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .padding(style == .standard ? 16 : 12)
        .glassCard(cornerRadius: cornerRadius)
    }

    private var categoryGradient: LinearGradient {
        switch lesson.category {
        case "basics": return .dorsalVagal
        case "regulation": return .ventral
        case "understanding": return .sympathetic
        default: return .blended
        }
    }

    private var categoryIcon: String {
        switch lesson.category {
        case "basics": return "book.fill"
        case "regulation": return "heart.fill"
        case "understanding": return "brain.head.profile"
        default: return "sparkles"
        }
    }
}

// MARK: - Legacy Lesson Card (kept for compatibility)

@available(iOS 17.0, *)
struct LessonCard: View {
    let lesson: Lesson
    var style: CardStyle = .standard

    enum CardStyle {
        case standard
        case compact
    }

    private var iconSize: CGFloat { style == .standard ? 60 : 50 }
    private var cornerRadius: CGFloat { style == .standard ? 12 : 10 }
    private var iconFont: Font { style == .standard ? .title2 : .title3 }
    private var spacing: CGFloat { style == .standard ? 16 : 12 }
    private var subtitleLineLimit: Int { style == .standard ? 2 : 1 }

    var body: some View {
        HStack(spacing: spacing) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: iconSize, height: iconSize)

                Image(systemName: categoryIcon)
                    .font(iconFont)
                    .foregroundStyle(categoryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(lesson.title)
                        .font(.headline)
                        .lineLimit(1)

                    if lesson.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }

                Text(lesson.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(subtitleLineLimit)

                HStack {
                    Label("\(lesson.estimatedMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if lesson.isGenerating {
                        generatingBadge
                    } else if !lesson.isPrebuilt {
                        aiGeneratedBadge
                    }
                }
            }

            Spacer()

            if style == .standard {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(style == .standard ? .all : .vertical, style == .standard ? 16 : 4)
        .background(style == .standard ? Color(.systemBackground) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: style == .standard ? 16 : 0))
        .shadow(color: style == .standard ? .black.opacity(0.05) : .clear, radius: 5, y: 2)
    }

    private var generatingBadge: some View {
        HStack(spacing: 4) {
            ProgressView()
                .scaleEffect(0.6)
            Text("Generating...")
        }
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.2))
        .clipShape(Capsule())
    }

    private var aiGeneratedBadge: some View {
        Text("AI Generated")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.purple.opacity(0.2))
            .clipShape(Capsule())
    }

    private var categoryColor: Color {
        switch lesson.category {
        case "basics": return .blue
        case "regulation": return .green
        case "understanding": return .orange
        default: return .purple
        }
    }

    private var categoryIcon: String {
        switch lesson.category {
        case "basics": return "book.fill"
        case "regulation": return "heart.fill"
        case "understanding": return "brain.head.profile"
        default: return "sparkles"
        }
    }
}

#Preview {
    LearnTabView()
        .modelContainer(for: [Lesson.self, LessonSection.self], inMemory: true)
}
