//
//  JournalListView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.timestamp, order: .reverse) private var entries: [JournalEntry]
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "No Journal Entries",
                        description: "Start tracking your nervous system by adding your first entry. Notice how you're feeling right now.",
                        actionTitle: "Add First Entry",
                        action: { showingEditor = true }
                    )
                } else {
                    List {
                        ForEach(entries) { entry in
                            NavigationLink(destination: JournalEntryView(entry: entry)) {
                                JournalEntryRow(entry: entry)
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticService.impact(.light)
                        showingEditor = true
                    } label: {
                        Label("Add Entry", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                JournalEditorView()
            }
        }
    }

    private func deleteEntries(offsets: IndexSet) {
        HapticService.impact(.medium)
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
        }
    }
}

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
