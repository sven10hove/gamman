//
//  JSONParser.swift
//  gamman
//
//  Shared JSON parsing utilities for extracting and cleaning JSON from AI responses.
//

import Foundation

/// JSON parsing utilities - all methods are nonisolated for use in actor contexts
enum JSONParser {
    /// Extracts a JSON object from text that may contain markdown code blocks or surrounding text
    nonisolated static func extractJSON(from text: String) -> String {
        var cleanedText = text

        // Remove markdown code blocks if present
        if cleanedText.contains("```json") {
            cleanedText = cleanedText.replacingOccurrences(of: "```json", with: "")
        }
        if cleanedText.contains("```") {
            cleanedText = cleanedText.replacingOccurrences(of: "```", with: "")
        }

        // Find JSON object in response (between first { and last })
        if let startIndex = cleanedText.firstIndex(of: "{"),
           let endIndex = cleanedText.lastIndex(of: "}") {
            var jsonString = String(cleanedText[startIndex...endIndex])
            jsonString = fixControlCharactersInJSON(jsonString)
            return jsonString
        }
        return cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Fixes unescaped control characters (newlines, tabs) inside JSON string values
    /// This handles newlines inside JSON strings that AI models sometimes return
    nonisolated static func fixControlCharactersInJSON(_ json: String) -> String {
        var result = ""
        var insideString = false
        var previousChar: Character = " "

        for char in json {
            if char == "\"" && previousChar != "\\" {
                insideString.toggle()
                result.append(char)
            } else if insideString {
                // Inside a JSON string - escape control characters
                switch char {
                case "\n":
                    result.append("\\n")
                case "\r":
                    result.append("\\r")
                case "\t":
                    result.append("\\t")
                default:
                    result.append(char)
                }
            } else {
                result.append(char)
            }
            previousChar = char
        }

        return result
    }

    /// Parses JSON from AI response text and decodes to a dictionary
    nonisolated static func parseJSONObject(from text: String) throws -> [String: Any] {
        let jsonString = extractJSON(from: text)

        guard let data = jsonString.data(using: .utf8) else {
            throw JSONParserError.dataConversionFailed
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw JSONParserError.notAJSONObject
        }

        return json
    }
}

enum JSONParserError: Error, LocalizedError {
    case dataConversionFailed
    case notAJSONObject
    case missingKey(String)

    var errorDescription: String? {
        switch self {
        case .dataConversionFailed:
            return "Could not convert response to data"
        case .notAJSONObject:
            return "Response is not a JSON object"
        case .missingKey(let key):
            return "Missing required key: \(key)"
        }
    }
}
