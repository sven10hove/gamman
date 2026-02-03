//
//  APIAccess.swift
//  gamman
//
//  Created by Codex on 2/3/26.
//

import Foundation

enum APIAccess {
    nonisolated private static let proxyBaseURLKey = "GAMMAN_AI_PROXY_BASE_URL"
    nonisolated private static let proxyTokenKey = "GAMMAN_AI_PROXY_CLIENT_TOKEN"
    nonisolated private static let claudeKey = "GAMMAN_CLAUDE_API_KEY"
    nonisolated private static let exaKey = "GAMMAN_EXA_API_KEY"
    nonisolated private static let openAIKey = "GAMMAN_OPENAI_API_KEY"

    nonisolated static var usesProxy: Bool {
        proxyBaseURL != nil
    }

    nonisolated static var hasClaudeAccess: Bool {
        usesProxy || !(claudeAPIKey?.isEmpty ?? true)
    }

    nonisolated static var hasExaAccess: Bool {
        usesProxy || !(exaAPIKey?.isEmpty ?? true)
    }

    nonisolated static var hasOpenAIAccess: Bool {
        usesProxy || !(openAIAPIKey?.isEmpty ?? true)
    }

    nonisolated static var claudeAPIKey: String? {
        configuredValue(for: claudeKey) ?? KeychainService.getAPIKey()
    }

    nonisolated static var exaAPIKey: String? {
        configuredValue(for: exaKey) ?? KeychainService.getExaAPIKey()
    }

    nonisolated static var openAIAPIKey: String? {
        configuredValue(for: openAIKey) ?? KeychainService.getOpenAIAPIKey()
    }

    nonisolated static func anthropicMessagesURL(defaultURL: String) -> URL? {
        endpointURL(proxyPath: "/v1/anthropic/messages", defaultURL: defaultURL)
    }

    nonisolated static func exaSearchURL(defaultURL: String) -> URL? {
        endpointURL(proxyPath: "/v1/exa/search", defaultURL: defaultURL)
    }

    nonisolated static func openAIImagesURL(defaultURL: String) -> URL? {
        endpointURL(proxyPath: "/v1/openai/images/generations", defaultURL: defaultURL)
    }

    nonisolated static func applyProxyHeaders(to request: inout URLRequest) {
        guard usesProxy else { return }

        if let token = configuredValue(for: proxyTokenKey) {
            request.setValue(token, forHTTPHeaderField: "x-gamman-client-token")
        }
    }

    nonisolated private static var proxyBaseURL: URL? {
        guard let raw = configuredValue(for: proxyBaseURLKey) else { return nil }
        return URL(string: raw)
    }

    nonisolated private static func endpointURL(proxyPath: String, defaultURL: String) -> URL? {
        if let base = proxyBaseURL {
            return URL(string: proxyPath, relativeTo: base)?.absoluteURL
        }

        return URL(string: defaultURL)
    }

    nonisolated private static func configuredValue(for key: String) -> String? {
        if let envValue = normalizedValue(ProcessInfo.processInfo.environment[key]) {
            return envValue
        }

        let infoValue = Bundle.main.object(forInfoDictionaryKey: key) as? String
        return normalizedValue(infoValue)
    }

    nonisolated private static func normalizedValue(_ value: String?) -> String? {
        guard let value else { return nil }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !(trimmed.hasPrefix("$(") && trimmed.hasSuffix(")")) else { return nil }

        return trimmed
    }
}
