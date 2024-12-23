//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 23.12.2024.
//

import Foundation

public protocol FeedStore {
    typealias DeleteCompletion = (Error?) -> Void
    typealias InsertCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeleteCompletion)
    func insert(_ items: [FeedItem], timeStamp: Date, completion: @escaping InsertCompletion)
}
