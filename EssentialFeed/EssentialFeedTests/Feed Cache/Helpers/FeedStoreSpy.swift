//
//  FeedStoreSpy.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 24.12.2024.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    
    enum ReceivedMessage: Equatable {
        case delete
        case insert([LocalFeedImage], Date)
        case retrieve
    }
    
    private(set) var commands = [ReceivedMessage]()
    private var deletionResult: Result<Void, Error>?
    private var insertionResult: Result<Void, Error>?
    private var retrievalResult: Result<CachedFeed?, Error>?
    
    func deleteCachedFeed() throws {
        commands.append(.delete)
        try deletionResult?.get()
    }
    
    func completeDelete(with error: Error?) {
        if let error {
            deletionResult = .failure(error)
        } else {
            deletionResult = .success(())
        }
    }
    
    func insert(_ items: [LocalFeedImage], timestamp: Date) throws {
        commands.append(.insert(items, timestamp))
        try insertionResult?.get()
    }
    
    func completeInsert(with error: Error?) {
        if let error {
            insertionResult = .failure(error)
        } else {
            insertionResult = .success(())
        }
    }
    
    func retrieve() throws -> CachedFeed? {
        commands.append(.retrieve)
        return try retrievalResult?.get()
    }
    
    func completeRetrieve(with error: Error) {
        retrievalResult = .failure(error)
    }
    
    func completeRetrieveWithEmptyCache() {
        retrievalResult = .success(nil)
    }
    
    func completeRetrieve(with feed: [LocalFeedImage], timestamp: Date) {
        retrievalResult = .success(CachedFeed(feed: feed, timestamp: timestamp))
    }
}
