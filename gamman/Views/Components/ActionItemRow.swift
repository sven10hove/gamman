//
//  ActionItemRow.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

struct ActionItemRow: View {
    var onEntry: () -> Void
    var onState: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ActionButton(
                icon: "pencil.line",
                label: "Entry",
                color: .appOrange,
                action: onEntry
            )

            ActionButton(
                icon: "heart.circle",
                label: "State",
                color: .ventralGreen,
                action: onState
            )
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    var icon: String
    var label: String
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: {
            HapticService.impact(.light)
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassCard(cornerRadius: 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Horizontal Scroll Variant

struct ActionItemScrollRow: View {
    var onEntry: () -> Void
    var onState: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ActionChip(
                    icon: "pencil.line",
                    label: "New Entry",
                    gradient: .orangeYellowInput,
                    action: onEntry
                )

                ActionChip(
                    icon: "heart.circle",
                    label: "Log State",
                    gradient: .ventral,
                    action: onState
                )
            }
            .padding(.horizontal)
        }
    }
}

struct ActionChip: View {
    var icon: String
    var label: String
    var gradient: LinearGradient
    var action: () -> Void

    var body: some View {
        Button(action: {
            HapticService.impact(.light)
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(gradient)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        VStack(spacing: 24) {
            Text("Action Item Row")
                .font(.caption)
                .foregroundStyle(.secondary)

            ActionItemRow(
                onEntry: {},
                onState: {}
            )
            .padding(.horizontal)

            Divider()

            Text("Scroll Variant")
                .font(.caption)
                .foregroundStyle(.secondary)

            ActionItemScrollRow(
                onEntry: {},
                onState: {}
            )
        }
    }
}
