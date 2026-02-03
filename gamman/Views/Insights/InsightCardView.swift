//
//  InsightCardView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

@available(iOS 17.0, *)
struct InsightCardView: View {
    @Bindable var insight: UserInsight
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
            HapticService.selection()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: categoryIcon)
                        .foregroundStyle(categoryColor)

                    Text(insight.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

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

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(insight.content)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                HStack {
                    Label("\(insight.entriesAnalyzedCount) entries", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(insight.generatedDate, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            InsightDetailView(insight: insight)
        }
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

// MARK: - Insight Detail View

@available(iOS 17.0, *)
struct InsightDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var insight: UserInsight

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: categoryIcon)
                            .font(.title2)
                            .foregroundStyle(categoryColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(categoryLabel)
                                .font(.caption)
                                .textCase(.uppercase)
                                .foregroundStyle(categoryColor)

                            Text(insight.generatedDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(categoryColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Title
                    Text(insight.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    // Full content
                    Text(insight.content)
                        .font(.body)
                        .lineSpacing(6)

                    Divider()

                    // Analysis info
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Based on \(insight.entriesAnalyzedCount) journal entries", systemImage: "doc.text")

                        Label("From \(insight.dateRangeStart.formatted(date: .abbreviated, time: .omitted)) to \(insight.dateRangeEnd.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Insight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        insight.isBookmarked.toggle()
                        HapticService.impact(.light)
                    } label: {
                        Image(systemName: insight.isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                }
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

    var categoryLabel: String {
        switch insight.category {
        case "pattern": return "Pattern"
        case "suggestion": return "Suggestion"
        case "observation": return "Observation"
        default: return "Insight"
        }
    }
}

#Preview {
    List {
        InsightCardView(insight: UserInsight(
            title: "Pattern Detected",
            content: "Over the past week, you've been spending more time in the sympathetic (activated) state, particularly in the mornings. Consider adding a calming morning routine to help regulate your nervous system.\n\nI noticed that your entries mention feeling activated after checking email. This is a common trigger for many people. You might try delaying email checks until after a grounding morning practice.\n\nYour body awareness is improving - keep noticing those physical cues!",
            category: "pattern",
            entriesAnalyzedCount: 12,
            dateRangeStart: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            dateRangeEnd: Date(),
            analyzedEntryIDs: []
        ))
    }
}
