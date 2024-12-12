//
//  RemoteFeedLoaderDataMapper.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 12.12.2024.
//

import Foundation

internal final class RemoteFeedLoaderDataMapper {
    
    private struct RemoteFeedItems: Decodable {
        let items: [Item]
        
        var feed: [FeedItem] {
            items.map { $0.item }
        }
    }

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
        
        var item: FeedItem {
            FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }
    
    internal static func map(_ data: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        
        let successCodes = Range(uncheckedBounds: (200, 300))
        guard successCodes.contains(response.statusCode),
              let result = try? JSONDecoder().decode(RemoteFeedItems.self, from: data) else {
            return .failure(RemoteFeedLoader.Error.invalidResponse)
        }
        
        return .success(result.feed)
    }
}

