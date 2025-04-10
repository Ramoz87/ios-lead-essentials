//
//  FeedCache.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.02.2025.
//

public protocol FeedCache {
    func save(_ feed: [FeedImage]) throws
}
