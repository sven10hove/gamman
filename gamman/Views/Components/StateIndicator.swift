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
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: state.systemImage)
                .font(size.iconSize)

            if let intensity = intensity {
                Text("\(intensity)")
                    .font(size == .small ? .caption2 : .caption)
                    .fontWeight(.medium)
            }
        }
        .foregroundStyle(state.color)
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding * 0.6)
        .background(state.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct StateBadge: View {
    let state: NervousSystemState

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: state.systemImage)
                .font(.caption2)
            Text(state.displayName)
                .font(.caption2)
        }
        .foregroundStyle(state.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(state.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(NervousSystemState.allCases) { state in
            HStack(spacing: 20) {
                StateIndicator(state: state, intensity: 7, size: .small)
                StateIndicator(state: state, intensity: 7, size: .medium)
                StateIndicator(state: state, intensity: nil, size: .large)
            }
        }

        Divider()

        HStack {
            ForEach(NervousSystemState.allCases) { state in
                StateBadge(state: state)
            }
        }
    }
    .padding()
}
