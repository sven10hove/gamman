//
//  JournalListView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.timestamp, order: .reverse) private var entries: [JournalEntry]
    @State private var showingEditor = false
    @State private var showingStateSelector = false
    @State private var selectedTab = 0

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
            Group {
                if entries.isEmpty {
                    emptyStateView
                } else {
                    feedView
                }
            }
            .navigationTitle("Journal")
            .glassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticService.impact(.light)
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.appOrange)
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                JournalEditorView()
            }
            .sheet(isPresented: $showingStateSelector) {
                QuickStateLogView()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "book.closed",
            title: "No Journal Entries",
            description: "Start tracking your nervous system by adding your first entry. Notice how you're feeling right now.",
            actionTitle: "Add First Entry",
            action: { showingEditor = true }
        )
    }

    // MARK: - Feed View

    private var feedView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Weekly Recap Card
                WeeklyRecapCard(
                    entriesThisWeek: entriesThisWeek,
                    dominantState: dominantStateThisWeek,
                    showsStateIcons: false,
                    onTap: {
                        HapticService.impact(.light)
                        // Navigate to insights
                    }
                )
                .padding(.horizontal)

                // Action Items Row
                ActionItemRow(
                    onEntry: {
                        showingEditor = true
                    },
                    onState: {
                        showingStateSelector = true
                    }
                )
                .padding(.horizontal)

                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                // Journal Entries
                ForEach(entries) { entry in
                    NavigationLink(destination: JournalEntryView(entry: entry)) {
                        UserPostCard(entry: entry)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Actions

    private func deleteEntry(_ entry: JournalEntry) {
        HapticService.impact(.medium)
        withAnimation {
            modelContext.delete(entry)
        }
    }
}

// MARK: - Quick State Log View

@available(iOS 17.0, *)
struct QuickStateLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedState: NervousSystemState = .ventral
    @State private var intensity: Double = 5
    @State private var quickNote: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // State selector
                VStack(spacing: 16) {
                    Text("How are you feeling?")
                        .font(.headline)

                    HStack(spacing: 12) {
                        ForEach(NervousSystemState.allCases) { state in
                            Button {
                                HapticService.selection()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedState = state
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedState == state ? state.gradient : LinearGradient(colors: [Color.secondary.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                                            .frame(width: 56, height: 56)

                                        Text(state.emoji)
                                            .font(.title)
                                    }

                                    Text(state.displayName)
                                        .font(.caption2)
                                        .fontWeight(selectedState == state ? .semibold : .regular)
                                        .foregroundStyle(selectedState == state ? state.color : .secondary)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .glassCard(cornerRadius: 20)

                // Intensity slider
                VStack(spacing: 12) {
                    HStack {
                        Text("Intensity")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(intensity))/10")
                            .font(.headline)
                            .foregroundStyle(selectedState.color)
                    }

                    Slider(value: $intensity, in: 1...10, step: 1)
                        .tint(selectedState.color)
                }
                .padding()
                .glassCard(cornerRadius: 16)

                // Quick note input
                GlassTextInput(
                    text: $quickNote,
                    placeholder: "Add a quick note (optional)...",
                    characterLimit: 200,
                    minHeight: 80
                )

                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Log State")
            .navigationBarTitleDisplayMode(.inline)
            .glassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveQuickState()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveQuickState() {
        let trimmedNote = quickNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = trimmedNote.isEmpty ? "Quick state log: \(selectedState.displayName)" : trimmedNote
        let entry = JournalEntry(
            content: content,
            nervousSystemState: selectedState,
            stateIntensity: Int(intensity),
            triggers: [],
            bodyLocations: []
        )
        modelContext.insert(entry)
        do {
            try modelContext.save()
        } catch {
            AppLogger.database.logError("Failed to save quick state log", error: error)
        }
        HapticService.success()
        dismiss()
    }
}

// MARK: - Legacy Row (kept for reference)

@available(iOS 17.0, *)
struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: 12) {
            // State indicator
            ZStack {
                Circle()
                    .fill(entry.state.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: entry.state.systemImage)
                    .foregroundStyle(entry.state.color)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.content.prefix(60) + (entry.content.count > 60 ? "..." : ""))
                    .font(.body)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(entry.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !entry.triggers.isEmpty {
                        Text("\(entry.triggers.count) triggers")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            // Intensity badge
            VStack(spacing: 2) {
                Text("\(entry.stateIntensity)")
                    .font(.headline)
                    .foregroundStyle(entry.state.color)
                Text("/ 10")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    JournalListView()
        .modelContainer(for: JournalEntry.self, inMemory: true)
}
