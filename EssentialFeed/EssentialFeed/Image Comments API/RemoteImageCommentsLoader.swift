//
//  RemoteFeedLoader 2.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 05.03.2025.
//
import Foundation

public class RemoteImageCommentsLoader {
    private let client: HTTPClient
    private let url: URL
    
    public typealias Result = Swift.Result<[ImageComment], Swift.Error>
    
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
                completion(RemoteImageCommentsLoader.map(data, response))
            case .failure:
                completion(.failure(Error.connection))
            }
        }
    }
    
    private static func map(_ data: Data, _ response: HTTPURLResponse) -> Result {
        do {
            let items = try ImageCommentsMapper.map(data, response)
            return .success(items)
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
    }
}
