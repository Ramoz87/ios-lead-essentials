//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Yury Ramazanov on 23.12.2024.
//

import XCTest
import EssentialFeed

class FeedStore {
    typealias DeleteCompletion = (Error?) -> Void
    typealias InsertCompletion = (Error?) -> Void
    
    enum ReceivedMessage: Equatable {
        case delete
        case insert([FeedItem], Date)
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
    
    func insert(_ items: [FeedItem], timeStamp: Date, completion: @escaping InsertCompletion) {
        insertCompletions.append(completion)
        commands.append(.insert(items, timeStamp))
    }
    
    func completeInsert(with error: Error?) {
        insertCompletions.last?(error)
    }
}

class LocalFeedLoader {
    let store: FeedStore
    let currentDate: () -> Date
    
    init(store: FeedStore, date: @escaping () -> Date) {
        self.store = store
        self.currentDate = date
    }
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed {[unowned self] error in
            if error == nil {
                self.store.insert(items, timeStamp: self.currentDate(), completion: completion)
            } else {
                completion(error)
            }
        }
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotPerformAnyCommands() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.commands, [])
    }
    
    func test_save_performaCacheDelete() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        sut.save(items) { _ in }
        
        XCTAssertEqual(store.commands, [.delete])
    }
    
    func test_save_errorOnDelete_doesNotInsertCache() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let deleteError = anyNSError()
        
        sut.save(items) { _ in }
        store.completeDelete(with: deleteError)
        
        XCTAssertEqual(store.commands, [.delete])
    }
    
    func test_save_errorOnDelete_deliverError() {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        let exp = expectation(description: "Wait for save completion")
        
        var receivedError: Error?
        sut.save(items) { error in
            receivedError = error
            exp.fulfill()
        }
        
        store.completeDelete(with: deletionError)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, deletionError)
    }
    
    func test_save_errorOnInsert_deliverError() {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        let exp = expectation(description: "Wait for save completion")
        
        var receivedError: Error?
        sut.save(items) { error in
            receivedError = error
            exp.fulfill()
        }
        
        store.completeDelete(with: nil)
        store.completeInsert(with: insertionError)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, insertionError)
    }
        
    func test_save_successOnDelete_insertCacheWithTimestamp() {
        let timestamp = Date()
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(items) { _ in }
        store.completeDelete(with: nil)
        
        XCTAssertEqual(store.commands, [.delete, .insert(items, timestamp)])
    }
    
    
    //MARK: - Helpers
    
    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, date: currentDate)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
}
