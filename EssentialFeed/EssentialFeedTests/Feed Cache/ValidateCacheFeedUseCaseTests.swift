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
    
    func test_validate_lessThanSevenDaysOldCache_doesNotDeleteCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrieve(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieve])
    }
    
    func test_validate_sevenDaysOldCache_deleteCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrieve(with: feed.local, timestamp: sevenDaysOldTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieve, .delete])
    }
    
    func test_validate_moreThanSevenDaysOldCache_deleteCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrieve(with: feed.local, timestamp: moreThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieve, .delete])
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
