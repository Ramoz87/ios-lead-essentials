//
//  FeedImageDataStoreSpy.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 19.02.2025.
//

import Foundation
import EssentialFeed

class FeedImageDataStoreSpy: FeedImageDataStore {
    enum Message: Equatable {
        case retrieve(dataFor: URL)
        case insert(data: Data, for: URL)
    }
    
    private(set) var receivedMessages = [Message]()
    private var insertResult: Result<Void, Error>?
    private var retrieveResult: Result<Data?, Error>?
    
    func retrieve(dataForURL url: URL) throws -> Data? {
        receivedMessages.append(.retrieve(dataFor: url))
        return try retrieveResult?.get()
    }
    
    func insert(_ data: Data, for url: URL) throws {
        receivedMessages.append(.insert(data: data, for: url))
        try insertResult?.get()
    }
    
    func completeRetrieve(with error: Error, at index: Int = 0) {
        retrieveResult = .failure(error)
    }
    
    func completeRetrieve(with data: Data?, at index: Int = 0) {
        retrieveResult = .success(data)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertResult = .failure(error)
    }
    
    func completeInsertionWithSuccess(at index: Int = 0) {
        insertResult = .success(())
    }
}
