//
//  IllustratorAgent.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation

actor IllustratorAgent {
    static let shared = IllustratorAgent()

    private let dalleURL = "https://api.openai.com/v1/images/generations"

    func execute(input: IllustratorInput, apiKey: String, isConnected: Bool) async throws -> IllustratorOutput {
        guard isConnected else {
            throw AgentError.offline
        }

        guard APIAccess.usesProxy || !apiKey.isEmpty else {
            // Return fallback instead of throwing for optional agent
            return IllustratorOutput(
                imageURL: nil,
                imageData: nil,
                prompt: "",
                fallbackSystemImage: selectFallbackIcon(for: input.sectionHeading)
            )
        }

        let prompt = generateImagePrompt(from: input)

        do {
            let imageURL = try await generateImage(prompt: prompt, apiKey: apiKey)
            let imageData = try await downloadImage(from: imageURL)

            return IllustratorOutput(
                imageURL: imageURL,
                imageData: imageData,
                prompt: prompt,
                fallbackSystemImage: selectFallbackIcon(for: input.sectionHeading)
            )
        } catch {
            // Graceful degradation - return fallback on any error
            return IllustratorOutput(
                imageURL: nil,
                imageData: nil,
                prompt: prompt,
                fallbackSystemImage: selectFallbackIcon(for: input.sectionHeading)
            )
        }
    }

    private nonisolated func generateImagePrompt(from input: IllustratorInput) -> String {
        """
        Abstract, calming digital illustration representing: \(input.suggestedConcept).
        Style: Soft watercolor effect, pastel colors (sage green, soft blue, warm peach), minimalist composition.
        Theme: Nervous system wellness, embodiment, inner peace.
        Mood: Serene, grounding, safe.
        Important: No text, no words, no letters. Abstract shapes only.
        Square format, suitable for iOS app.
        """
    }

    private func generateImage(prompt: String, apiKey: String) async throws -> String {
        guard let url = APIAccess.openAIImagesURL(defaultURL: dalleURL) else {
            throw AgentError.invalidResponse(agent: "Illustrator", details: "Invalid URL")
        }

        let usesProxy = APIAccess.usesProxy
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if usesProxy {
            APIAccess.applyProxyHeaders(to: &request)
        } else {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",
            "quality": "standard",
            "response_format": "url"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AgentError.invalidResponse(agent: "Illustrator", details: "No HTTP response")
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw AgentError.noAPIKey(agent: "Illustrator")
        case 429:
            throw AgentError.rateLimited(retryAfter: nil)
        default:
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AgentError.invalidResponse(agent: "Illustrator", details: "Status \(httpResponse.statusCode): \(errorBody)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let firstImage = dataArray.first,
              let imageURL = firstImage["url"] as? String else {
            throw AgentError.invalidResponse(agent: "Illustrator", details: "Could not parse image URL")
        }

        return imageURL
    }

    private func downloadImage(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw AgentError.invalidResponse(agent: "Illustrator", details: "Invalid image URL")
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AgentError.invalidResponse(agent: "Illustrator", details: "Failed to download image")
        }

        return data
    }

    private nonisolated func selectFallbackIcon(for heading: String) -> String {
        let lowercased = heading.lowercased()

        if lowercased.contains("breath") || lowercased.contains("breathing") {
            return "lungs.fill"
        }
        if lowercased.contains("heart") || lowercased.contains("love") || lowercased.contains("compassion") {
            return "heart.fill"
        }
        if lowercased.contains("brain") || lowercased.contains("mind") || lowercased.contains("nervous") {
            return "brain.head.profile"
        }
        if lowercased.contains("body") || lowercased.contains("somatic") || lowercased.contains("sensation") {
            return "figure.mind.and.body"
        }
        if lowercased.contains("safe") || lowercased.contains("safety") || lowercased.contains("protect") {
            return "hand.raised.fill"
        }
        if lowercased.contains("connect") || lowercased.contains("relation") || lowercased.contains("social") {
            return "person.2.fill"
        }
        if lowercased.contains("energy") || lowercased.contains("activat") || lowercased.contains("fight") || lowercased.contains("flight") {
            return "bolt.fill"
        }
        if lowercased.contains("calm") || lowercased.contains("rest") || lowercased.contains("freeze") || lowercased.contains("shutdown") {
            return "snowflake"
        }
        if lowercased.contains("practice") || lowercased.contains("exercise") || lowercased.contains("try") {
            return "sparkles"
        }
        if lowercased.contains("learn") || lowercased.contains("understand") || lowercased.contains("insight") {
            return "lightbulb.fill"
        }

        return "sparkles"
    }
}
