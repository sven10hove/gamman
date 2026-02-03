//
//  AppLogger.swift
//  gamman
//
//  Structured logging utilities using os.log for better debugging and privacy.
//

import Foundation
import os.log

/// Centralized logging for the Gamman app using os.log
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.gamman"

    // MARK: - Log Categories
    static let general = Logger(subsystem: subsystem, category: "general")
    static let agents = Logger(subsystem: subsystem, category: "agents")
    static let lessons = Logger(subsystem: subsystem, category: "lessons")
    static let api = Logger(subsystem: subsystem, category: "api")
    static let database = Logger(subsystem: subsystem, category: "database")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}

// MARK: - Convenience Extensions

extension Logger {
    /// Log an error with optional error object
    func logError(_ message: String, error: Error? = nil) {
        if let error = error {
            self.error("\(message): \(error.localizedDescription)")
        } else {
            self.error("\(message)")
        }
    }

    /// Log a warning
    func logWarning(_ message: String) {
        self.warning("\(message)")
    }

    /// Log debug info (only visible in debug builds)
    func logDebug(_ message: String) {
        self.debug("\(message)")
    }
}
