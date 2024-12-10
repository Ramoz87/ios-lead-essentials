//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 09.12.2024.
//

import Foundation

public enum HTTPClientResult {
    case success(HTTPURLResponse)
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
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Error?) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success:
                completion(.invalidResponse)
            case .failure:
                completion(.connection)
            }
        }
    }
}
