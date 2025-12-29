//
//  AgentProtocol.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation

// MARK: - Agent Configuration

struct AgentConfiguration: Sendable {
    let claudeAPIKey: String
    let exaAPIKey: String?
    let imageAPIKey: String?
    let isConnected: Bool

    init(
        claudeAPIKey: String,
        exaAPIKey: String? = nil,
        imageAPIKey: String? = nil,
        isConnected: Bool = true
    ) {
        self.claudeAPIKey = claudeAPIKey
        self.exaAPIKey = exaAPIKey
        self.imageAPIKey = imageAPIKey
        self.isConnected = isConnected
    }
}

// MARK: - Agent Error Types

enum AgentError: Error, LocalizedError, Sendable {
    case noAPIKey(agent: String)
    case networkError(underlying: String)
    case rateLimited(retryAfter: Int?)
    case invalidResponse(agent: String, details: String)
    case timeout(agent: String)
    case offline

    var errorDescription: String? {
        switch self {
        case .noAPIKey(let agent):
            return "\(agent) agent requires an API key"
        case .networkError(let message):
            return "Network error: \(message)"
        case .rateLimited(let retryAfter):
            let time = retryAfter.map { "\($0) seconds" } ?? "later"
            return "Rate limited. Try again in \(time)"
        case .invalidResponse(let agent, let details):
            return "\(agent) returned invalid response: \(details)"
        case .timeout(let agent):
            return "\(agent) timed out"
        case .offline:
            return "No internet connection"
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .rateLimited, .timeout, .networkError:
            return true
        default:
            return false
        }
    }
}

// MARK: - Lesson Outline (Architect Agent Output)

struct LessonOutline: Sendable {
    let title: String
    let subtitle: String
    let sections: [SectionOutline]

    struct SectionOutline: Sendable {
        let heading: String
        let learningObjective: String
        let keyTopics: [String]
        let suggestedImageConcept: String
    }
}

// MARK: - Writer Agent Types

struct WriterInput: Sendable {
    let sectionOutline: LessonOutline.SectionOutline
    let lessonContext: String
    let previousSectionSummary: String?
}

struct WriterOutput: Sendable {
    let content: String
    let practicePrompt: String?
    let keyTakeaways: [String]
}

// MARK: - Fact Checker Agent Types

struct FactCheckerInput: Sendable {
    let originalContent: String
    let sectionHeading: String
    let learningObjective: String
}

struct FactCheckerOutput: Sendable {
    let revisedContent: String
    let corrections: [String]
    let confidenceScore: Double
    let warnings: [String]?
}

// MARK: - Curator Agent Types

struct CuratorInput: Sendable {
    let sectionContent: String
    let sectionHeading: String
    let lessonTopic: String
}

// MARK: - Illustrator Agent Types

struct IllustratorInput: Sendable {
    let sectionHeading: String
    let sectionContent: String
    let suggestedConcept: String
}

struct IllustratorOutput: Sendable {
    let imageURL: String?
    let imageData: Data?
    let prompt: String
    let fallbackSystemImage: String
}

// MARK: - Retry Configuration

struct RetryConfiguration: Sendable {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval

    static let `default` = RetryConfiguration(
        maxAttempts: 3,
        baseDelay: 1.0,
        maxDelay: 30.0
    )
}

// MARK: - Retry Helper

func withRetry<T: Sendable>(
    configuration: RetryConfiguration = .default,
    operation: @Sendable () async throws -> T
) async throws -> T {
    var lastError: Error?

    for attempt in 0..<configuration.maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error

            if let agentError = error as? AgentError, !agentError.isRecoverable {
                throw error
            }

            let delay = min(
                configuration.baseDelay * pow(2, Double(attempt)),
                configuration.maxDelay
            )
            try await Task.sleep(for: .seconds(delay))
        }
    }

    throw lastError!
}
