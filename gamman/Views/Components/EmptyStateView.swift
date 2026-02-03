//
//  EmptyStateView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

@available(iOS 17.0, *)
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse, options: .repeating.speed(0.5))

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .padding(40)
    }
}

#Preview {
    EmptyStateView(
        icon: "book.closed",
        title: "No Journal Entries",
        description: "Start tracking your nervous system by adding your first entry.",
        actionTitle: "Add Entry",
        action: {}
    )
}
