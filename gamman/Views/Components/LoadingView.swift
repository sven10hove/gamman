//
//  LoadingView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

struct LoadingView: View {
    let message: String
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient.purpleBlueRecap,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .glassCard(cornerRadius: 20)
        .onAppear {
            isAnimating = true
        }
    }
}

struct GeneratingOverlay: View {
    let isPresented: Bool
    let message: String

    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)

                LoadingView(message: message)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

// MARK: - Glass Loading Spinner

struct GlassLoadingSpinner: View {
    var size: CGFloat = 40
    var lineWidth: CGFloat = 3
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient.orangeYellowInput,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Inline Loading State

struct InlineLoadingView: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            GlassLoadingSpinner(size: 24, lineWidth: 2)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .glassCard(cornerRadius: 12)
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        VStack(spacing: 30) {
            LoadingView(message: "Generating your lesson...")

            GlassLoadingSpinner()

            GlassLoadingSpinner(size: 24, lineWidth: 2)

            InlineLoadingView(message: "Processing...")
        }
    }
}
