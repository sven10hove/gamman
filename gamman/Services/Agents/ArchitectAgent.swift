//
//  ArchitectAgent.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation

actor ArchitectAgent {
    static let shared = ArchitectAgent()

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-3-haiku-20240307"

    func execute(prompt: String, apiKey: String, isConnected: Bool) async throws -> LessonOutline {
        guard isConnected else {
            throw AgentError.offline
        }

        guard !apiKey.isEmpty else {
            throw AgentError.noAPIKey(agent: "Architect")
        }

        let systemPrompt = """
        You are an expert instructional designer specializing in polyvagal theory, nervous system regulation, and somatic psychology.
        Design a comprehensive lesson structure based on the user's topic.

        Your response MUST be valid JSON in this exact format:
        {
            "title": "Lesson title (concise, engaging)",
            "subtitle": "One sentence description of what learners will gain",
            "sections": [
                {
                    "heading": "Section heading",
                    "learningObjective": "What the learner will understand after this section",
                    "keyTopics": ["topic1", "topic2", "topic3"],
                    "suggestedImageConcept": "Description for AI image generation (abstract, calming)"
                }
            ]
        }

        Guidelines:
        - Create 4-6 sections with clear progression from foundational to applied
        - Each section should have a specific, measurable learning objective
        - Build complexity gradually
        - Include at least one practical/experiential section
        - Key topics should be 2-4 specific concepts per section
        - Image concepts should be abstract and calming (no text, watercolor style)
        - Focus on nervous system awareness and regulation
        - Be warm, accessible, and trauma-informed
        """

        let response = try await sendRequest(
            prompt: "Design a comprehensive lesson about: \(prompt)",
            systemPrompt: systemPrompt,
            apiKey: apiKey
        )

        return try parseOutline(from: response)
    }

    private func sendRequest(prompt: String, systemPrompt: String, apiKey: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw AgentError.invalidResponse(agent: "Architect", details: "Invalid URL")
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
            throw AgentError.invalidResponse(agent: "Architect", details: "No HTTP response")
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw AgentError.noAPIKey(agent: "Architect")
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "retry-after").flatMap { Int($0) }
            throw AgentError.rateLimited(retryAfter: retryAfter)
        default:
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AgentError.invalidResponse(agent: "Architect", details: "Status \(httpResponse.statusCode): \(errorBody)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AgentError.invalidResponse(agent: "Architect", details: "Could not parse Claude response")
        }

        return text
    }

    private nonisolated func parseOutline(from response: String) throws -> LessonOutline {
        let jsonString = extractJSON(from: response)

        guard let data = jsonString.data(using: .utf8) else {
            throw AgentError.invalidResponse(agent: "Architect", details: "Could not convert to data")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let title = json["title"] as? String,
              let subtitle = json["subtitle"] as? String,
              let sectionsArray = json["sections"] as? [[String: Any]] else {
            throw AgentError.invalidResponse(agent: "Architect", details: "Invalid JSON structure")
        }

        let sections = sectionsArray.compactMap { sectionDict -> LessonOutline.SectionOutline? in
            guard let heading = sectionDict["heading"] as? String,
                  let learningObjective = sectionDict["learningObjective"] as? String else {
                return nil
            }

            let keyTopics = (sectionDict["keyTopics"] as? [String]) ?? []
            let suggestedImageConcept = (sectionDict["suggestedImageConcept"] as? String) ?? "Abstract calming illustration"

            return LessonOutline.SectionOutline(
                heading: heading,
                learningObjective: learningObjective,
                keyTopics: keyTopics,
                suggestedImageConcept: suggestedImageConcept
            )
        }

        guard !sections.isEmpty else {
            throw AgentError.invalidResponse(agent: "Architect", details: "No valid sections found")
        }

        return LessonOutline(title: title, subtitle: subtitle, sections: sections)
    }

    private nonisolated func extractJSON(from text: String) -> String {
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return String(text[startIndex...endIndex])
        }
        return text
    }
}
