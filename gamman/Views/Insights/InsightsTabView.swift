//
//  InsightsTabView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

struct InsightsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserInsight.generatedDate, order: .reverse) private var insights: [UserInsight]
    @Query(sort: \JournalEntry.timestamp, order: .reverse) private var entries: [JournalEntry]
    @Query private var settings: [UserSettings]

    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var selectedView = 0

    var networkMonitor = NetworkMonitor.shared

    private var apiKey: String? {
        KeychainService.getAPIKey() ?? settings.first?.apiKey
    }

    private var hasAPIKey: Bool {
        guard let key = apiKey else { return false }
        return !key.isEmpty
    }

    private var canGenerate: Bool {
        hasAPIKey && networkMonitor.isConnected && entries.count >= 3 && !isGenerating
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control at top
                Picker("View", selection: $selectedView) {
                    Text("Insights").tag(0)
                    Text("Patterns").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content fills remaining space
                if selectedView == 0 {
                    insightsListView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    patternsView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticService.impact(.medium)
                        generateInsight()
                    } label: {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Label("Generate", systemImage: "sparkles")
                        }
                    }
                    .disabled(!canGenerate)
                }
            }
            .overlay {
                GeneratingOverlay(
                    isPresented: isGenerating,
                    message: "Analyzing your journal entries..."
                )
            }
            .overlay(alignment: .bottom) {
                statusBanner
            }
        }
    }

    private var insightsListView: some View {
        Group {
            if insights.isEmpty {
                EmptyStateView(
                    icon: "sparkles",
                    title: "No Insights Yet",
                    description: "Keep journaling and tap the sparkle button to generate personalized insights about your nervous system patterns.",
                    actionTitle: canGenerate ? "Generate First Insight" : nil,
                    action: canGenerate ? { generateInsight() } : nil
                )
            } else {
                List {
                    ForEach(insights) { insight in
                        InsightCardView(insight: insight)
                    }
                    .onDelete(perform: deleteInsights)
                }
                .listStyle(.plain)
            }
        }
    }

    private var patternsView: some View {
        Group {
            if entries.isEmpty {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "No Data Yet",
                    description: "Start journaling to see your nervous system patterns visualized here."
                )
            } else {
                ScrollView {
                    PatternChartView(entries: entries)
                        .padding()
                }
            }
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        VStack(spacing: 8) {
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text(error)
                    Spacer()
                    Button {
                        withAnimation {
                            errorMessage = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
                .font(.caption)
                .padding()
                .background(.red.opacity(0.9))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    HapticService.error()
                }
            }

            if !hasAPIKey && selectedView == 0 {
                HStack {
                    Image(systemName: "key.fill")
                    Text("Add API key in Settings for AI insights")
                }
                .font(.caption)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            } else if !networkMonitor.isConnected && selectedView == 0 {
                HStack {
                    Image(systemName: "wifi.slash")
                    Text("Offline - AI insights unavailable")
                }
                .font(.caption)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            } else if entries.count < 3 && selectedView == 0 {
                HStack {
                    Image(systemName: "pencil.line")
                    Text("Add \(3 - entries.count) more entries for insights")
                }
                .font(.caption)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .animation(.easeInOut, value: errorMessage)
    }

    private func deleteInsights(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(insights[index])
            }
        }
    }

    private func generateInsight() {
        guard let key = apiKey, !key.isEmpty else {
            errorMessage = "Please add your API key in Settings"
            return
        }

        isGenerating = true
        errorMessage = nil

        // Extract data from entries on MainActor before passing to actor
        let recentEntries = Array(entries.prefix(15))
        let summaries = recentEntries.map { entry in
            JournalEntrySummary(
                timestamp: entry.timestamp,
                stateDisplayName: entry.state.displayName,
                stateIntensity: entry.stateIntensity,
                content: entry.content,
                triggers: entry.triggers,
                bodyLocations: entry.bodyLocations
            )
        }
        let isConnected = networkMonitor.isConnected

        Task {
            do {
                let generatedContent = try await ClaudeAPIService.shared.generateInsight(
                    from: summaries,
                    apiKey: key,
                    isConnected: isConnected
                )

                let insight = UserInsight(
                    title: generatedContent.title,
                    content: generatedContent.content,
                    category: generatedContent.category,
                    entriesAnalyzedCount: recentEntries.count,
                    dateRangeStart: recentEntries.last?.timestamp ?? Date(),
                    dateRangeEnd: recentEntries.first?.timestamp ?? Date(),
                    analyzedEntryIDs: recentEntries.map { $0.id }
                )

                for entry in recentEntries {
                    entry.isAnalyzed = true
                }

                if let userSettings = settings.first {
                    userSettings.lastInsightGeneratedDate = Date()
                }

                await MainActor.run {
                    modelContext.insert(insight)
                    isGenerating = false
                    HapticService.success()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }
}

#Preview {
    InsightsTabView()
        .modelContainer(for: [UserInsight.self, JournalEntry.self, UserSettings.self], inMemory: true)
}
