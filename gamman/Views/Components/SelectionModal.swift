//
//  SelectionModal.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

struct StateSelectionModal: View {
    @Binding var selectedState: NervousSystemState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(NervousSystemState.allCases) { state in
                        StateSelectionRow(
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
                .padding()
            }
            .navigationTitle("Select State")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .glassNavigationBar()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - State Selection Row

struct StateSelectionRow: View {
    let state: NervousSystemState
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Emoji with gradient background
                ZStack {
                    Circle()
                        .fill(state.gradient)
                        .frame(width: 48, height: 48)

                    Text(state.emoji)
                        .font(.title2)
                }

                // State info
                VStack(alignment: .leading, spacing: 4) {
                    Text(state.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(state.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(state.color)
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 16, tint: isSelected ? state.color : .clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Generic Selection Modal

struct SelectionModal<Item: Identifiable & Hashable>: View {
    let title: String
    let items: [Item]
    @Binding var selection: Item
    let itemContent: (Item, Bool) -> AnyView
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        Button {
                            HapticService.selection()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selection = item
                            }
                        } label: {
                            itemContent(item, selection == item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .glassNavigationBar()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedState: NervousSystemState = .ventral

        var body: some View {
            VStack {
                Text("Selected: \(selectedState.displayName)")
                    .padding()

                Button("Show Modal") {
                    // Preview only - modal shown via sheet
                }
            }
            .sheet(isPresented: .constant(true)) {
                StateSelectionModal(selectedState: $selectedState)
            }
        }
    }

    return PreviewWrapper()
}
