//
//  InMemoryFeedStore.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 27.02.2025.
//
import Foundation

public class InMemoryFeedStore: FeedStore, FeedImageDataStore {
    private(set) var feedCache: CachedFeed?
    private var feedImageDataCache: [URL: Data] = [:]
        
    public init() {}
    
    //MARK: - FeedStore
    
    public func deleteCachedFeed() throws {
        feedCache = nil
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date) throws {
        feedCache = CachedFeed(feed: feed, timestamp: timestamp)
    }
    
    public func retrieve() throws -> CachedFeed? {
        feedCache
    }
    
    //MARK: - FeedImageDataStore
    
    public func insert(_ data: Data, for url: URL) throws {
        feedImageDataCache[url] = data
    }
    public func retrieve(dataForURL url: URL) throws -> Data? {
        feedImageDataCache[url]
    }
}
