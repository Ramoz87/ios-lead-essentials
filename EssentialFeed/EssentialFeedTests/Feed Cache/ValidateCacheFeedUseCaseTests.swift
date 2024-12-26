//
//  ValidateCacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Yury Ramazanov on 26.12.2024.
//

import XCTest
import EssentialFeed

final class ValidateCacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotPerformAnyCommands() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.commands, [])
    }
    
    func test_validate_errorOnRetrieve_deleteCache() {
        let (sut, store) = makeSUT()

        sut.validateCache()
        store.completeRetrieve(with: anyNSError())
        
        XCTAssertEqual(store.commands, [.retrieve, .delete])
    }
    
    func test_validate_emptyCache_doesNotDeleteCache() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completeRetrieveWithEmptyCache()
        
        XCTAssertEqual(store.commands, [.retrieve])
    }
    
    //MARK: - Helpers
        
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, date: currentDate)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
}
