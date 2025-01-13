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
    private var deleteCompletions = [DeleteCompletion]()
    private var insertCompletions = [InsertCompletion]()
    private var retrieveCompletions = [RetrieveCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        deleteCompletions.append(completion)
        commands.append(.delete)
    }
    
    func completeDelete(with error: Error?) {
        deleteCompletions.last?(error)
    }
    
    func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
        insertCompletions.append(completion)
        commands.append(.insert(items, timestamp))
    }
    
    func completeInsert(with error: Error?) {
        insertCompletions.last?(error)
    }
    
    func retrieve(completion: @escaping RetrieveCompletion) {
        retrieveCompletions.append(completion)
        commands.append(.retrieve)
    }
    
    func completeRetrieve(with error: Error) {
        retrieveCompletions.last?(.failure(error))
    }
    
    func completeRetrieveWithEmptyCache() {
        retrieveCompletions.last?(.success(nil))
    }
    
    func completeRetrieve(with feed: [LocalFeedImage], timestamp: Date) {
        retrieveCompletions.last?(.success(CachedFeed(feed: feed, timestamp: timestamp)))
    }
}
