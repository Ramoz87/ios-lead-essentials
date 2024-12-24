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
    
    public typealias Result = Error?
    
    public init(store: FeedStore, date: @escaping () -> Date) {
        self.store = store
        self.currentDate = date
    }
    
    public func save(_ items: [FeedItem], completion: @escaping (Result) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self else { return }
            
            if error == nil {
                self.insert(items, completion: completion)
            } else {
                completion(error)
            }
        }
    }
    
    //MARK: - Private
    
    public func insert(_ items: [FeedItem], completion: @escaping (Result) -> Void) {
        store.insert(items.toLocal(), timeStamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

private extension Array where Element == FeedItem {
    func toLocal() -> [LocalFeedItem] {
        return map { LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL) }
    }
}
