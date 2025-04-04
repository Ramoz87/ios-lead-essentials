//
//  FeedEndpoint.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 25.03.2025.
//
import Foundation

public enum FeedEndpoint {
    case get(limit: Int = 10, after: FeedImage? = nil)
    
    public func url(baseURL: URL) -> URL {
        switch self {
        case .get(let limit, let image):
            var components = URLComponents()
            components.scheme = baseURL.scheme
            components.host = baseURL.host
            components.path = baseURL.path + "/v1/feed"
            components.queryItems = [
                URLQueryItem(name: "limit", value: String(limit)),
                image.map { URLQueryItem(name: "after_id", value: $0.id.uuidString) },
            ].compactMap { $0 }
            return components.url!
        }
    }
}
