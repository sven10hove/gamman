//
//  gammanApp.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import SwiftUI
import os
#if canImport(SwiftData)
import SwiftData
#endif

@main
struct gammanApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

struct AppRootView: View {
    var body: some View {
        Group {
#if canImport(SwiftData)
            if #available(iOS 17.0, *) {
                ModernAppRootView()
            } else {
                IOS16MainView()
            }
#else
            IOS16MainView()
#endif
        }
    }
}

#if canImport(SwiftData)
@available(iOS 17.0, *)
struct ModernAppRootView: View {
    @State private var databaseError: DatabaseError?

    private let sharedModelContainer: ModelContainer?

    init() {
        let schema = Schema([
            JournalEntry.self,
            Lesson.self,
            LessonSection.self,
            UserInsight.self,
            UserSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            AppLogger.database.info("Database initialized successfully")
        } catch {
            AppLogger.database.logError("Database initialization failed, attempting cleanup", error: error)

            // Migration failed - try to delete old database and recreate
            let fileManager = FileManager.default
            if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let dbFiles = ["default.store", "default.store-shm", "default.store-wal"]
                for file in dbFiles {
                    let fileURL = appSupport.appendingPathComponent(file)
                    try? fileManager.removeItem(at: fileURL)
                }
            }

            // Try again after cleanup
            do {
                sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                AppLogger.database.info("Database recreated successfully after cleanup")
            } catch {
                AppLogger.database.logError("Database recreation failed", error: error)
                sharedModelContainer = nil
                _databaseError = State(initialValue: DatabaseError(message: error.localizedDescription))
            }
        }
    }

    var body: some View {
        Group {
            if let container = sharedModelContainer {
                MainTabView()
                    .onAppear {
                        let context = container.mainContext
                        LessonContentProvider.shared.loadPrebuiltLessons(into: context)
                        ensureDefaultSettings(in: context)
                    }
                    .modelContainer(container)
            } else {
                DatabaseErrorView(error: databaseError) {
                    resetAppData()
                }
            }
        }
    }

    private func resetAppData() {
        AppLogger.database.logWarning("User initiated database reset")
        let fileManager = FileManager.default
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dbFiles = ["default.store", "default.store-shm", "default.store-wal"]
            for file in dbFiles {
                let fileURL = appSupport.appendingPathComponent(file)
                try? fileManager.removeItem(at: fileURL)
            }
        }
        // Restart the app (user needs to relaunch manually)
        exit(0)
    }

    private func ensureDefaultSettings(in context: ModelContext) {
        let descriptor = FetchDescriptor<UserSettings>()
        let settingsCount = (try? context.fetchCount(descriptor)) ?? 0

        if settingsCount == 0 {
            context.insert(UserSettings())
            do {
                try context.save()
                AppLogger.database.info("Created default user settings")
            } catch {
                AppLogger.database.logError("Failed to create default user settings", error: error)
            }
        } else if settingsCount > 1 {
            AppLogger.database.logWarning("Detected duplicate settings records: \(settingsCount)")
        }
    }
}
#endif

struct DatabaseError: Identifiable {
    let id = UUID()
    let message: String
}

struct DatabaseErrorView: View {
    let error: DatabaseError?
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Database Error")
                .font(.title)
                .fontWeight(.bold)

            Text("The app's database could not be loaded. This may happen after an app update.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let error = error {
                Text(error.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button(role: .destructive) {
                onReset()
            } label: {
                Label("Reset App Data", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.horizontal, 40)

            Text("This will delete all your data and restart the app.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
