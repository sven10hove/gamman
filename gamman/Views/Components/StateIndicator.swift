//
//  StateIndicator.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

struct StateIndicator: View {
    let state: NervousSystemState
    let intensity: Int?
    var size: Size = .medium
    var useGradient: Bool = false

    enum Size {
        case small, medium, large

        var iconSize: Font {
            switch self {
            case .small: return .caption
            case .medium: return .title3
            case .large: return .title
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 10
            case .large: return 14
            }
        }

        var circleSize: CGFloat {
            switch self {
            case .small: return 28
            case .medium: return 40
            case .large: return 52
            }
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            if useGradient {
                // Gradient emoji style
                ZStack {
                    Circle()
                        .fill(state.gradient)
                        .frame(width: size.circleSize, height: size.circleSize)

                    Text(state.emoji)
                        .font(size.iconSize)
                }
            } else {
                // Classic icon style
                Image(systemName: state.systemImage)
                    .font(size.iconSize)
                    .foregroundStyle(state.color)
            }

            if let intensity = intensity {
                Text("\(intensity)")
                    .font(size == .small ? .caption2 : .caption)
                    .fontWeight(.medium)
                    .foregroundStyle(useGradient ? .primary : state.color)
            }
        }
        .padding(.horizontal, useGradient ? 0 : size.padding)
        .padding(.vertical, useGradient ? 0 : size.padding * 0.6)
        .background {
            if !useGradient {
                Capsule()
                    .fill(state.color.opacity(0.15))
            }
        }
    }
}

// MARK: - Glass State Indicator

struct GlassStateIndicator: View {
    let state: NervousSystemState
    let intensity: Int?
    var size: StateIndicator.Size = .medium

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(state.gradient)
                    .frame(width: size.circleSize, height: size.circleSize)

                Text(state.emoji)
                    .font(size.iconSize)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(state.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let intensity = intensity {
                    Text("Intensity: \(intensity)/10")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 16, tint: state.color)
    }
}

struct StateBadge: View {
    let state: NervousSystemState
    var useGradient: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if useGradient {
                Text(state.emoji)
                    .font(.caption)
            } else {
                Image(systemName: state.systemImage)
                    .font(.caption2)
            }
            Text(state.displayName)
                .font(.caption2)
        }
        .foregroundStyle(useGradient ? .white : state.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            if useGradient {
                Capsule()
                    .fill(state.gradient)
            } else {
                Capsule()
                    .fill(state.color.opacity(0.15))
            }
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 20) {
                Text("Classic Style")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(NervousSystemState.allCases) { state in
                    HStack(spacing: 20) {
                        StateIndicator(state: state, intensity: 7, size: .small)
                        StateIndicator(state: state, intensity: 7, size: .medium)
                        StateIndicator(state: state, intensity: nil, size: .large)
                    }
                }

                Divider()

                Text("Gradient Style")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(NervousSystemState.allCases) { state in
                    HStack(spacing: 20) {
                        StateIndicator(state: state, intensity: 7, size: .small, useGradient: true)
                        StateIndicator(state: state, intensity: 7, size: .medium, useGradient: true)
                        StateIndicator(state: state, intensity: nil, size: .large, useGradient: true)
                    }
                }

                Divider()

                Text("Glass State Indicators")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(NervousSystemState.allCases) { state in
                    GlassStateIndicator(state: state, intensity: 7)
                }

                Divider()

                Text("Badges")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    ForEach(NervousSystemState.allCases) { state in
                        StateBadge(state: state)
                    }
                }

                HStack {
                    ForEach(NervousSystemState.allCases) { state in
                        StateBadge(state: state, useGradient: true)
                    }
                }
            }
            .padding()
        }
    }
}
