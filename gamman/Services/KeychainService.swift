//
//  KeychainService.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation
import Security

enum KeychainService {
    nonisolated private static let service = "com.gamman.api"
    nonisolated private static let claudeKeyAccount = "claude-api-key"
    nonisolated private static let exaKeyAccount = "exa-api-key"
    nonisolated private static let openaiKeyAccount = "openai-api-key"

    // MARK: - Claude API Key

    nonisolated static func saveAPIKey(_ key: String) -> Bool {
        saveKey(key, account: claudeKeyAccount)
    }

    nonisolated static func getAPIKey() -> String? {
        getKey(account: claudeKeyAccount)
    }

    @discardableResult
    nonisolated static func deleteAPIKey() -> Bool {
        deleteKey(account: claudeKeyAccount)
    }

    nonisolated static var hasAPIKey: Bool {
        getAPIKey() != nil
    }

    // MARK: - Exa API Key

    nonisolated static func saveExaAPIKey(_ key: String) -> Bool {
        saveKey(key, account: exaKeyAccount)
    }

    nonisolated static func getExaAPIKey() -> String? {
        getKey(account: exaKeyAccount)
    }

    @discardableResult
    nonisolated static func deleteExaAPIKey() -> Bool {
        deleteKey(account: exaKeyAccount)
    }

    nonisolated static var hasExaAPIKey: Bool {
        getExaAPIKey() != nil
    }

    // MARK: - OpenAI API Key

    nonisolated static func saveOpenAIAPIKey(_ key: String) -> Bool {
        saveKey(key, account: openaiKeyAccount)
    }

    nonisolated static func getOpenAIAPIKey() -> String? {
        getKey(account: openaiKeyAccount)
    }

    @discardableResult
    nonisolated static func deleteOpenAIAPIKey() -> Bool {
        deleteKey(account: openaiKeyAccount)
    }

    nonisolated static var hasOpenAIAPIKey: Bool {
        getOpenAIAPIKey() != nil
    }

    // MARK: - Generic Helpers

    nonisolated private static func saveKey(_ key: String, account: String) -> Bool {
        deleteKey(account: account)

        guard let data = key.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    nonisolated private static func getKey(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    @discardableResult
    nonisolated private static func deleteKey(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
