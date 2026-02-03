//
//  LessonDetailView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

@available(iOS 17.0, *)
struct LessonDetailView: View {
    @Bindable var lesson: Lesson
    @State private var currentSection = 0

    var sections: [LessonSectionData] {
        lesson.sections
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressView(value: Double(currentSection + 1), total: Double(max(sections.count, 1)))
                .tint(.blue)
                .padding()

            // Content
            TabView(selection: $currentSection) {
                ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Section header
                            HStack {
                                if let imageName = section.imageSystemName {
                                    Image(systemName: imageName)
                                        .font(.largeTitle)
                                        .foregroundStyle(.blue)
                                }

                                Text(section.heading)
                                    .font(.title2)
                                    .bold()
                            }

                            // Content
                            Text(section.content)
                                .font(.body)
                                .lineSpacing(6)

                            // Practice prompt
                            if let prompt = section.practicePrompt {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Reflection", systemImage: "pencil.and.outline")
                                        .font(.headline)
                                        .foregroundStyle(.orange)

                                    Text(prompt)
                                        .font(.body)
                                        .italic()
                                        .padding()
                                        .background(Color.orange.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .padding(.top)
                            }

                            Spacer()
                        }
                        .padding()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Navigation buttons
            HStack {
                Button {
                    withAnimation {
                        currentSection = max(0, currentSection - 1)
                    }
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                }
                .disabled(currentSection == 0)

                Spacer()

                Text("\(currentSection + 1) / \(sections.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if currentSection < sections.count - 1 {
                    Button {
                        withAnimation {
                            currentSection += 1
                        }
                    } label: {
                        Label("Next", systemImage: "chevron.right")
                            .labelStyle(.titleAndIcon)
                    }
                } else {
                    Button {
                        markAsCompleted()
                    } label: {
                        Label(lesson.isCompleted ? "Completed" : "Complete", systemImage: "checkmark.circle.fill")
                    }
                    .disabled(lesson.isCompleted)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func markAsCompleted() {
        lesson.isCompleted = true
        lesson.completedDate = Date()
    }
}

#Preview {
    NavigationStack {
        LessonDetailView(lesson: Lesson(
            title: "Introduction to Polyvagal Theory",
            subtitle: "Understanding your nervous system",
            category: "basics",
            sections: [
                LessonSectionData(
                    heading: "What is Polyvagal Theory?",
                    content: "Polyvagal Theory, developed by Dr. Stephen Porges, explains how our autonomic nervous system responds to safety and danger. It describes three distinct states that govern our responses to the world around us.",
                    imageSystemName: "brain.head.profile",
                    practicePrompt: "Think about a time when you felt completely safe. What did that feel like in your body?"
                ),
                LessonSectionData(
                    heading: "The Three States",
                    content: "Our nervous system operates in three main states: Ventral Vagal (safe and social), Sympathetic (fight or flight), and Dorsal Vagal (freeze or shutdown). Understanding these states helps us navigate our daily experiences.",
                    imageSystemName: "circle.hexagongrid.fill",
                    practicePrompt: nil
                )
            ],
            estimatedMinutes: 10
        ))
    }
}
