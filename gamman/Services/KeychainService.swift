//
//  KeychainService.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation
import Security

enum KeychainService {
    private static let service = "com.gamman.api"
    private static let claudeKeyAccount = "claude-api-key"
    private static let exaKeyAccount = "exa-api-key"
    private static let openaiKeyAccount = "openai-api-key"

    // MARK: - Claude API Key

    static func saveAPIKey(_ key: String) -> Bool {
        saveKey(key, account: claudeKeyAccount)
    }

    static func getAPIKey() -> String? {
        getKey(account: claudeKeyAccount)
    }

    @discardableResult
    static func deleteAPIKey() -> Bool {
        deleteKey(account: claudeKeyAccount)
    }

    static var hasAPIKey: Bool {
        getAPIKey() != nil
    }

    // MARK: - Exa API Key

    static func saveExaAPIKey(_ key: String) -> Bool {
        saveKey(key, account: exaKeyAccount)
    }

    static func getExaAPIKey() -> String? {
        getKey(account: exaKeyAccount)
    }

    @discardableResult
    static func deleteExaAPIKey() -> Bool {
        deleteKey(account: exaKeyAccount)
    }

    static var hasExaAPIKey: Bool {
        getExaAPIKey() != nil
    }

    // MARK: - OpenAI API Key

    static func saveOpenAIAPIKey(_ key: String) -> Bool {
        saveKey(key, account: openaiKeyAccount)
    }

    static func getOpenAIAPIKey() -> String? {
        getKey(account: openaiKeyAccount)
    }

    @discardableResult
    static func deleteOpenAIAPIKey() -> Bool {
        deleteKey(account: openaiKeyAccount)
    }

    static var hasOpenAIAPIKey: Bool {
        getOpenAIAPIKey() != nil
    }

    // MARK: - Generic Helpers

    private static func saveKey(_ key: String, account: String) -> Bool {
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

    private static func getKey(account: String) -> String? {
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
    private static func deleteKey(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
