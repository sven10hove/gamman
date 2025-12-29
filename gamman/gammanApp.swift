//
//  gammanApp.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import SwiftData

@main
struct gammanApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            JournalEntry.self,
            Lesson.self,
            LessonSection.self,
            UserInsight.self,
            UserSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    let context = sharedModelContainer.mainContext
                    LessonContentProvider.shared.loadPrebuiltLessons(into: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
