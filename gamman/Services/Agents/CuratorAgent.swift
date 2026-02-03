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

        guard APIAccess.usesProxy || !apiKey.isEmpty else {
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
        guard let url = APIAccess.exaSearchURL(defaultURL: exaBaseURL) else {
            throw AgentError.invalidResponse(agent: "Curator", details: "Invalid URL")
        }

        let usesProxy = APIAccess.usesProxy
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if usesProxy {
            APIAccess.applyProxyHeaders(to: &request)
        } else {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        }
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

    private func parseExaResponse(data: Data) throws -> [ExternalResource] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            return []
        }

        return results.compactMap { result -> ExternalResource? in
            guard let urlString = result["url"] as? String else {
                return nil
            }

            // Get title, or extract from URL if empty
            var title = (result["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if title.isEmpty {
                title = extractTitleFromURL(urlString)
            }

            let snippet = result["text"] as? String
            let score = result["score"] as? Double
            let resourceType = classifyResource(url: urlString)

            return ExternalResource(
                id: UUID(),
                title: title,
                url: urlString,
                snippet: snippet,
                resourceType: resourceType,
                relevanceScore: score
            )
        }
    }

    private func extractTitleFromURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString) else { return "" }

        // Try to get a readable title from the URL path
        let path = url.path
        if !path.isEmpty && path != "/" {
            // Get the last path component and clean it up
            var title = url.lastPathComponent
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: ".html", with: "")
                .replacingOccurrences(of: ".htm", with: "")
                .replacingOccurrences(of: ".php", with: "")

            // Capitalize words
            title = title.capitalized

            if !title.isEmpty && title != "/" {
                return title
            }
        }

        // Fallback to domain name
        if let host = url.host {
            return host.replacingOccurrences(of: "www.", with: "").capitalized
        }

        return ""
    }

    private func classifyResource(url: String) -> ResourceType {
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

    private func deduplicateResources(_ resources: [ExternalResource]) -> [ExternalResource] {
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
