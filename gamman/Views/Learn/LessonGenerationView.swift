//
//  LessonGenerationView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

struct LessonGenerationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [UserSettings]

    @State private var prompt: String = ""
    @State private var navigateToLesson = false

    var generatorService = LessonGeneratorService.shared
    var networkMonitor = NetworkMonitor.shared

    private var apiKey: String? {
        KeychainService.getAPIKey() ?? settings.first?.apiKey
    }

    private var hasAPIKey: Bool {
        guard let key = apiKey else { return false }
        return !key.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if generatorService.isGenerating {
                    GenerationProgressView(
                        service: generatorService,
                        onStartReading: {
                            navigateToLesson = true
                        }
                    )
                } else {
                    promptInputForm
                }
            }
            .navigationTitle(generatorService.isGenerating ? "Creating Lesson" : "New Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !generatorService.isGenerating {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }

                if !generatorService.isGenerating {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Generate") {
                            startGeneration()
                        }
                        .fontWeight(.semibold)
                        .disabled(prompt.isEmpty || !networkMonitor.isConnected || !hasAPIKey)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToLesson) {
                if let lesson = generatorService.currentLesson {
                    LiveLessonDetailView(lesson: lesson)
                        .onDisappear {
                            if !generatorService.isGenerating {
                                generatorService.reset()
                                dismiss()
                            }
                        }
                }
            }
        }
    }

    private var promptInputForm: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What would you like to learn about?")
                        .font(.headline)

                    Text("Our AI team will create a comprehensive, fact-checked lesson with resources and illustrations.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $prompt)
                        .frame(minHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3))
                        )
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Example topics:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(examplePrompts, id: \.self) { example in
                        Button {
                            prompt = example
                        } label: {
                            Text(example)
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                    }
                }
            }

            Section {
                agentInfoView
            }

            if !hasAPIKey {
                Section {
                    Label("Add API key in Settings", systemImage: "key.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }

            if !networkMonitor.isConnected {
                Section {
                    Label("You're offline", systemImage: "wifi.slash")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var agentInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Powered by AI Agents")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                AgentBadge(icon: "pencil.and.outline", name: "Architect", color: .blue)
                AgentBadge(icon: "text.quote", name: "Writer", color: .green)
                AgentBadge(icon: "checkmark.shield", name: "Fact Checker", color: .orange)
            }

            HStack(spacing: 16) {
                AgentBadge(icon: "link", name: "Curator", color: .purple)
                AgentBadge(icon: "photo.artframe", name: "Illustrator", color: .pink)
            }
        }
    }

    private var examplePrompts: [String] {
        [
            "How can I use breathing exercises to calm my nervous system?",
            "What is the window of tolerance and how can I expand it?",
            "Explain how trauma affects the nervous system",
            "What are some grounding techniques for anxiety?",
            "How does co-regulation work in relationships?"
        ]
    }

    private func startGeneration() {
        guard let key = apiKey, !key.isEmpty else { return }

        HapticService.impact(.medium)

        let config = AgentConfiguration(
            claudeAPIKey: key,
            exaAPIKey: KeychainService.getExaAPIKey(),
            imageAPIKey: KeychainService.getOpenAIAPIKey(),
            isConnected: networkMonitor.isConnected
        )

        Task {
            await generatorService.generateLesson(
                prompt: prompt,
                configuration: config,
                modelContext: modelContext
            )
        }
    }
}

struct AgentBadge: View {
    let icon: String
    let name: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    LessonGenerationView()
        .modelContainer(for: [Lesson.self, LessonSection.self, UserSettings.self], inMemory: true)
}
