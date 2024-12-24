//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 09.12.2024.
//

import Foundation

public class RemoteFeedLoader: FeedLoader {
    private let client: HTTPClient
    private let url: URL
    
    public typealias Result = LoadFeedResult
    public enum Error: Swift.Error {
        case connection
        case invalidResponse
    }
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let data, let response):
                completion(RemoteFeedLoader.map(data, response))
            case .failure:
                completion(.failure(Error.connection))
            }
        }
    }
    
    private static func map(_ data: Data, _ response: HTTPURLResponse) -> Result {
        do {
            let items = try RemoteFeedLoaderDataMapper.map(data, response)
            return .success(items.toModels())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedItem] {
        return map { FeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.image) }
    }
}
