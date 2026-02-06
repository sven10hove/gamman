//
//  LessonGenerationView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct LessonGenerationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var prompt: String = ""
    @State private var navigateToLesson = false
    @State private var showingErrorAlert = false
    @State private var shouldAutoNavigateToLesson = false
    @State private var generationTask: Task<Void, Never>?

    var generatorService = LessonGeneratorService.shared
    var networkMonitor = NetworkMonitor.shared

    private var hasAPIKey: Bool {
        APIAccess.hasClaudeAccess
    }

    private var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        networkMonitor.isConnected &&
        hasAPIKey
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if generatorService.isGenerating {
                    GenerationProgressView(
                        service: generatorService,
                        onStartReading: {
                            navigateToLesson = true
                        }
                    )
                } else {
                    promptInputView
                }
            }
            .navigationTitle(generatorService.isGenerating ? "Creating Lesson" : "New Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .glassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if generatorService.isGenerating {
                        Button("Stop") {
                            stopGeneration()
                        }
                        .foregroundStyle(.red)
                    } else {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }

                if !generatorService.isGenerating {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            startGeneration()
                        } label: {
                            Text("Create")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(LiquidPrimaryButtonStyle(cornerRadius: 999, horizontalPadding: 16, verticalPadding: 8))
                        .disabled(!canGenerate)
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
            .alert("Generation Issue", isPresented: $showingErrorAlert) {
                Button("OK") {
                    showingErrorAlert = false
                }
            } message: {
                Text(generatorService.errors.joined(separator: "\n"))
            }
            .onChange(of: generatorService.errors) { _, newErrors in
                if !newErrors.isEmpty && !generatorService.isGenerating {
                    if newErrors.count == 1, newErrors[0] == "Lesson generation was stopped" {
                        return
                    }
                    showingErrorAlert = true
                }
            }
            .onChange(of: generatorService.isGenerating) { wasGenerating, isGenerating in
                if !isGenerating {
                    generationTask = nil
                }

                guard wasGenerating, !isGenerating else { return }
                defer { shouldAutoNavigateToLesson = false }

                guard shouldAutoNavigateToLesson else { return }
                guard generatorService.currentLesson != nil else { return }
                guard !navigateToLesson else { return }

                navigateToLesson = true
            }
        }
    }

    // MARK: - Prompt Input View

    private var promptInputView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(LinearGradient.purpleBlueRecap)

                    Text("What would you like to learn?")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("We'll create a personalized lesson just for you")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // Text input
                GlassTextInput(
                    text: $prompt,
                    placeholder: "e.g., How can breathing exercises calm my nervous system?",
                    characterLimit: 300,
                    minHeight: 140
                )
                .padding(.horizontal)

                // Example topics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Try these topics")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(examplePrompts, id: \.self) { example in
                                TopicChip(text: example) {
                                    HapticService.selection()
                                    prompt = example
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Status warnings
                if !hasAPIKey || !networkMonitor.isConnected {
                    VStack(spacing: 12) {
                        if !hasAPIKey {
                            StatusBanner(
                                icon: "key.fill",
                                message: "AI service unavailable",
                                color: .orange
                            )
                        }

                        if !networkMonitor.isConnected {
                            StatusBanner(
                                icon: "wifi.slash",
                                message: "You're offline",
                                color: .red
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 100)
            }
        }
    }

    private var examplePrompts: [String] {
        [
            "Breathing exercises for anxiety",
            "Window of tolerance explained",
            "How trauma affects the body",
            "Grounding techniques",
            "Co-regulation in relationships"
        ]
    }

    private func startGeneration() {
        guard APIAccess.hasClaudeAccess else { return }

        generationTask?.cancel()
        generatorService.reset()

        HapticService.impact(.medium)
        shouldAutoNavigateToLesson = true

        let config = AgentConfiguration(
            claudeAPIKey: APIAccess.claudeAPIKey ?? "",
            exaAPIKey: APIAccess.exaAPIKey,
            imageAPIKey: APIAccess.openAIAPIKey,
            usesProxy: APIAccess.usesProxy,
            isConnected: networkMonitor.isConnected
        )

        generationTask = Task {
            await generatorService.generateLesson(
                prompt: prompt,
                configuration: config,
                modelContext: modelContext
            )
        }
    }

    private func stopGeneration() {
        generatorService.cancelGeneration()
        generationTask?.cancel()
    }
}

// MARK: - Topic Chip

@available(iOS 17.0, *)
struct TopicChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassCard(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Banner

@available(iOS 17.0, *)
struct StatusBanner: View {
    let icon: String
    let message: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)

            Text(message)
                .font(.subheadline)

            Spacer()
        }
        .padding()
        .glassCard(cornerRadius: 12, tint: color)
    }
}

#Preview {
    LessonGenerationView()
        .modelContainer(for: [Lesson.self, LessonSection.self, UserSettings.self], inMemory: true)
}
