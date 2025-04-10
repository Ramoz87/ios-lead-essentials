//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 23.12.2024.
//

import Foundation

public typealias CachedFeed = (feed: [LocalFeedImage], timestamp: Date)

public protocol FeedStore {
    
    func deleteCachedFeed() throws
    func insert(_ feed: [LocalFeedImage], timestamp: Date) throws
    func retrieve() throws -> CachedFeed?
    
    typealias DeleteResult = Result<Void, Error>
    typealias DeleteCompletion = (DeleteResult) -> Void
    
    typealias InsertResult = Result<Void, Error>
    typealias InsertCompletion = (InsertResult) -> Void
    
    typealias RetrieveResult = Swift.Result<CachedFeed?, Error>
    typealias RetrieveCompletion = (RetrieveResult) -> Void
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    @available(*, deprecated)
    func deleteCachedFeed(completion: @escaping DeleteCompletion)
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    @available(*, deprecated)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion)
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    @available(*, deprecated)
    func retrieve(completion: @escaping RetrieveCompletion)
}

public extension FeedStore {
    func deleteCachedFeed() throws {
        let group = DispatchGroup()
        group.enter()
        var result: DeleteResult!
        deleteCachedFeed {
            result = $0
            group.leave()
        }
        group.wait()
        return try result.get()
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date) throws {
        let group = DispatchGroup()
        group.enter()
        var result: InsertResult!
        insert(feed, timestamp: timestamp) {
            result = $0
            group.leave()
        }
        group.wait()
        return try result.get()
    }

    func retrieve() throws -> CachedFeed? {
        let group = DispatchGroup()
        group.enter()
        var result: RetrieveResult!
        retrieve {
            result = $0
            group.leave()
        }
        group.wait()
        return try result.get()
    }

    func deleteCachedFeed(completion: @escaping DeleteCompletion) {}
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {}
    func retrieve(completion: @escaping RetrieveCompletion) {}
}
