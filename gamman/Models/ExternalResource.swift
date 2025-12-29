//
//  ExternalResource.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation

struct ExternalResource: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let url: String
    let snippet: String?
    let resourceType: ResourceType
    let relevanceScore: Double?

    enum ResourceType: String, Codable, Sendable {
        case article
        case video
        case research
        case book
        case podcast
        case other

        var systemImage: String {
            switch self {
            case .article: return "doc.text"
            case .video: return "play.rectangle"
            case .research: return "newspaper"
            case .book: return "book"
            case .podcast: return "headphones"
            case .other: return "link"
            }
        }
    }

    init(
        title: String,
        url: String,
        snippet: String? = nil,
        resourceType: ResourceType = .article,
        relevanceScore: Double? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.snippet = snippet
        self.resourceType = resourceType
        self.relevanceScore = relevanceScore
    }
}
