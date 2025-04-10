//
//  LocalFeedLoader+Publisher.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 10.04.2025.
//

import Combine
import EssentialFeed

public extension LocalFeedLoader {
    typealias Publisher = AnyPublisher<[FeedImage], Error>
    
    func loadPublisher() -> Publisher {
        Deferred { Future(self.load) }.eraseToAnyPublisher()
    }
}
