//
//  ClaudeAPIService.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation

// MARK: - Response Models (Sendable and nonisolated for Swift 6 compatibility)

struct GeneratedLessonContent: Sendable {
    let title: String
    let subtitle: String
    let sections: [GeneratedSection]

    struct GeneratedSection: Sendable {
        let heading: String
        let content: String
        let imageSystemName: String?
        let practicePrompt: String?
    }

    @MainActor
    func toLessonSections() -> [LessonSectionData] {
        sections.map { section in
            LessonSectionData(
                heading: section.heading,
                content: section.content,
                imageSystemName: section.imageSystemName,
                practicePrompt: section.practicePrompt
            )
        }
    }
}

struct GeneratedInsightContent: Sendable {
    let title: String
    let category: String
    let content: String
}


// MARK: - Entry Summary (Sendable wrapper for journal data)

struct JournalEntrySummary: Sendable {
    let timestamp: Date
    let stateDisplayName: String
    let stateIntensity: Int
    let content: String
    let triggers: [String]
    let bodyLocations: [String]
}

actor ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-3-haiku-20240307"

    enum APIError: Error, LocalizedError, Sendable {
        case noAPIKey
        case networkError(String)
        case invalidResponse
        case rateLimited
        case offline
        case decodingError(String)
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "Please add your Claude API key in Settings"
            case .networkError(let message):
                return "Network error: \(message)"
            case .invalidResponse:
                return "Invalid response from server"
            case .rateLimited:
                return "Rate limited. Please try again in a moment."
            case .offline:
                return "No internet connection. AI features require connectivity."
            case .decodingError(let message):
                return "Failed to parse response: \(message)"
            case .serverError(let message):
                return "Server error: \(message)"
            }
        }
    }

    // MARK: - Lesson Generation

    func generateLesson(prompt: String, apiKey: String, isConnected: Bool) async throws -> GeneratedLessonContent {
        guard isConnected else {
            throw APIError.offline
        }

        guard !apiKey.isEmpty else {
            throw APIError.noAPIKey
        }

        let systemPrompt = """
        You are an expert in polyvagal theory, nervous system regulation, and somatic experiencing.
        Create an educational lesson based on the user's question.

        Your response MUST be valid JSON in this exact format:
        {
            "title": "Short lesson title",
            "subtitle": "One sentence description",
            "sections": [
                {
                    "heading": "Section heading",
                    "content": "Detailed content for this section (2-3 paragraphs)",
                    "imageSystemName": "SF Symbol name like heart.fill or brain.head.profile",
                    "practicePrompt": "Optional journaling prompt or null"
                }
            ]
        }

        Guidelines:
        - Create 3-5 sections
        - Make content accessible and practical
        - Include at least 2 practice prompts
        - Use these SF Symbol names: heart.fill, brain.head.profile, bolt.fill, snowflake, lungs.fill, figure.mind.and.body, hand.raised.fill, person.2.fill, sparkles, lightbulb.fill
        - Focus on nervous system awareness and regulation
        - Be compassionate and non-judgmental
        """

        let response = try await sendRequest(
            prompt: "Create a lesson about: \(prompt)",
            systemPrompt: systemPrompt,
            apiKey: apiKey
        )

        return try Self.parseLesson(from: response)
    }

    // MARK: - Insight Generation

    func generateInsight(from summaries: [JournalEntrySummary], apiKey: String, isConnected: Bool) async throws -> GeneratedInsightContent {
        guard isConnected else {
            throw APIError.offline
        }

        guard !apiKey.isEmpty else {
            throw APIError.noAPIKey
        }

        let entrySummariesText = summaries.prefix(15).map { entry in
            """
            ---
            Date: \(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
            State: \(entry.stateDisplayName) (intensity: \(entry.stateIntensity)/10)
            Entry: \(entry.content.prefix(500))
            Triggers: \(entry.triggers.isEmpty ? "None noted" : entry.triggers.joined(separator: ", "))
            Body sensations: \(entry.bodyLocations.isEmpty ? "None noted" : entry.bodyLocations.joined(separator: ", "))
            """
        }.joined(separator: "\n")

        let systemPrompt = """
        You are a compassionate nervous system coach analyzing journal entries.
        Provide personalized insights based on the user's patterns.

        Your response MUST be valid JSON in this exact format:
        {
            "title": "Short insight title (e.g., 'Pattern Noticed' or 'Progress Update')",
            "category": "pattern" or "suggestion" or "observation",
            "content": "Your detailed insight (2-3 paragraphs). Be warm, specific, and actionable. Reference specific patterns you noticed. Offer gentle suggestions for regulation."
        }

        Guidelines:
        - Look for patterns in nervous system states over time
        - Notice common triggers and body sensations
        - Acknowledge progress and growth
        - Offer 1-2 specific, practical suggestions
        - Be encouraging but not dismissive of struggles
        - Use polyvagal-informed language
        """

        let prompt = """
        Analyze these nervous system journal entries and provide personalized insights:

        \(entrySummariesText)

        Based on these entries, what patterns do you notice? What might help this person regulate their nervous system?
        """

        let response = try await sendRequest(
            prompt: prompt,
            systemPrompt: systemPrompt,
            apiKey: apiKey
        )

        return try Self.parseInsight(from: response)
    }

    // MARK: - API Request

    private func sendRequest(prompt: String, systemPrompt: String, apiKey: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw APIError.noAPIKey
        case 429:
            throw APIError.rateLimited
        case 500...599:
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorBody)
        default:
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError("Status \(httpResponse.statusCode): \(errorBody)")
        }

        // Parse Claude response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw APIError.invalidResponse
        }

        return text
    }

    // MARK: - Response Parsing (nonisolated to avoid MainActor issues)

    private nonisolated static func parseLesson(from response: String) throws -> GeneratedLessonContent {
        let jsonString = extractJSON(from: response)

        guard let data = jsonString.data(using: .utf8) else {
            throw APIError.decodingError("Could not convert response to data")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let title = json["title"] as? String,
              let subtitle = json["subtitle"] as? String,
              let sectionsArray = json["sections"] as? [[String: Any]] else {
            throw APIError.decodingError("Invalid lesson JSON structure")
        }

        let sections = sectionsArray.compactMap { sectionDict -> GeneratedLessonContent.GeneratedSection? in
            guard let heading = sectionDict["heading"] as? String,
                  let content = sectionDict["content"] as? String else {
                return nil
            }
            return GeneratedLessonContent.GeneratedSection(
                heading: heading,
                content: content,
                imageSystemName: sectionDict["imageSystemName"] as? String,
                practicePrompt: sectionDict["practicePrompt"] as? String
            )
        }

        return GeneratedLessonContent(title: title, subtitle: subtitle, sections: sections)
    }

    private nonisolated static func parseInsight(from response: String) throws -> GeneratedInsightContent {
        let jsonString = extractJSON(from: response)

        guard let data = jsonString.data(using: .utf8) else {
            throw APIError.decodingError("Could not convert response to data")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let title = json["title"] as? String,
              let category = json["category"] as? String,
              let content = json["content"] as? String else {
            throw APIError.decodingError("Invalid insight JSON structure")
        }

        return GeneratedInsightContent(title: title, category: category, content: content)
    }

    private nonisolated static func extractJSON(from text: String) -> String {
        // Find JSON object in response (between first { and last })
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return String(text[startIndex...endIndex])
        }
        return text
    }
}
