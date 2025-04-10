//
//  NullStore.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 08.04.2025.
//

import Foundation
import EssentialFeed

final class NullStore: FeedStore, FeedImageDataStore {
    func deleteCachedFeed() throws { }
    func insert(_ feed: [EssentialFeed.LocalFeedImage], timestamp: Date) throws {}
    func retrieve() throws -> CachedFeed? { .none }

    func retrieve(dataForURL url: URL) throws -> Data? { . none }
    func insert(_ data: Data, for url: URL) throws {}
}
