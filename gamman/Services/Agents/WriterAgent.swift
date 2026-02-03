//
//  WriterAgent.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation

actor WriterAgent {
    static let shared = WriterAgent()

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-3-haiku-20240307"

    func execute(input: WriterInput, apiKey: String, isConnected: Bool) async throws -> WriterOutput {
        guard isConnected else {
            throw AgentError.offline
        }

        guard APIAccess.usesProxy || !apiKey.isEmpty else {
            throw AgentError.noAPIKey(agent: "Writer")
        }

        let previousContext = input.previousSectionSummary.map {
            "\n\nPrevious section summary for continuity: \($0)"
        } ?? ""

        let systemPrompt = """
        You are an expert educator writing engaging, accessible content about nervous system regulation and polyvagal theory.
        Write detailed content for this specific lesson section.

        Your response MUST be valid JSON in this exact format:
        {
            "content": "2-3 paragraphs of educational content (detailed, practical, warm)",
            "practicePrompt": "A reflection question or somatic exercise for the reader",
            "keyTakeaways": ["takeaway1", "takeaway2", "takeaway3"]
        }

        Writing Guidelines:
        - Write in second person ("you", "your")
        - Use concrete examples and relatable metaphors
        - Be warm, compassionate, and trauma-informed
        - Include body-based awareness cues where appropriate
        - Make complex concepts accessible without oversimplifying
        - Each paragraph should be 3-5 sentences
        - Practice prompts should be specific and actionable
        - Reference the learning objective throughout
        """

        let userPrompt = """
        Lesson: \(input.lessonContext)

        Section: \(input.sectionOutline.heading)
        Learning Objective: \(input.sectionOutline.learningObjective)
        Key Topics to Cover: \(input.sectionOutline.keyTopics.joined(separator: ", "))\(previousContext)

        Write the content for this section.
        """

        let response = try await sendRequest(
            prompt: userPrompt,
            systemPrompt: systemPrompt,
            apiKey: apiKey
        )

        return try parseOutput(from: response)
    }

    private func sendRequest(prompt: String, systemPrompt: String, apiKey: String) async throws -> String {
        guard let url = APIAccess.anthropicMessagesURL(defaultURL: baseURL) else {
            throw AgentError.invalidResponse(agent: "Writer", details: "Invalid URL")
        }

        let usesProxy = APIAccess.usesProxy
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if usesProxy {
            APIAccess.applyProxyHeaders(to: &request)
        } else {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        }
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
            throw AgentError.invalidResponse(agent: "Writer", details: "No HTTP response")
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw AgentError.noAPIKey(agent: "Writer")
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "retry-after").flatMap { Int($0) }
            throw AgentError.rateLimited(retryAfter: retryAfter)
        default:
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AgentError.invalidResponse(agent: "Writer", details: "Status \(httpResponse.statusCode): \(errorBody)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AgentError.invalidResponse(agent: "Writer", details: "Could not parse Claude response")
        }

        return text
    }

    private nonisolated func parseOutput(from response: String) throws -> WriterOutput {
        do {
            let json = try JSONParser.parseJSONObject(from: response)

            let content: String
            if let contentStr = json["content"] as? String {
                content = contentStr
            } else {
                throw AgentError.invalidResponse(agent: "Writer", details: "No 'content' key in JSON. Found keys: \(Array(json.keys))")
            }

            let practicePrompt = json["practicePrompt"] as? String ?? json["practice_prompt"] as? String
            let keyTakeaways = (json["keyTakeaways"] as? [String]) ?? (json["key_takeaways"] as? [String]) ?? []

            return WriterOutput(
                content: content,
                practicePrompt: practicePrompt,
                keyTakeaways: keyTakeaways
            )
        } catch let error as AgentError {
            throw error
        } catch {
            throw AgentError.invalidResponse(agent: "Writer", details: error.localizedDescription)
        }
    }
}
