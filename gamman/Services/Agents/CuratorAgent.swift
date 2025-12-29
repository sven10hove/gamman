//
//  CuratorAgent.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation

actor CuratorAgent {
    static let shared = CuratorAgent()

    private let exaBaseURL = "https://api.exa.ai/search"

    func execute(input: CuratorInput, apiKey: String, isConnected: Bool) async throws -> [ExternalResource] {
        guard isConnected else {
            throw AgentError.offline
        }

        guard !apiKey.isEmpty else {
            throw AgentError.noAPIKey(agent: "Curator")
        }

        let searchQueries = generateSearchQueries(from: input)
        var allResources: [ExternalResource] = []

        for query in searchQueries {
            do {
                let results = try await searchExa(query: query, apiKey: apiKey)
                allResources.append(contentsOf: results)
            } catch {
                // Continue with other queries if one fails
                continue
            }
        }

        // Deduplicate and sort by relevance
        let uniqueResources = deduplicateResources(allResources)
        let sortedResources = uniqueResources.sorted {
            ($0.relevanceScore ?? 0) > ($1.relevanceScore ?? 0)
        }

        return Array(sortedResources.prefix(5))
    }

    private func generateSearchQueries(from input: CuratorInput) -> [String] {
        [
            "\(input.sectionHeading) polyvagal theory",
            "\(input.lessonTopic) nervous system regulation",
            "\(input.sectionHeading) somatic experiencing trauma"
        ]
    }

    private func searchExa(query: String, apiKey: String) async throws -> [ExternalResource] {
        guard let url = URL(string: exaBaseURL) else {
            throw AgentError.invalidResponse(agent: "Curator", details: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "query": query,
            "numResults": 5,
            "type": "neural",
            "useAutoprompt": true,
            "contents": [
                "text": ["maxCharacters": 200]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AgentError.invalidResponse(agent: "Curator", details: "No HTTP response")
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw AgentError.noAPIKey(agent: "Curator")
        case 429:
            throw AgentError.rateLimited(retryAfter: nil)
        default:
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AgentError.invalidResponse(agent: "Curator", details: "Status \(httpResponse.statusCode): \(errorBody)")
        }

        return try parseExaResponse(data: data)
    }

    private nonisolated func parseExaResponse(data: Data) throws -> [ExternalResource] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            return []
        }

        return results.compactMap { result -> ExternalResource? in
            guard let title = result["title"] as? String,
                  let urlString = result["url"] as? String else {
                return nil
            }

            let snippet = result["text"] as? String
            let score = result["score"] as? Double
            let resourceType = classifyResource(url: urlString)

            return ExternalResource(
                title: title,
                url: urlString,
                snippet: snippet,
                resourceType: resourceType,
                relevanceScore: score
            )
        }
    }

    private nonisolated func classifyResource(url: String) -> ExternalResource.ResourceType {
        let lowercased = url.lowercased()

        if lowercased.contains("youtube") || lowercased.contains("vimeo") || lowercased.contains("video") {
            return .video
        }
        if lowercased.contains("pubmed") || lowercased.contains("doi.org") ||
           lowercased.contains("arxiv") || lowercased.contains("ncbi") ||
           lowercased.contains("journal") || lowercased.contains("research") {
            return .research
        }
        if lowercased.contains("podcast") || lowercased.contains("spotify") ||
           lowercased.contains("apple.com/podcast") {
            return .podcast
        }
        if lowercased.contains("amazon") || lowercased.contains("goodreads") ||
           lowercased.contains("book") {
            return .book
        }

        return .article
    }

    private nonisolated func deduplicateResources(_ resources: [ExternalResource]) -> [ExternalResource] {
        var seen = Set<String>()
        return resources.filter { resource in
            let key = resource.url.lowercased()
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }
}
