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

    var entry: JournalEntry?

    @State private var content: String = ""
    @State private var selectedState: NervousSystemState = .ventral
    @State private var intensity: Double = 5
    @State private var triggerText: String = ""
    @State private var triggers: [String] = []
    @State private var bodyLocationText: String = ""
    @State private var bodyLocations: [String] = []

    var isEditing: Bool { entry != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("How are you feeling?") {
                    MoodSelectorView(selectedState: $selectedState)

                    VStack(alignment: .leading) {
                        Text("Intensity: \(Int(intensity))")
                            .font(.subheadline)
                        Slider(value: $intensity, in: 1...10, step: 1)
                            .tint(selectedState.color)
                    }
                }

                Section("What's on your mind?") {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }

                Section("Triggers (optional)") {
                    HStack {
                        TextField("Add a trigger", text: $triggerText)
                        Button("Add") {
                            addTrigger()
                        }
                        .disabled(triggerText.isEmpty)
                    }

                    if !triggers.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(triggers, id: \.self) { trigger in
                                HStack(spacing: 4) {
                                    Text(trigger)
                                    Button {
                                        triggers.removeAll { $0 == trigger }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }

                Section("Body sensations (optional)") {
                    HStack {
                        TextField("Where do you feel it?", text: $bodyLocationText)
                        Button("Add") {
                            addBodyLocation()
                        }
                        .disabled(bodyLocationText.isEmpty)
                    }

                    if !bodyLocations.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(bodyLocations, id: \.self) { location in
                                HStack(spacing: 4) {
                                    Text(location)
                                    Button {
                                        bodyLocations.removeAll { $0 == location }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
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
                    .disabled(content.isEmpty)
                }
            }
            .onAppear {
                if let entry {
                    content = entry.content
                    selectedState = entry.state
                    intensity = Double(entry.stateIntensity)
                    triggers = entry.triggers
                    bodyLocations = entry.bodyLocations
                }
            }
        }
    }

    private func addTrigger() {
        let trimmed = triggerText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !triggers.contains(trimmed) {
            triggers.append(trimmed)
            triggerText = ""
        }
    }

    private func addBodyLocation() {
        let trimmed = bodyLocationText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !bodyLocations.contains(trimmed) {
            bodyLocations.append(trimmed)
            bodyLocationText = ""
        }
    }

    private func saveEntry() {
        if let entry {
            entry.content = content
            entry.state = selectedState
            entry.stateIntensity = Int(intensity)
            entry.triggers = triggers
            entry.bodyLocations = bodyLocations
            entry.lastModified = Date()
        } else {
            let newEntry = JournalEntry(
                content: content,
                nervousSystemState: selectedState,
                stateIntensity: Int(intensity),
                triggers: triggers,
                bodyLocations: bodyLocations
            )
            modelContext.insert(newEntry)
        }
        HapticService.success()
        dismiss()
    }
}

#Preview {
    JournalEditorView()
        .modelContainer(for: JournalEntry.self, inMemory: true)
}
