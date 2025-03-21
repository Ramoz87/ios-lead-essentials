//
//  Untitled.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 23.12.2024.
//

import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, date: @escaping () -> Date) {
        self.store = store
        self.currentDate = date
    }
}

extension LocalFeedLoader: FeedCache {
    public typealias SaveResult = FeedCache.SaveResult
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] deleteResult in
            guard let self else { return }
            
            switch deleteResult {
            case .success:
                self.insert(feed, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    public func insert(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal(), timestamp: currentDate()) { [weak self] insertResult in
            guard self != nil else { return }
            completion(insertResult)
        }
    }
}

extension LocalFeedLoader {
    public typealias LoadResult = Swift.Result<[FeedImage], Error>
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(.some(cache)) where FeedCachePolicy.validate(cache.timestamp, against: self.currentDate()):
                completion(.success(cache.feed.toModels()))
            case .success:
                completion(.success([]))
            }
        }
    }
}

extension LocalFeedLoader {
    public typealias ValidationResult = Result<Void, Error>
    
    public func validateCache(completion: @escaping (ValidationResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .failure:
                store.deleteCachedFeed(completion: completion)
            case let .success(.some(cache)) where !FeedCachePolicy.validate(cache.timestamp, against: self.currentDate()):
                store.deleteCachedFeed(completion: completion)
            case .success: completion(.success(()))
            }
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}
