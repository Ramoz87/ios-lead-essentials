//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Yury Ramazanov on 23.12.2024.
//

import XCTest
import EssentialFeed

protocol FeedStore {
    typealias DeleteCompletion = (Error?) -> Void
    typealias InsertCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeleteCompletion)
    func insert(_ items: [FeedItem], timeStamp: Date, completion: @escaping InsertCompletion)
}

class LocalFeedLoader {
    let store: FeedStore
    let currentDate: () -> Date
    
    init(store: FeedStore, date: @escaping () -> Date) {
        self.store = store
        self.currentDate = date
    }
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self else { return }
            
            if error == nil {
                self.store.insert(items, timeStamp: self.currentDate()) { [weak self] error in
                    guard self != nil else { return }
                    completion(error)
                }
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
    
    func test_save_performCacheDelete() {
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
    
    func test_save_successOnDelete_insertCacheWithTimestamp() {
        let timestamp = Date()
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(items) { _ in }
        store.completeDelete(with: nil)
        
        XCTAssertEqual(store.commands, [.delete, .insert(items, timestamp)])
    }
    
    func test_save_errorOnDelete_completeWithError() {
        let (sut, store) = makeSUT()
        let deleteError = anyNSError()
        
        expect(sut, completeWithError: deleteError) {
            store.completeDelete(with: deleteError)
        }
    }
    
    func test_save_errorOnInsert_completeWithError() {
        
        let (sut, store) = makeSUT()
        let insertError = anyNSError()
       
        expect(sut, completeWithError: insertError) {
            store.completeDelete(with: nil)
            store.completeInsert(with: insertError)
        }
    }
        
    func test_save_successOnDeleteAndInsert_completeSuccessfully() {
        let (sut, store) = makeSUT()
        
        expect(sut, completeWithError: nil) {
            store.completeDelete(with: nil)
            store.completeInsert(with: nil)
        }
    }
    
    func test_save_deallocatedBeforeDelete_errorOnDelete_notCompleteWithError() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, date: Date.init)
        
        var receivedResults = [Error?]()
        sut?.save([uniqueItem()]) {
            receivedResults.append($0)
        }
        
        sut = nil
        store.completeDelete(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_deallocatedBeforeInsert_errorOnInsert_notCompleteWithError() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, date: Date.init)
        
        var receivedResults = [Error?]()
        sut?.save([uniqueItem()]) {
            receivedResults.append($0)
        }
        
        store.completeDelete(with: nil)
        sut = nil
        store.completeInsert(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    //MARK: - Helpers
    
    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, date: currentDate)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, completeWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        var receivedError: Error?
        let items = [uniqueItem(), uniqueItem()]
        
        let exp = expectation(description: "Wait for save completion")
        sut.save(items) { error in
            receivedError = error
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
    }
    
    private class FeedStoreSpy: FeedStore {
        
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
}
