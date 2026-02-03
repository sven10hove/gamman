//
//  ExternalResource.swift
//  gamman
//
//  Created by Sven Ten Hove on 12/29/25.
//

import Foundation

enum ResourceType: String, Codable, Sendable, CaseIterable {
    case article
    case video
    case research
    case book
    case podcast
    case other

    nonisolated var systemImage: String {
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

struct ExternalResource: Codable, Hashable, Identifiable, @unchecked Sendable {
    let id: UUID
    let title: String
    let url: String
    let snippet: String?
    let resourceType: ResourceType
    let relevanceScore: Double?

    nonisolated init(
        id: UUID,
        title: String,
        url: String,
        snippet: String?,
        resourceType: ResourceType,
        relevanceScore: Double?
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.snippet = snippet
        self.resourceType = resourceType
        self.relevanceScore = relevanceScore
    }
}
