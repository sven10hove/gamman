//
//  UserPostCard.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

@available(iOS 17.0, *)
struct UserPostCard: View {
    let entry: JournalEntry

    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: entry.timestamp, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with state and time
            HStack(spacing: 10) {
                // State indicator with gradient background
                ZStack {
                    Circle()
                        .fill(entry.state.gradient)
                        .frame(width: 40, height: 40)

                    Text(entry.state.emoji)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.state.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(timeAgoText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Intensity badge
                if entry.stateIntensity > 0 {
                    HStack(spacing: 2) {
                        Text("\(entry.stateIntensity)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("/10")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(entry.state.color.opacity(0.15))
                    .clipShape(Capsule())
                }
            }

            // Content
            Text(entry.content)
                .font(.body)
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            // Triggers and body locations
            if !entry.triggers.isEmpty || !entry.bodyLocations.isEmpty {
                HStack(spacing: 8) {
                    if !entry.triggers.isEmpty {
                        Label("\(entry.triggers.count) triggers", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    if !entry.bodyLocations.isEmpty {
                        Label("\(entry.bodyLocations.count) locations", systemImage: "figure.stand")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - Compact Post Card

@available(iOS 17.0, *)
struct CompactPostCard: View {
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: 12) {
            // State emoji
            ZStack {
                Circle()
                    .fill(entry.state.gradient)
                    .frame(width: 44, height: 44)

                Text(entry.state.emoji)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.content.prefix(60) + (entry.content.count > 60 ? "..." : ""))
                    .font(.subheadline)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(entry.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(entry.state.displayName)
                        .font(.caption)
                        .foregroundStyle(entry.state.color)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .glassCard(cornerRadius: 12)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 16) {
                // Note: These previews require JournalEntry model to be available
                Text("UserPostCard Previews")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                // Placeholder cards showing the design
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient.sympathetic)
                                .frame(width: 40, height: 40)
                            Text("⚡")
                                .font(.title3)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Activated")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("2h ago")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 2) {
                            Text("7")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text("/10")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    Text("Felt energized after my morning workout. Heart rate was up but in a good way.")
                        .font(.body)
                }
                .padding(16)
                .glassCard(cornerRadius: 16)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient.ventral)
                                .frame(width: 40, height: 40)
                            Text("🌿")
                                .font(.title3)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Safe & Connected")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("5h ago")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    Text("Had a great call with a friend. Feeling grounded and present.")
                        .font(.body)
                }
                .padding(16)
                .glassCard(cornerRadius: 16)
            }
            .padding()
        }
    }
}
