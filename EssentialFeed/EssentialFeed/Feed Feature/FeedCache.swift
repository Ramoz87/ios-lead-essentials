//
//  FeedCache.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.02.2025.
//

public protocol FeedCache {
    typealias SaveResult = Result<Void, Error>
    func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void)
}
