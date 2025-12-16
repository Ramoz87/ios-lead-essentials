//
//  FeedService.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 16.12.2025.
//

import CoreData
import os
import EssentialFeed

@MainActor
final class FeedService {
    
    private lazy var client: HTTPClient = {
        URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    }()
    
    private lazy var store: FeedStore & FeedImageDataStore & Scheduler & Sendable = {
        do {
            return try CoreDataFeedStore(
                storeUrl: NSPersistentContainer
                    .defaultDirectoryURL()
                    .appendingPathComponent("feed-store.sqlite"))
        } catch {
            assertionFailure("Failed to instantiate CoreData store with error: \(error.localizedDescription)")
            logger.fault("Failed to instantiate CoreData store with error: \(error.localizedDescription)")
            return InMemoryFeedStore()
        }
    }()
    
    private lazy var baseURL = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed")!
    private lazy var logger = Logger(subsystem: "com.essentialdeveloper.EssentialApp", category: "main")
    
    convenience init(httpClient: HTTPClient, store: FeedStore & FeedImageDataStore & Scheduler & Sendable) {
        self.init()
        
        self.client = httpClient
        self.store = store
    }
    
    func loadRemoteFeedWithLocalFallback() async throws -> Paginated<FeedImage> {
        do {
            let feed = try await loadAndCacheRemoteFeed()
            return makePage(items: feed, last: feed.last)
        }
        catch {
            let feed = try await loadLocalFeed()
            return makePage(items: feed, last: feed.last)
        }
    }
    
    func loadAndCacheRemoteFeed() async throws -> [FeedImage] {
        let feed = try await loadRemoteFeed()
        await store.schedule { [store] in
            let localFeedLoader = LocalFeedLoader(store: store, date: Date.init)
            try? localFeedLoader.save(feed)
        }
        return feed
    }
    
    func loadLocalFeed() async throws -> [FeedImage] {
        try await store.schedule { [store] in
            let localFeedLoader = LocalFeedLoader(store: store, date: Date.init)
            return try localFeedLoader.load()
        }
    }
    
    func loadRemoteFeed(after: FeedImage? = nil) async throws -> [FeedImage] {
        let url = FeedEndpoint.get(after: after).url(baseURL: baseURL)
        let (data, response) = try await client.get(from: url)
        return try RemoteFeedLoaderDataMapper.map(data, response)
    }
    
    func loadMoreRemoteFeed(last: FeedImage?) async throws -> Paginated<FeedImage> {
        async let cachedFeed = try await loadLocalFeed()
        async let newFeed = try await loadRemoteFeed(after: last)
        
        let items = try await cachedFeed + newFeed
        
        await store.schedule { [store] in
            let localFeedLoader = LocalFeedLoader(store: store, date: Date.init)
            try? localFeedLoader.save(items)
        }
        
        return try await makePage(items: items, last: newFeed.last)
    }
    
    func loadLocalImageWithRemoteFallback(url: URL) async throws -> Data {
        do {
            return try await loadLocalImage(url: url)
        } catch {
            return try await loadAndCacheRemoteImage(url: url)
        }
    }
    
    func loadAndCacheRemoteImage(url: URL) async throws -> Data {
        let (data, response) = try await client.get(from: url)
        let imageData = try RemoteFeedImageDataMapper.map(data, from: response)
        await store.schedule { [store] in
            let localImageLoader = LocalFeedImageDataLoader(store: store)
            try? localImageLoader.save(data, for: url)
        }
        return imageData
    }
    
    func loadLocalImage(url: URL) async throws -> Data {
        try await store.schedule { [store] in
            let localImageLoader = LocalFeedImageDataLoader(store: store)
            let imageData = try localImageLoader.loadImageData(from: url)
            return imageData
        }
    }
    
    func loadComments(for image: FeedImage) -> () async throws -> [ImageComment] {
        return { [client, baseURL] in
            let url = ImageCommentsEndpoint.get(image.id).url(baseURL: baseURL)
            let (data, response) = try await client.get(from: url)
            return try ImageCommentsMapper.map(data, response)
        }
    }
    
    private func makePage(items: [FeedImage], last: FeedImage?) -> Paginated<FeedImage> {
        Paginated(items: items, loadMore: last.map { last in
            { @MainActor @Sendable in try await self.loadMoreRemoteFeed(last: last) }
        })
    }
    
    func validateCache() {
        Task.immediate {
            await store.schedule { [store, logger] in
                do {
                    let localFeedLoader = LocalFeedLoader(store: store, date: Date.init)
                    try localFeedLoader.validateCache()
                } catch {
                    logger.error("Failed to validate cache with error: \(error.localizedDescription)")
                }
            }
        }
    }
}
