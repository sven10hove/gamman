//
//  OnboardingView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "brain.head.profile",
            iconColor: .blue,
            title: "Understand Your Nervous System",
            description: "Learn about polyvagal theory and how your body responds to stress and safety through our curated lessons."
        ),
        OnboardingPage(
            icon: "book.fill",
            iconColor: .green,
            title: "Journal Your States",
            description: "Track your nervous system states throughout the day. Notice patterns in your activation, calm, and shutdown responses."
        ),
        OnboardingPage(
            icon: "sparkles",
            iconColor: .purple,
            title: "AI-Powered Insights",
            description: "Get personalized insights from Claude AI that analyze your patterns and offer regulation suggestions tailored to you."
        ),
        OnboardingPage(
            icon: "heart.fill",
            iconColor: .pink,
            title: "Build Awareness",
            description: "The more you journal, the better you'll understand your nervous system and develop tools for regulation."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 30) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(page.iconColor.opacity(0.15))
                                .frame(width: 120, height: 120)

                            Image(systemName: page.icon)
                                .font(.system(size: 50))
                                .foregroundStyle(page.iconColor)
                        }

                        VStack(spacing: 12) {
                            Text(page.title)
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)

                            Text(page.description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                    .padding()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 20) {
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }

                // Button
                Button {
                    HapticService.impact(.light)
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        isPresented = false
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        isPresented = false
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground))
    }
}

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
