//
//  JournalEntryView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

@available(iOS 17.0, *)
struct JournalEntryView: View {
    let entry: JournalEntry
    @State private var showingEditor = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // State header
                HStack {
                    Image(systemName: entry.state.systemImage)
                        .font(.largeTitle)
                        .foregroundStyle(entry.state.color)

                    VStack(alignment: .leading) {
                        Text(entry.state.displayName)
                            .font(.headline)
                        Text("Intensity: \(entry.stateIntensity)/10")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(entry.state.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Timestamp
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text(entry.timestamp, format: .dateTime.weekday(.wide).month().day().hour().minute())
                        .foregroundStyle(.secondary)
                }

                // Content
                Text(entry.content)
                    .font(.body)

                // Triggers
                if !entry.triggers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Triggers")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(entry.triggers, id: \.self) { trigger in
                                Text(trigger)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.secondary.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Body locations
                if !entry.bodyLocations.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Body Sensations")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(entry.bodyLocations, id: \.self) { location in
                                Text(location)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditor = true
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            JournalEditorView(entry: entry)
        }
    }
}

// Simple flow layout for tags
@available(iOS 17.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var size: CGSize = .zero

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}

#Preview {
    NavigationStack {
        JournalEntryView(entry: JournalEntry(
            content: "Today I noticed I was feeling quite activated after a difficult meeting. My heart was racing and I felt tension in my shoulders.",
            nervousSystemState: .sympathetic,
            stateIntensity: 7,
            triggers: ["Work meeting", "Deadline pressure"],
            bodyLocations: ["Shoulders", "Chest"]
        ))
    }
}
