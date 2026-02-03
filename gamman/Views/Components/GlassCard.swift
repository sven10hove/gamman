//
//  GlassCard.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat
    var tint: Color
    var padding: CGFloat
    @ViewBuilder var content: () -> Content

    init(
        cornerRadius: CGFloat = 20,
        tint: Color = .clear,
        padding: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .glassCard(cornerRadius: cornerRadius, tint: tint)
    }
}

// MARK: - Gradient Glass Card

struct GradientGlassCard<Content: View>: View {
    var gradient: LinearGradient
    var cornerRadius: CGFloat
    var padding: CGFloat
    @ViewBuilder var content: () -> Content

    init(
        gradient: LinearGradient,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.gradient = gradient
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(gradient)

                    // Glass overlay for depth
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LinearGradient.glassOverlay)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glass Card")
                        .font(.headline)
                    Text("This is a reusable glass container with customizable corner radius and tint.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GlassCard(tint: .orange) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tinted Glass Card")
                        .font(.headline)
                    Text("Orange tinted version")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GradientGlassCard(gradient: .purpleBlueRecap) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Recap")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Your patterns this week")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
}
