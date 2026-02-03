//
//  SettingsView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query private var entries: [JournalEntry]
    @Query private var insights: [UserInsight]
    @Query private var lessons: [Lesson]

    @State private var showingResetConfirmation = false

    // MARK: - URL Constants
    private static let polyvagalTheoryURL = URL(string: "https://www.dfrporges.org/polyvagal-theory")
    private static let claudeDocsURL = URL(string: "https://docs.anthropic.com")

    var currentSettings: UserSettings {
        if let existing = settings.first {
            return existing
        } else {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            return newSettings
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // AI Service
                    GlassSettingsSection(title: "AI Service") {
                        aiServiceSection
                    }

                    // Insight Preferences
                    GlassSettingsSection(title: "Insight Preferences") {
                        insightPreferencesSection
                    }

                    // Your Data
                    GlassSettingsSection(title: "Your Data") {
                        dataStatsSection
                    }

                    // About
                    GlassSettingsSection(title: "About") {
                        aboutSection
                    }

                    // Reset
                    GlassSettingsSection(title: "Danger Zone") {
                        resetSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .glassNavigationBar()
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

    // MARK: - AI Service Section

    private var aiServiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: APIAccess.hasClaudeAccess ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(APIAccess.hasClaudeAccess ? .green : .orange)
                Text(APIAccess.hasClaudeAccess ? "AI Service Connected" : "AI Service Not Configured")
                    .font(.headline)
            }

            if APIAccess.usesProxy {
                Label("Keys are managed on your secure backend.", systemImage: "server.rack")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("Users no longer need to paste vendor API keys.", systemImage: "person.crop.circle.badge.checkmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Label("Set `GAMMAN_AI_PROXY_BASE_URL` in your app config.", systemImage: "gear")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("Without backend config, AI features stay disabled.", systemImage: "wifi.exclamationmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if APIAccess.hasExaAccess || APIAccess.hasOpenAIAccess {
                Label("Enhanced resources and illustrations are enabled.", systemImage: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Insight Preferences Section

    private var insightPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Auto-generate insights")
                    .font(.subheadline)

                Picker("", selection: Binding(
                    get: { currentSettings.insightFrequency },
                    set: { currentSettings.insightFrequency = $0 }
                )) {
                    Text("Daily").tag("daily")
                    Text("Weekly").tag("weekly")
                    Text("Manual only").tag("manual")
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Minimum entries")
                        .font(.subheadline)
                    Spacer()
                    Text("\(currentSettings.minimumEntriesForInsight)")
                        .font(.headline)
                        .foregroundStyle(Color.appPurple)
                }

                Stepper(
                    "",
                    value: Binding(
                        get: { currentSettings.minimumEntriesForInsight },
                        set: { currentSettings.minimumEntriesForInsight = $0 }
                    ),
                    in: 3...20
                )
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Analysis timeframe")
                        .font(.subheadline)
                    Spacer()
                    Text("\(currentSettings.preferredAnalysisTimeframe) days")
                        .font(.headline)
                        .foregroundStyle(Color.appPurple)
                }

                Stepper(
                    "",
                    value: Binding(
                        get: { currentSettings.preferredAnalysisTimeframe },
                        set: { currentSettings.preferredAnalysisTimeframe = $0 }
                    ),
                    in: 3...30
                )
                .labelsHidden()
            }
        }
    }

    // MARK: - Data Stats Section

    private var dataStatsSection: some View {
        VStack(spacing: 12) {
            DataStatRow(label: "Journal Entries", value: "\(entries.count)", icon: "book.closed")
            DataStatRow(label: "Insights Generated", value: "\(insights.count)", icon: "sparkles")
            DataStatRow(label: "Lessons Completed", value: "\(lessons.filter { $0.isCompleted }.count)/\(lessons.count)", icon: "checkmark.circle")

            if let lastInsight = currentSettings.lastInsightGeneratedDate {
                DataStatRow(label: "Last Insight", value: lastInsight.formatted(date: .abbreviated, time: .shortened), icon: "clock")
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Version")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("1.0.0 (MVP)")
                    .font(.subheadline)
            }

            if let url = Self.polyvagalTheoryURL {
                Link(destination: url) {
                    Label("Learn about Polyvagal Theory", systemImage: "link")
                }
            }

            if let url = Self.claudeDocsURL {
                Link(destination: url) {
                    Label("Claude API Documentation", systemImage: "book")
                }
            }
        }
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(role: .destructive) {
                showingResetConfirmation = true
            } label: {
                Label("Reset All Data", systemImage: "trash")
            }

            Text("This will delete all journal entries, insights, and custom lessons. Pre-built lessons will be restored on next launch.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

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
        HapticService.impact(.heavy)
    }
}

// MARK: - Glass Settings Section

@available(iOS 17.0, *)
struct GlassSettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            content()
                .padding(16)
                .glassCard(cornerRadius: 16)
        }
    }
}

// MARK: - Data Stat Row

@available(iOS 17.0, *)
struct DataStatRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: UserSettings.self, inMemory: true)
}
