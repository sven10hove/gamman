//
//  WeeklyRecapCard.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

struct WeeklyRecapCard: View {
    var entriesThisWeek: Int
    var dominantState: NervousSystemState?
    var showsStateIcons: Bool = true
    var onTap: () -> Void

    private var subtitle: String {
        if entriesThisWeek == 0 {
            return "Start tracking your patterns"
        } else if let state = dominantState {
            return "Mostly \(state.displayName.lowercased()) this week"
        } else {
            return "\(entriesThisWeek) entries this week"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weekly Check-in")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                if showsStateIcons {
                    HStack(spacing: 8) {
                        ForEach(NervousSystemState.allCases.prefix(3)) { state in
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.2))
                                    .frame(width: 32, height: 32)

                                Text(state.emoji)
                                    .font(.callout)
                            }
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(16)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient.purpleBlueRecap)

                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient.glassOverlay)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Insights Recap Card Variant

struct InsightsRecapCard: View {
    var totalInsights: Int
    var recentCategory: String?
    var onTap: () -> Void

    private var subtitle: String {
        if totalInsights == 0 {
            return "Generate your first AI insight"
        } else if let category = recentCategory {
            return "Latest: \(category)"
        } else {
            return "\(totalInsights) insights generated"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.headline)
                        Text("AI Insights")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(16)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient.blended)

                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient.glassOverlay)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        VStack(spacing: 16) {
            WeeklyRecapCard(
                entriesThisWeek: 12,
                dominantState: .ventral,
                onTap: {}
            )

            WeeklyRecapCard(
                entriesThisWeek: 0,
                dominantState: nil,
                showsStateIcons: false,
                onTap: {}
            )

            InsightsRecapCard(
                totalInsights: 5,
                recentCategory: "Pattern Recognition",
                onTap: {}
            )

            InsightsRecapCard(
                totalInsights: 0,
                recentCategory: nil,
                onTap: {}
            )
        }
        .padding()
    }
}
