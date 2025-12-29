//
//  JournalEditorView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

struct JournalEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFocused: Bool

    var entry: JournalEntry?

    @State private var content: String = ""
    @State private var selectedState: NervousSystemState = .ventral
    @State private var triggers: [String] = []
    @State private var bodyLocations: [String] = []

    var isEditing: Bool { entry != nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main writing area
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Date header
                        Text(Date().formatted(date: .complete, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        // Text editor
                        TextEditor(text: $content)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .focused($isTextFocused)
                            .frame(minHeight: 300)
                            .padding(.horizontal, 12)

                        Spacer(minLength: 100)
                    }
                }

                Divider()

                // Bottom bar with state pills
                VStack(spacing: 12) {
                    // State selector pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(NervousSystemState.allCases) { state in
                                StatePillButton(
                                    state: state,
                                    isSelected: selectedState == state
                                ) {
                                    HapticService.selection()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedState = state
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Helper text
                    Text("How are you feeling?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditing ? "Edit Note" : "New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let entry {
                    content = entry.content
                    selectedState = entry.state
                    triggers = entry.triggers
                    bodyLocations = entry.bodyLocations
                } else {
                    // Auto-focus on new entries
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTextFocused = true
                    }
                }
            }
        }
    }

    private func saveEntry() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        if let entry {
            entry.content = trimmedContent
            entry.state = selectedState
            entry.stateIntensity = 5 // Default intensity
            entry.triggers = triggers
            entry.bodyLocations = bodyLocations
            entry.lastModified = Date()
        } else {
            let newEntry = JournalEntry(
                content: trimmedContent,
                nervousSystemState: selectedState,
                stateIntensity: 5,
                triggers: triggers,
                bodyLocations: bodyLocations
            )
            modelContext.insert(newEntry)
        }
        HapticService.success()
        dismiss()
    }
}

// MARK: - State Pill Button

struct StatePillButton: View {
    let state: NervousSystemState
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: state.systemImage)
                    .font(.subheadline)
                Text(state.displayName)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? state.color : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : state.color)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(state.color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    JournalEditorView()
        .modelContainer(for: JournalEntry.self, inMemory: true)
}
