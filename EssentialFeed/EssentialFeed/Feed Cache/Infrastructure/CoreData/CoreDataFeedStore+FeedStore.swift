//
//  Untitled.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 19.02.2025.
//
import Foundation

extension CoreDataFeedStore: FeedStore {
    
    public func retrieve() throws -> CachedFeed? {
        try performSync { context in
            Result {
                try ManagedCache.find(in: context).map { CachedFeed(feed: $0.localFeed, timestamp: $0.timestamp) }
            }
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date) throws {
        try performSync { context in
            Result {
                try ManagedCache.find(in: context).map(context.delete).map(context.save)
                let managedCache = ManagedCache(context: context)
                managedCache.timestamp = timestamp
                managedCache.feed = ManagedFeedImage.images(from: feed, in: context)
                try context.save()
            }
        }
    }
    
    public func deleteCachedFeed() throws {
        try performSync { context in
            Result {
                try ManagedCache.find(in: context).map(context.delete).map(context.save)
            }
        }
    }
}
