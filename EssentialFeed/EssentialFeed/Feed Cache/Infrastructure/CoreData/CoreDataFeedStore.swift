//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 31.12.2024.
//

import CoreData

final public class CoreDataFeedStore: FeedStore {
    
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeUrl: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(modelName: "FeedCache", url: storeUrl, in: bundle)
        context = container.newBackgroundContext()
    }
    
    public func retrieve(completion: @escaping RetrieveCompletion) {
        perform { context in
            completion(Result {
                try ManagedCache.find(in: context).map { CachedFeed(feed: $0.localFeed, timestamp: $0.timestamp) }
            })
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
        perform { context in
            completion(Result {
                if let cache = try ManagedCache.find(in: context) {
                    context.delete(cache)
                }
                let managedCache = ManagedCache(context: context)
                managedCache.timestamp = timestamp
                managedCache.feed = ManagedFeedImage.images(from: feed, in: context)
                try context.save()
            })
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        perform { context in
            completion(Result {
                try ManagedCache.find(in: context).map(context.delete).map(context.save)
            })
        }
    }
    
    func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.context
        context.perform { action(context) }
    }
}
