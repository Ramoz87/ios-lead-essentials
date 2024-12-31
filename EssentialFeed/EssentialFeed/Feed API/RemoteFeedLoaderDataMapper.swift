//
//  RemoteFeedLoaderDataMapper.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 12.12.2024.
//

import Foundation

internal final class RemoteFeedLoaderDataMapper {
    
    private struct Result: Decodable {
        let items: [RemoteFeedItem]
    }

    internal static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        let successCodes = Range(uncheckedBounds: (200, 300))
        guard successCodes.contains(response.statusCode),
              let result = try? JSONDecoder().decode(Result.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidResponse
        }
        
        return result.items
    }
}

