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
                if response.statusCode == 200,
                    let root = try? JSONDecoder().decode(Root.self, from: data) {
                    completion(.success(root.feedItems))
                } else {
                    completion(.failure(.invalidResponse))
                }
            case .failure:
                completion(.failure(.connection))
            }
        }
    }
}

private struct Root: Decodable {
    let items: [Item]
    var feedItems: [FeedItem] { items.map{ $0.item } }
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
