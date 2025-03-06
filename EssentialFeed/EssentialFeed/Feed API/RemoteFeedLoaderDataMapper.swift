//
//  RemoteFeedLoaderDataMapper.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 12.12.2024.
//

import Foundation

public final class RemoteFeedLoaderDataMapper {
    
    private struct Result: Decodable {
        private let items: [RemoteFeedItem]
        
        private struct RemoteFeedItem: Decodable {
            let id: UUID
            let description: String?
            let location: String?
            let image: URL
        }
        
        var images: [FeedImage] {
            items.map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
        }
    }

    public static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedImage] {
        guard response.isOK, let result = try? JSONDecoder().decode(Result.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidResponse
        }
        
        return result.images
    }
}
