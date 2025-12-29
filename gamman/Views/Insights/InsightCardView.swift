//
//  InsightCardView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

struct InsightCardView: View {
    @Bindable var insight: UserInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: categoryIcon)
                    .foregroundStyle(categoryColor)

                Text(insight.title)
                    .font(.headline)

                Spacer()

                if !insight.isRead {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                }

                if insight.isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }

            Text(insight.content)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(4)

            HStack {
                Label("\(insight.entriesAnalyzedCount) entries", systemImage: "doc.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(insight.generatedDate, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button {
                    insight.isBookmarked.toggle()
                } label: {
                    Label(insight.isBookmarked ? "Bookmarked" : "Bookmark", systemImage: insight.isBookmarked ? "bookmark.fill" : "bookmark")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            if !insight.isRead {
                insight.isRead = true
            }
        }
    }

    var categoryColor: Color {
        switch insight.category {
        case "pattern": return .blue
        case "suggestion": return .green
        case "observation": return .orange
        default: return .purple
        }
    }

    var categoryIcon: String {
        switch insight.category {
        case "pattern": return "chart.bar.fill"
        case "suggestion": return "lightbulb.fill"
        case "observation": return "eye.fill"
        default: return "sparkles"
        }
    }
}

#Preview {
    List {
        InsightCardView(insight: UserInsight(
            title: "Pattern Detected",
            content: "Over the past week, you've been spending more time in the sympathetic (activated) state, particularly in the mornings. Consider adding a calming morning routine to help regulate your nervous system.",
            category: "pattern",
            entriesAnalyzedCount: 12,
            dateRangeStart: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            dateRangeEnd: Date(),
            analyzedEntryIDs: []
        ))
    }
}
