//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 09.12.2024.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}
public protocol HTTPClient {
    func get(from url: URL, completeion: @escaping (HTTPClientResult) -> Void)
}

public struct RemoteFeedLoader {
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connection
        case invalidResponse
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success(let data, let response):
                do {
                    let items = try RemoteFeedLoaderDataMapper.map(data, response)
                    completion(.success(items))
                } catch {
                    completion(.failure(.invalidResponse))
                }
            case .failure:
                completion(.failure(.connection))
            }
        }
    }
}

private class RemoteFeedLoaderDataMapper {
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        
        let successCodes = Range(uncheckedBounds: (200, 300))
        guard successCodes.contains(response.statusCode) else {
            throw RemoteFeedLoader.Error.invalidResponse
        }
        
        let result = try JSONDecoder().decode(RemoteFeedItems.self, from: data)
        return result.items.map { $0.item }
    }
}

private struct RemoteFeedItems: Decodable {
    let items: [Item]
}

private struct Item: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
    
    var item: FeedItem {
        return FeedItem(id: id, description: description, location: location, imageURL: image)
    }
}
