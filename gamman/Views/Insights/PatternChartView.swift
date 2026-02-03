//
//  PatternChartView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import Charts

@available(iOS 17.0, *)
struct PatternChartView: View {
    let entries: [JournalEntry]

    var stateDistribution: [(state: NervousSystemState, count: Int)] {
        let grouped = Dictionary(grouping: entries, by: { $0.state })
        return NervousSystemState.allCases.map { state in
            (state: state, count: grouped[state]?.count ?? 0)
        }.filter { $0.count > 0 }
    }

    var intensityOverTime: [(date: Date, intensity: Int, state: NervousSystemState)] {
        entries.sorted { $0.timestamp < $1.timestamp }.map { entry in
            (date: entry.timestamp, intensity: entry.stateIntensity, state: entry.state)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // State Distribution
            if !stateDistribution.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("State Distribution")
                        .font(.headline)

                    Chart(stateDistribution, id: \.state) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(item.state.color)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)

                    // Legend
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(stateDistribution, id: \.state) { item in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(item.state.color)
                                    .frame(width: 10, height: 10)
                                Text("\(item.state.displayName)")
                                    .font(.caption)
                                Text("(\(item.count))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Intensity Over Time
            if intensityOverTime.count > 1 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Intensity Over Time")
                        .font(.headline)

                    Chart(intensityOverTime, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Intensity", item.intensity)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Intensity", item.intensity)
                        )
                        .foregroundStyle(item.state.color)
                        .symbolSize(40)
                    }
                    .chartYScale(domain: 1...10)
                    .chartYAxis {
                        AxisMarks(values: [1, 5, 10])
                    }
                    .frame(height: 150)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Weekly Summary
            WeeklySummaryView(entries: entries)
        }
    }
}

@available(iOS 17.0, *)
struct WeeklySummaryView: View {
    let entries: [JournalEntry]

    var weekdayData: [(day: String, count: Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        var counts: [Int: Int] = [:]
        for entry in entries {
            let weekday = calendar.component(.weekday, from: entry.timestamp)
            counts[weekday, default: 0] += 1
        }

        return (1...7).map { weekday in
            let date = calendar.date(from: DateComponents(weekday: weekday))!
            return (day: formatter.string(from: date), count: counts[weekday] ?? 0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Entries by Day")
                .font(.headline)

            Chart(weekdayData, id: \.day) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Entries", item.count)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 120)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ScrollView {
        PatternChartView(entries: [
            JournalEntry(content: "Test 1", nervousSystemState: .ventral, stateIntensity: 3),
            JournalEntry(content: "Test 2", nervousSystemState: .sympathetic, stateIntensity: 7),
            JournalEntry(content: "Test 3", nervousSystemState: .ventral, stateIntensity: 4),
            JournalEntry(content: "Test 4", nervousSystemState: .dorsalVagal, stateIntensity: 6),
        ])
        .padding()
    }
}
