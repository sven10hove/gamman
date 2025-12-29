//
//  MoodSelectorView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

struct MoodSelectorView: View {
    @Binding var selectedState: NervousSystemState

    var body: some View {
        VStack(spacing: 12) {
            ForEach(NervousSystemState.allCases) { state in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedState = state
                    }
                } label: {
                    HStack {
                        Image(systemName: state.systemImage)
                            .font(.title2)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(state.displayName)
                                .font(.headline)
                            Text(state.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedState == state {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(state.color)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedState == state ? state.color.opacity(0.15) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedState == state ? state.color : Color.gray.opacity(0.3), lineWidth: selectedState == state ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(state.color)
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedState: NervousSystemState = .ventral
    MoodSelectorView(selectedState: $selectedState)
        .padding()
}
