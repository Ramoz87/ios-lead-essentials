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
    
    private var retrieveCompletions = [(FeedImageDataStore.RetrieveResult) -> Void]()
    
    func retrieve(dataForURL url: URL, completion: @escaping (FeedImageDataStore.RetrieveResult) -> Void) {
        retrieveCompletions.append(completion)
        receivedMessages.append(.retrieve(dataFor: url))
    }
    
    func insert(_ data: Data, for url: URL) throws {
        receivedMessages.append(.insert(data: data, for: url))
        try insertResult?.get()
    }
    
    func completeRetrieve(with error: Error, at index: Int = 0) {
        retrieveCompletions[index](.failure(error))
    }
    
    func completeRetrieve(with data: Data?, at index: Int = 0) {
        retrieveCompletions[index](.success(data))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertResult = .failure(error)
    }
    
    func completeInsertionWithSuccess(at index: Int = 0) {
        insertResult = .success(())
    }
}
