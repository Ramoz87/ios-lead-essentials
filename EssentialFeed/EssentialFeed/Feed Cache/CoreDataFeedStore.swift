//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 31.12.2024.
//

import Foundation

final public class CoreDataFeedStore: FeedStore {
    
    public init() { }
    
    public func retrieve(completion: @escaping RetrieveCompletion) {
        completion(.empty)
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
        
    }
    
    public func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        
    }
}
