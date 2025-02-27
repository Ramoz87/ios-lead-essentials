//
//  InMemoryFeedStore.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 27.02.2025.
//
import Foundation
import EssentialFeed

class InMemoryFeedStore: FeedStore, FeedImageDataStore {
    private(set) var feedCache: CachedFeed?
    private var feedImageDataCache: [URL: Data] = [:]
    
    private init(feedCache: CachedFeed? = nil) {
        self.feedCache = feedCache
    }
    
    static var empty: InMemoryFeedStore {
        InMemoryFeedStore()
    }
    
    static var withExpiredFeedCache: InMemoryFeedStore {
        InMemoryFeedStore(feedCache: CachedFeed(feed: [], timestamp: Date.distantPast))
    }
    
    static var withNonExpiredFeedCache: InMemoryFeedStore {
        InMemoryFeedStore(feedCache: CachedFeed(feed: [], timestamp: Date()))
    }
    
    //MARK: - FeedStore
    
    func deleteCachedFeed(completion: @escaping FeedStore.DeleteCompletion) {
        feedCache = nil
        completion(.success(()))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertCompletion) {
        feedCache = CachedFeed(feed: feed, timestamp: timestamp)
        completion(.success(()))
    }
    
    func retrieve(completion: @escaping FeedStore.RetrieveCompletion) {
        completion(.success(feedCache))
    }
    
    //MARK: - FeedImageDataStore
    
    func insert(_ data: Data, for url: URL, completion: @escaping (FeedImageDataStore.InsertResult) -> Void) {
        feedImageDataCache[url] = data
        completion(.success(()))
    }
    
    func retrieve(dataForURL url: URL, completion: @escaping (FeedImageDataStore.RetrieveResult) -> Void) {
        completion(.success(feedImageDataCache[url]))
    }
}
