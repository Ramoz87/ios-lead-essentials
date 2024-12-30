//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 23.12.2024.
//

import Foundation

public enum RetrieveFeedResult {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
    case failure(Error)
}

public protocol FeedStore {
    typealias DeleteCompletion = (Error?) -> Void
    typealias InsertCompletion = (Error?) -> Void
    typealias RetrieveCompletion = (RetrieveFeedResult) -> Void
    
    func deleteCachedFeed(completion: @escaping DeleteCompletion)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion)
    func retrieve(completion: @escaping RetrieveCompletion)
}
