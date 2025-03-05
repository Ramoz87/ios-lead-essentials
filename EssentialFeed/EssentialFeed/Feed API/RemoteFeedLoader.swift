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
    
    public typealias Result = FeedLoader.Result
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
            case let .success((data, response)):
                completion(RemoteFeedLoader.map(data, response))
            case .failure:
                completion(.failure(Error.connection))
            }
        }
    }
    
    private static func map(_ data: Data, _ response: HTTPURLResponse) -> Result {
        do {
            let items = try RemoteFeedLoaderDataMapper.map(data, response)
            return .success(items)
        } catch {
            return .failure(error)
        }
    }
}
