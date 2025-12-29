//
//  LearnTabView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

struct LearnTabView: View {
    @Query private var lessons: [Lesson]
    @State private var showingCustomLesson = false

    var prebuiltLessons: [Lesson] {
        lessons.filter { $0.isPrebuilt }
    }

    var customLessons: [Lesson] {
        lessons.filter { !$0.isPrebuilt }
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
                                        LessonCard(lesson: lesson)
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
                            Text("Your Lessons")
                                .font(.headline)
                                .padding(.horizontal)

                            LazyVStack(spacing: 12) {
                                ForEach(customLessons) { lesson in
                                    NavigationLink(destination: LiveLessonDetailView(lesson: lesson)) {
                                        LessonCard(lesson: lesson)
                                    }
                                    .buttonStyle(.plain)
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
            .navigationTitle("Learn")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCustomLesson = true
                    } label: {
                        Label("Create Lesson", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCustomLesson) {
                LessonGenerationView()
            }
        }
    }
}

struct LessonCard: View {
    let lesson: Lesson

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: categoryIcon)
                    .font(.title2)
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
                    .lineLimit(2)

                HStack {
                    Label("\(lesson.estimatedMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if lesson.isGenerating {
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
                    } else if !lesson.isPrebuilt {
                        Text("AI Generated")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    var categoryColor: Color {
        switch lesson.category {
        case "basics": return .blue
        case "regulation": return .green
        case "understanding": return .orange
        default: return .purple
        }
    }

    var categoryIcon: String {
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
        .modelContainer(for: Lesson.self, inMemory: true)
}
