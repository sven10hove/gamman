//
//  IOS16MainView.swift
//  gamman
//
//  Created by Codex on 02/03/26.
//

import Foundation
import SwiftUI
import Combine

enum IOS16State: String, CaseIterable, Identifiable, Codable {
    case ventral
    case sympathetic
    case dorsalVagal
    case blended

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ventral: return "Safe & Connected"
        case .sympathetic: return "Activated"
        case .dorsalVagal: return "Withdrawn"
        case .blended: return "Mixed"
        }
    }

    var icon: String {
        switch self {
        case .ventral: return "heart.fill"
        case .sympathetic: return "bolt.fill"
        case .dorsalVagal: return "snowflake"
        case .blended: return "circle.hexagongrid.fill"
        }
    }
}

struct IOS16JournalEntry: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let state: IOS16State
    let content: String

    init(content: String, state: IOS16State) {
        self.id = UUID()
        self.createdAt = Date()
        self.state = state
        self.content = content
    }
}

@MainActor
final class IOS16JournalStore: ObservableObject {
    @Published private(set) var entries: [IOS16JournalEntry] = []

    private let storageKey = "ios16.journal.entries"

    init() {
        load()
    }

    func addEntry(content: String, state: IOS16State) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        entries.insert(IOS16JournalEntry(content: trimmed, state: state), at: 0)
        save()
    }

    func deleteEntries(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        guard let decoded = try? JSONDecoder().decode([IOS16JournalEntry].self, from: data) else { return }
        entries = decoded.sorted { $0.createdAt > $1.createdAt }
    }
}

struct IOS16MainView: View {
    @StateObject private var store = IOS16JournalStore()

    var body: some View {
        TabView {
            IOS16JournalListView(store: store)
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }

            IOS16SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

private struct IOS16JournalListView: View {
    @ObservedObject var store: IOS16JournalStore
    @State private var showingComposer = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("You're in iOS 16 compatibility mode. Newer features stay available on iOS 17+.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if store.entries.isEmpty {
                    Section {
                        Text("No journal entries yet.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(store.entries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Label(entry.state.title, systemImage: entry.state.icon)
                                .font(.subheadline.weight(.semibold))
                            Text(entry.content)
                                .font(.body)
                            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: store.deleteEntries)
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingComposer = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingComposer) {
                IOS16AddEntryView { content, state in
                    store.addEntry(content: content, state: state)
                    showingComposer = false
                }
            }
        }
    }
}

private struct IOS16AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedState: IOS16State = .ventral
    @State private var content = ""

    let onSave: (String, IOS16State) -> Void

    var body: some View {
        NavigationView {
            Form {
                Picker("State", selection: $selectedState) {
                    ForEach(IOS16State.allCases) { state in
                        Label(state.title, systemImage: state.icon)
                            .tag(state)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Entry")
                        .font(.subheadline.weight(.semibold))
                    TextEditor(text: $content)
                        .frame(minHeight: 140)
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(content, selectedState)
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct IOS16SettingsView: View {
    @State private var claudeKey = KeychainService.getAPIKey() ?? ""
    @State private var saveStatus = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Claude API Key") {
                    SecureField("sk-ant-...", text: $claudeKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    Button("Save Key") {
                        let ok = KeychainService.saveAPIKey(claudeKey)
                        saveStatus = ok ? "Saved to Keychain." : "Could not save key."
                    }

                    if !saveStatus.isEmpty {
                        Text(saveStatus)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("AI Service") {
                    Text("You can save your Claude key locally for future compatibility workflows.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Compatibility") {
                    Text("Full data + AI workflow is available on iOS 17 and newer. iOS 16 keeps journal basics and secure key storage.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
