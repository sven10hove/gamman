//
//  InsightsTabView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct InsightsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserInsight.generatedDate, order: .reverse) private var insights: [UserInsight]
    @Query(sort: \JournalEntry.timestamp, order: .reverse) private var entries: [JournalEntry]
    @Query private var settings: [UserSettings]

    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var selectedView = 0

    var networkMonitor = NetworkMonitor.shared

    private var hasAPIKey: Bool {
        APIAccess.hasClaudeAccess
    }

    private var minimumEntriesForInsight: Int {
        settings.first?.minimumEntriesForInsight ?? 3
    }

    private var preferredAnalysisTimeframeDays: Int {
        settings.first?.preferredAnalysisTimeframe ?? 7
    }

    private var entriesInPreferredWindow: [JournalEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -preferredAnalysisTimeframeDays, to: Date()) ?? .distantPast
        return entries.filter { $0.timestamp >= cutoff }
    }

    private var canGenerate: Bool {
        hasAPIKey && networkMonitor.isConnected && entriesInPreferredWindow.count >= minimumEntriesForInsight && !isGenerating
    }

    // Calculate entries from the past week
    private var entriesThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { $0.timestamp >= weekAgo }.count
    }

    // Find the most common state this week
    private var dominantStateThisWeek: NervousSystemState? {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekEntries = entries.filter { $0.timestamp >= weekAgo }
        guard !weekEntries.isEmpty else { return nil }

        let stateCounts = Dictionary(grouping: weekEntries, by: { $0.state })
        return stateCounts.max(by: { $0.value.count < $1.value.count })?.key
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Weekly Recap Card at top
                    WeeklyRecapCard(
                        entriesThisWeek: entriesThisWeek,
                        dominantState: dominantStateThisWeek,
                        onTap: {
                            HapticService.impact(.light)
                            selectedView = 1 // Switch to patterns view
                        }
                    )
                    .padding(.horizontal)

                    // Segmented control
                    Picker("View", selection: $selectedView) {
                        Text("Insights").tag(0)
                        Text("Patterns").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Content
                    if selectedView == 0 {
                        insightsListView
                    } else {
                        patternsView
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Insights")
            .glassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticService.impact(.medium)
                        generateInsight()
                    } label: {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Color.appPurple)
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
                VStack(spacing: 16) {
                    EmptyStateView(
                        icon: "sparkles",
                        title: "No Insights Yet",
                        description: "Keep journaling and tap the sparkle button to generate personalized insights about your nervous system patterns.",
                        actionTitle: canGenerate ? "Generate First Insight" : nil,
                        action: canGenerate ? { generateInsight() } : nil
                    )
                }
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(insights) { insight in
                        NavigationLink(destination: InsightDetailView(insight: insight)) {
                            GlassInsightCard(insight: insight)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                HapticService.selection()
                                markInsightAsRead(insight)
                            }
                        )
                        .padding(.horizontal)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteInsight(insight)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
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
                VStack(spacing: 16) {
                    PatternChartView(entries: entries)
                        .padding()
                        .glassCard(cornerRadius: 16)
                        .padding(.horizontal)
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
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .glassCard(cornerRadius: 12, tint: .red)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    HapticService.error()
                }
            }

            if !hasAPIKey && selectedView == 0 {
                HStack {
                    Image(systemName: "key.fill")
                    Text("AI service unavailable")
                }
                .font(.caption)
                .padding()
                .glassCard(cornerRadius: 20)
            } else if !networkMonitor.isConnected && selectedView == 0 {
                HStack {
                    Image(systemName: "wifi.slash")
                    Text("Offline - AI insights unavailable")
                }
                .font(.caption)
                .padding()
                .glassCard(cornerRadius: 20)
            } else if entriesInPreferredWindow.count < minimumEntriesForInsight && selectedView == 0 {
                HStack {
                    Image(systemName: "pencil.line")
                    Text("Add \(minimumEntriesForInsight - entriesInPreferredWindow.count) more entries for insights")
                }
                .font(.caption)
                .padding()
                .glassCard(cornerRadius: 20)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .animation(.easeInOut, value: errorMessage)
    }

    private func deleteInsight(_ insight: UserInsight) {
        HapticService.impact(.medium)
        withAnimation {
            modelContext.delete(insight)
        }
    }

    private func deleteInsights(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(insights[index])
            }
        }
    }

    private func markInsightAsRead(_ insight: UserInsight) {
        if !insight.isRead {
            insight.isRead = true
        }
    }

    private func generateInsight() {
        AppLogger.ui.logDebug("Starting insight generation")

        guard APIAccess.hasClaudeAccess else {
            errorMessage = "AI service is not configured"
            AppLogger.ui.logWarning("Insight generation blocked: AI service unavailable")
            return
        }

        guard entriesInPreferredWindow.count >= minimumEntriesForInsight else {
            errorMessage = "Add at least \(minimumEntriesForInsight) entries in the past \(preferredAnalysisTimeframeDays) days"
            AppLogger.ui.logWarning("Insight generation blocked: insufficient entries")
            return
        }

        isGenerating = true
        errorMessage = nil

        // Extract data from entries on MainActor before passing to actor
        let recentEntries = Array(entriesInPreferredWindow.prefix(30))

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
                    apiKey: APIAccess.claudeAPIKey ?? "",
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
                    do {
                        try modelContext.save()
                    } catch {
                        AppLogger.database.logError("Failed to save generated insight", error: error)
                    }
                    isGenerating = false
                    HapticService.success()
                }
            } catch {
                AppLogger.ui.logError("Insight generation failed", error: error)
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }
}

// MARK: - Glass Insight Card

@available(iOS 17.0, *)
struct GlassInsightCard: View {
    let insight: UserInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: categoryIcon)
                    .font(.headline)
                    .foregroundStyle(categoryColor)

                Text(insight.title)
                    .font(.headline)

                Spacer()

                Text(insight.generatedDate, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(insight.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(4)

            HStack {
                Label("\(insight.entriesAnalyzedCount) entries", systemImage: "doc.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(insight.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.15))
                    .foregroundStyle(categoryColor)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }

    private var categoryIcon: String {
        switch insight.category.lowercased() {
        case "pattern": return "waveform.path.ecg"
        case "suggestion": return "heart.text.square"
        case "observation": return "eye"
        default: return "sparkles"
        }
    }

    private var categoryColor: Color {
        switch insight.category.lowercased() {
        case "pattern": return .purple
        case "suggestion": return .green
        case "observation": return .orange
        default: return .blue
        }
    }
}

#Preview {
    InsightsTabView()
        .modelContainer(for: [UserInsight.self, JournalEntry.self, UserSettings.self], inMemory: true)
}
