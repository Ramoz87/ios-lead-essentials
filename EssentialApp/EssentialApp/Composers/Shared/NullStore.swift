//
//  NullStore.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 08.04.2025.
//

import Foundation
import EssentialFeed

final class NullStore: FeedStore, FeedImageDataStore {
    func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        completion(.success(()))
    }
    
    func insert(_ feed: [EssentialFeed.LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
        completion(.success(()))
    }
    
    func retrieve(completion: @escaping RetrieveCompletion) {
        completion(.success(.none))
    }
    
    func retrieve(dataForURL url: URL, completion: @escaping (FeedImageDataStore.RetrieveResult) -> Void) {
        completion(.success(.none))
    }
    
    func insert(_ data: Data, for url: URL, completion: @escaping (InsertResult) -> Void) {
        completion(.success(()))
    }
}
