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
    }
    
    private(set) var commands = [ReceivedMessage]()
    private var deleteCompletions = [DeleteCompletion]()
    private var insertCompletions = [InsertCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        deleteCompletions.append(completion)
        commands.append(.delete)
    }
    
    func completeDelete(with error: Error?) {
        deleteCompletions.last?(error)
    }
    
    func insert(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertCompletion) {
        insertCompletions.append(completion)
        commands.append(.insert(items, timeStamp))
    }
    
    func completeInsert(with error: Error?) {
        insertCompletions.last?(error)
    }
}
