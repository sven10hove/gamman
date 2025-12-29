//
//  CustomLessonView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

struct CustomLessonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [UserSettings]

    @State private var prompt: String = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var networkMonitor = NetworkMonitor.shared

    private var apiKey: String? {
        // Check Keychain first, then fall back to settings
        KeychainService.getAPIKey() ?? settings.first?.apiKey
    }

    private var hasAPIKey: Bool {
        guard let key = apiKey else { return false }
        return !key.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What would you like to learn about?")
                            .font(.headline)

                        Text("Ask Claude to create a personalized lesson about any aspect of your nervous system.")
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
                        Text("Example prompts:")
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

                if !hasAPIKey {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("API Key Required", systemImage: "key.fill")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                            Text("Add your Claude API key in Settings to generate custom lessons.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !networkMonitor.isConnected {
                    Section {
                        Label("You're offline. AI features require an internet connection.", systemImage: "wifi.slash")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Create Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                GeneratingOverlay(
                    isPresented: isGenerating,
                    message: "Creating your personalized lesson..."
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        generateLesson()
                    } label: {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Text("Generate")
                        }
                    }
                    .disabled(prompt.isEmpty || isGenerating || !networkMonitor.isConnected || !hasAPIKey)
                }
            }
        }
    }

    private var examplePrompts: [String] {
        [
            "How can I use breathing exercises to calm my nervous system?",
            "What is the window of tolerance and how can I expand it?",
            "Explain how trauma affects the nervous system",
            "What are some grounding techniques for anxiety?"
        ]
    }

    private func generateLesson() {
        guard let key = apiKey, !key.isEmpty else {
            errorMessage = "Please add your API key in Settings"
            return
        }

        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let generatedContent = try await ClaudeAPIService.shared.generateLesson(
                    prompt: prompt,
                    apiKey: key
                )

                let lesson = Lesson(
                    title: generatedContent.title,
                    subtitle: generatedContent.subtitle,
                    category: "custom",
                    sections: generatedContent.toLessonSections(),
                    estimatedMinutes: max(5, generatedContent.sections.count * 3),
                    isPrebuilt: false,
                    userPrompt: prompt
                )

                await MainActor.run {
                    modelContext.insert(lesson)
                    isGenerating = false
                    HapticService.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                    HapticService.error()
                }
            }
        }
    }
}

#Preview {
    CustomLessonView()
        .modelContainer(for: Lesson.self, inMemory: true)
}
