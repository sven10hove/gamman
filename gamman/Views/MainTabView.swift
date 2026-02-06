//
//  MainTabView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var selectedTab = 0
    @State private var showOnboarding = false

    private var currentSettings: UserSettings? {
        settings.first
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            JournalListView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
                .tag(0)

            LearnTabView()
                .tabItem {
                    Label("Learn", systemImage: "lightbulb.fill")
                }
                .tag(1)

            InsightsTabView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .onChange(of: selectedTab) { _, _ in
            HapticService.selection()
        }
        .onAppear {
            if let currentSettings, !currentSettings.hasCompletedOnboarding, !showOnboarding {
                showOnboarding = true
            }
        }
        .onChange(of: settings) { _, newSettings in
            guard let settings = newSettings.first else { return }
            if !settings.hasCompletedOnboarding && !showOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .onDisappear {
                    markOnboardingComplete()
                }
        }
    }

    private func markOnboardingComplete() {
        guard let currentSettings else { return }

        currentSettings.hasCompletedOnboarding = true
        do {
            try modelContext.save()
        } catch {
            AppLogger.database.logError("Failed to save onboarding completion", error: error)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [UserSettings.self, JournalEntry.self, Lesson.self, UserInsight.self], inMemory: true)
}
