//
//  SettingsView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query private var entries: [JournalEntry]
    @Query private var insights: [UserInsight]
    @Query private var lessons: [Lesson]

    @State private var apiKey: String = ""
    @State private var exaAPIKey: String = ""
    @State private var openAIAPIKey: String = ""
    @State private var showingAPIKey = false
    @State private var showingExaKey = false
    @State private var showingOpenAIKey = false
    @State private var apiKeySaved = false
    @State private var showingResetConfirmation = false

    var currentSettings: UserSettings {
        if let existing = settings.first {
            return existing
        } else {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            return newSettings
        }
    }

    var hasStoredAPIKey: Bool {
        KeychainService.hasAPIKey
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: hasStoredAPIKey ? "checkmark.shield.fill" : "key.fill")
                                .foregroundStyle(hasStoredAPIKey ? .green : .orange)
                            Text(hasStoredAPIKey ? "API Key Configured" : "API Key Required")
                                .font(.headline)
                        }

                        if hasStoredAPIKey {
                            Text("Your Claude API key is securely stored in the iOS Keychain.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button(role: .destructive) {
                                KeychainService.deleteAPIKey()
                                currentSettings.apiKey = nil
                                apiKey = ""
                                apiKeySaved = false
                            } label: {
                                Label("Remove API Key", systemImage: "trash")
                            }
                        } else {
                            HStack {
                                if showingAPIKey {
                                    TextField("sk-ant-...", text: $apiKey)
                                        .textContentType(.password)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("sk-ant-...", text: $apiKey)
                                }

                                Button {
                                    showingAPIKey.toggle()
                                } label: {
                                    Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                                }
                            }

                            if !apiKey.isEmpty {
                                Button {
                                    saveAPIKey()
                                } label: {
                                    Label("Save API Key", systemImage: "checkmark.circle")
                                }
                                .disabled(apiKey.count < 10)
                            }

                            Link(destination: URL(string: "https://console.anthropic.com/settings/keys")!) {
                                Label("Get API key from Anthropic Console", systemImage: "arrow.up.right.square")
                            }
                            .font(.caption)
                        }
                    }
                } header: {
                    Text("Claude AI (Required)")
                } footer: {
                    Text("Required for lesson generation and insights.")
                }

                // Exa API Key Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: KeychainService.hasExaAPIKey ? "checkmark.shield.fill" : "link")
                                .foregroundStyle(KeychainService.hasExaAPIKey ? .green : .purple)
                            Text(KeychainService.hasExaAPIKey ? "Exa API Configured" : "Add Exa API Key")
                                .font(.headline)
                        }

                        if KeychainService.hasExaAPIKey {
                            Text("Exa is used to find relevant learning resources.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button(role: .destructive) {
                                KeychainService.deleteExaAPIKey()
                                exaAPIKey = ""
                            } label: {
                                Label("Remove Exa Key", systemImage: "trash")
                            }
                        } else {
                            HStack {
                                if showingExaKey {
                                    TextField("exa-...", text: $exaAPIKey)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("exa-...", text: $exaAPIKey)
                                }

                                Button {
                                    showingExaKey.toggle()
                                } label: {
                                    Image(systemName: showingExaKey ? "eye.slash" : "eye")
                                }
                            }

                            if !exaAPIKey.isEmpty {
                                Button {
                                    KeychainService.saveExaAPIKey(exaAPIKey)
                                } label: {
                                    Label("Save Exa Key", systemImage: "checkmark.circle")
                                }
                            }

                            Link(destination: URL(string: "https://exa.ai")!) {
                                Label("Get API key from Exa", systemImage: "arrow.up.right.square")
                            }
                            .font(.caption)
                        }
                    }
                } header: {
                    Text("Exa (Optional)")
                } footer: {
                    Text("Adds curated external resources to lessons.")
                }

                // OpenAI API Key Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: KeychainService.hasOpenAIAPIKey ? "checkmark.shield.fill" : "photo.artframe")
                                .foregroundStyle(KeychainService.hasOpenAIAPIKey ? .green : .pink)
                            Text(KeychainService.hasOpenAIAPIKey ? "OpenAI API Configured" : "Add OpenAI API Key")
                                .font(.headline)
                        }

                        if KeychainService.hasOpenAIAPIKey {
                            Text("OpenAI is used to generate lesson illustrations with DALL-E.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button(role: .destructive) {
                                KeychainService.deleteOpenAIAPIKey()
                                openAIAPIKey = ""
                            } label: {
                                Label("Remove OpenAI Key", systemImage: "trash")
                            }
                        } else {
                            HStack {
                                if showingOpenAIKey {
                                    TextField("sk-...", text: $openAIAPIKey)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("sk-...", text: $openAIAPIKey)
                                }

                                Button {
                                    showingOpenAIKey.toggle()
                                } label: {
                                    Image(systemName: showingOpenAIKey ? "eye.slash" : "eye")
                                }
                            }

                            if !openAIAPIKey.isEmpty {
                                Button {
                                    KeychainService.saveOpenAIAPIKey(openAIAPIKey)
                                } label: {
                                    Label("Save OpenAI Key", systemImage: "checkmark.circle")
                                }
                            }

                            Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                                Label("Get API key from OpenAI", systemImage: "arrow.up.right.square")
                            }
                            .font(.caption)
                        }
                    }
                } header: {
                    Text("OpenAI (Optional)")
                } footer: {
                    Text("Adds AI-generated illustrations to lessons. Falls back to icons if not configured.")
                }

                Section("Insight Preferences") {
                    Picker("Auto-generate insights", selection: Binding(
                        get: { currentSettings.insightFrequency },
                        set: { currentSettings.insightFrequency = $0 }
                    )) {
                        Text("Daily").tag("daily")
                        Text("Weekly").tag("weekly")
                        Text("Manual only").tag("manual")
                    }

                    Stepper(
                        "Minimum entries: \(currentSettings.minimumEntriesForInsight)",
                        value: Binding(
                            get: { currentSettings.minimumEntriesForInsight },
                            set: { currentSettings.minimumEntriesForInsight = $0 }
                        ),
                        in: 3...20
                    )

                    Stepper(
                        "Analysis timeframe: \(currentSettings.preferredAnalysisTimeframe) days",
                        value: Binding(
                            get: { currentSettings.preferredAnalysisTimeframe },
                            set: { currentSettings.preferredAnalysisTimeframe = $0 }
                        ),
                        in: 3...30
                    )
                }

                Section("Your Data") {
                    LabeledContent("Journal Entries", value: "\(entries.count)")
                    LabeledContent("Insights Generated", value: "\(insights.count)")
                    LabeledContent("Lessons Completed", value: "\(lessons.filter { $0.isCompleted }.count)/\(lessons.count)")

                    if let lastInsight = currentSettings.lastInsightGeneratedDate {
                        LabeledContent("Last Insight", value: lastInsight.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0 (MVP)")

                    Link(destination: URL(string: "https://www.dfrporges.org/polyvagal-theory")!) {
                        Label("Learn about Polyvagal Theory", systemImage: "link")
                    }

                    Link(destination: URL(string: "https://docs.anthropic.com")!) {
                        Label("Claude API Documentation", systemImage: "book")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                    }
                } footer: {
                    Text("This will delete all journal entries, insights, and custom lessons. Pre-built lessons will be restored on next launch.")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                // Load API key from Keychain on appear
                if let storedKey = KeychainService.getAPIKey() {
                    currentSettings.apiKey = storedKey
                }
            }
            .confirmationDialog(
                "Reset All Data?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive) {
                    resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your journal entries, insights, and custom lessons. This action cannot be undone.")
            }
        }
    }

    private func saveAPIKey() {
        if KeychainService.saveAPIKey(apiKey) {
            currentSettings.apiKey = apiKey
            apiKeySaved = true
        }
    }

    private func resetAllData() {
        // Delete all entries
        for entry in entries {
            modelContext.delete(entry)
        }

        // Delete all insights
        for insight in insights {
            modelContext.delete(insight)
        }

        // Delete custom lessons only
        for lesson in lessons where !lesson.isPrebuilt {
            modelContext.delete(lesson)
        }

        // Reset lesson completion status
        for lesson in lessons where lesson.isPrebuilt {
            lesson.isCompleted = false
            lesson.completedDate = nil
        }

        // Reset settings
        currentSettings.lastInsightGeneratedDate = nil

        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: UserSettings.self, inMemory: true)
}
