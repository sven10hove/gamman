//
//  FactCheckerAgent.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation

actor FactCheckerAgent {
    static let shared = FactCheckerAgent()

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-3-haiku-20240307"

    func execute(input: FactCheckerInput, apiKey: String, isConnected: Bool) async throws -> FactCheckerOutput {
        guard isConnected else {
            throw AgentError.offline
        }

        guard !apiKey.isEmpty else {
            throw AgentError.noAPIKey(agent: "Fact Checker")
        }

        let systemPrompt = """
        You are a scientific fact-checker specializing in polyvagal theory, neuroscience, trauma studies, and somatic psychology.
        Review and revise the educational content for accuracy while maintaining accessibility.

        Your response MUST be valid JSON in this exact format:
        {
            "revisedContent": "The corrected/improved content (keep same length and tone)",
            "corrections": ["List of specific corrections or improvements made"],
            "confidenceScore": 0.95,
            "warnings": ["Any caveats about areas of ongoing research or debate"]
        }

        Fact-Checking Guidelines:
        - Verify claims against established research (Porges, Dana, Levine, van der Kolk)
        - Correct any misrepresentations of polyvagal theory
        - Distinguish between established science and emerging research
        - Flag speculative vs. well-supported claims
        - Maintain the warm, accessible tone of the original
        - Keep the same approximate length
        - Add researcher citations where appropriate (e.g., "As Dr. Stephen Porges describes...")
        - If content is accurate, return it unchanged with empty corrections array
        - Confidence score: 0.0-1.0 based on scientific support for claims
        """

        let userPrompt = """
        Section: \(input.sectionHeading)
        Learning Objective: \(input.learningObjective)

        Content to fact-check:
        \(input.originalContent)

        Please verify the accuracy and revise if needed.
        """

        let response = try await sendRequest(
            prompt: userPrompt,
            systemPrompt: systemPrompt,
            apiKey: apiKey
        )

        return try parseOutput(from: response)
    }

    private func sendRequest(prompt: String, systemPrompt: String, apiKey: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw AgentError.invalidResponse(agent: "Fact Checker", details: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1500,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AgentError.invalidResponse(agent: "Fact Checker", details: "No HTTP response")
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw AgentError.noAPIKey(agent: "Fact Checker")
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "retry-after").flatMap { Int($0) }
            throw AgentError.rateLimited(retryAfter: retryAfter)
        default:
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AgentError.invalidResponse(agent: "Fact Checker", details: "Status \(httpResponse.statusCode): \(errorBody)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AgentError.invalidResponse(agent: "Fact Checker", details: "Could not parse Claude response")
        }

        return text
    }

    private nonisolated func parseOutput(from response: String) throws -> FactCheckerOutput {
        let jsonString = extractJSON(from: response)

        guard let data = jsonString.data(using: .utf8) else {
            throw AgentError.invalidResponse(agent: "Fact Checker", details: "Could not convert to data")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let revisedContent = json["revisedContent"] as? String else {
            throw AgentError.invalidResponse(agent: "Fact Checker", details: "Invalid JSON structure")
        }

        let corrections = (json["corrections"] as? [String]) ?? []
        let confidenceScore = (json["confidenceScore"] as? Double) ?? 0.8
        let warnings = json["warnings"] as? [String]

        return FactCheckerOutput(
            revisedContent: revisedContent,
            corrections: corrections,
            confidenceScore: confidenceScore,
            warnings: warnings
        )
    }

    private nonisolated func extractJSON(from text: String) -> String {
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return String(text[startIndex...endIndex])
        }
        return text
    }
}
