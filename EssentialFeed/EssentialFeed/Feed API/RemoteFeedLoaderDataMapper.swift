//
//  RemoteFeedLoaderDataMapper.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 12.12.2024.
//

import Foundation

final class RemoteFeedLoaderDataMapper {
    
    private struct Result: Decodable {
        let items: [RemoteFeedItem]
    }

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.isOK, let result = try? JSONDecoder().decode(Result.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidResponse
        }
        
        return result.items
    }
}

