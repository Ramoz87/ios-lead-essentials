//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Yury Ramazanov on 23.12.2024.
//

import XCTest
import EssentialFeed

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotPerformAnyCommands() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.commands, [])
    }
        
    func test_save_errorOnDelete_doesNotInsertCache() {
        let (sut, store) = makeSUT()
        let deleteError = anyNSError()
        
        store.completeDelete(with: deleteError)
        sut.save(uniqueImageFeed().models) { _ in }
        
        XCTAssertEqual(store.commands, [.delete])
    }
    
    func test_save_successOnDelete_insertCacheWithTimestamp() {
        let timestamp = Date()
        let items = uniqueImageFeed()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        store.completeDelete(with: nil)
        sut.save(items.models) { _ in }
        
        XCTAssertEqual(store.commands, [.delete, .insert(items.local, timestamp)])
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
    
   
    //MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, date: currentDate)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, completeWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        action()
        
        var receivedError: Error?
        let exp = expectation(description: "Wait for save completion")
        sut.save(uniqueImageFeed().models) { result in
            if case let .failure(error) = result { receivedError = error }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
    }
}
