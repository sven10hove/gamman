//
//  JournalEditorView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct JournalEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFocused: Bool

    var entry: JournalEntry?

    @State private var content: String = ""
    @State private var selectedState: NervousSystemState = .ventral
    @State private var stateIntensity: Int = 5
    @State private var triggers: [String] = []
    @State private var bodyLocations: [String] = []

    var isEditing: Bool { entry != nil }

    private var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Writing area
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Date
                        Text(Date().formatted(date: .long, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 8)

                        // Text editor - full journal feel
                        TextEditor(text: $content)
                            .font(.body)
                            .lineSpacing(6)
                            .scrollContentBackground(.hidden)
                            .focused($isTextFocused)
                            .frame(minHeight: 400)
                            .padding(.horizontal, 16)

                        // Placeholder when empty
                        if content.isEmpty {
                            Text("Write about your day, how you're feeling, what's on your mind...")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 20)
                                .padding(.top, -380)
                                .allowsHitTesting(false)
                        }
                    }
                }

                // Bottom: State selector
                stateSelector
            }
            .background(Color(.systemBackground))
            .navigationTitle(isEditing ? "Edit" : "Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if let entry {
                    content = entry.content
                    selectedState = entry.state
                    stateIntensity = entry.stateIntensity
                    triggers = entry.triggers
                    bodyLocations = entry.bodyLocations
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isTextFocused = true
                    }
                }
            }
        }
    }

    // MARK: - State Selector

    private var stateSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NervousSystemState.allCases) { state in
                    Button {
                        HapticService.selection()
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedState = state
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(state.emoji)
                            if selectedState == state {
                                Text(state.displayName)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal, selectedState == state ? 14 : 12)
                        .padding(.vertical, 10)
                        .background {
                            Capsule()
                                .fill(selectedState == state ? state.color.opacity(0.15) : Color(.secondarySystemBackground))
                        }
                        .overlay(
                            Capsule()
                                .stroke(selectedState == state ? state.color : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
    }

    // MARK: - Save Entry

    private func saveEntry() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        if let entry {
            entry.content = trimmedContent
            entry.state = selectedState
            entry.stateIntensity = stateIntensity
            entry.triggers = triggers
            entry.bodyLocations = bodyLocations
            entry.lastModified = Date()
        } else {
            let newEntry = JournalEntry(
                content: trimmedContent,
                nervousSystemState: selectedState,
                stateIntensity: stateIntensity,
                triggers: triggers,
                bodyLocations: bodyLocations
            )
            modelContext.insert(newEntry)
        }
        HapticService.success()
        dismiss()
    }
}

// MARK: - Glass State Pill (kept for other views)

@available(iOS 17.0, *)
struct GlassStatePill: View {
    let state: NervousSystemState
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(state.emoji)
                    .font(.subheadline)

                Text(state.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(state.gradient)
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
            }
            .foregroundStyle(isSelected ? .white : .primary)
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

// MARK: - Media Button (kept for future use)

@available(iOS 17.0, *)
struct MediaButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticService.impact(.light)
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60, height: 50)
            .glassCard(cornerRadius: 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Legacy State Pill Button (kept for compatibility)

@available(iOS 17.0, *)
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
