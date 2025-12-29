//
//  MainTabView.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var selectedTab = 0
    @State private var showOnboarding = false

    var currentSettings: UserSettings {
        if let existing = settings.first {
            return existing
        } else {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            return newSettings
        }
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
            if !currentSettings.hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .onDisappear {
                    currentSettings.hasCompletedOnboarding = true
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [UserSettings.self, JournalEntry.self, Lesson.self, UserInsight.self], inMemory: true)
}
