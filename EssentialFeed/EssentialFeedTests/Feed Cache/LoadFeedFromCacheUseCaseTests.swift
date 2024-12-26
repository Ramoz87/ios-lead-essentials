//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 24.12.2024.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {
    
    func test_init_doesNotPerformAnyCommands() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.commands, [])
    }
    
    func test_load_performRetrieve() {
        let (sut, store) = makeSUT()
        sut.load() { _ in }
        XCTAssertEqual(store.commands, [.retrieve])
    }
    
    
    func test_load_errorOnRetrieve_completeWithError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()
        expect(sut, completeWith: .failure(retrievalError)) {
            store.completeRetrieve(with: retrievalError)
        }
    }
    
    func test_load_errorOnRetrieve_hasNoSideEffects() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()

        sut.load { _ in }
        
        store.completeRetrieve(with: retrievalError)
        XCTAssertEqual(store.commands, [.retrieve])
    }
    
    
    func test_load_emptyCache_completeWithEmptyResult() {
        let (sut, store) = makeSUT()
        expect(sut, completeWith: .success([])) {
            store.completeRetrieveWithEmptyCache()
        }
    }
    
    func test_load_emptyCache_hasNoSideEffects() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.completeRetrieveWithEmptyCache()
        
        XCTAssertEqual(store.commands, [.retrieve])
    }
    
    
    func test_load_lessThanSevenDaysOldCache_completeWithResult() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, completeWith: .success(feed.models), when: {
            store.completeRetrieve(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        })
    }
    
    func test_load_lessThanSevenDaysOldCache_hasNoSideEffects() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieve(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieve])
    }
    
    
    func test_load_sevenDaysOldCache_completeWithEmptyResult() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, completeWith: .success([]), when: {
            store.completeRetrieve(with: feed.local, timestamp: sevenDaysOldTimestamp)
        })
    }
    
    func test_load_sevenDaysOldCache_deleteCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieve(with: feed.local, timestamp: sevenDaysOldTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieve, .delete])
    }
    
    
    func test_load_moreThanSevenDaysOldCache_completeWithEmptyResult() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, completeWith: .success([]), when: {
            store.completeRetrieve(with: feed.local, timestamp: moreThanSevenDaysOldTimestamp)
        })
    }
    
    func test_load_moreThanSevenDaysOldCache_deleteCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieve(with: feed.local, timestamp: moreThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieve, .delete])
    }
    
    
    func test_load_deallocatedBeforeCompletion_doesNotComplete() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, date: Date.init)
        
        var receivedResults = [LocalFeedLoader.LoadResult]()
        sut?.load { receivedResults.append($0) }
        sut = nil
        store.completeRetrieveWithEmptyCache()
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    //MARK: - Helpers
        
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, date: currentDate)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
 
    private func expect(_ sut: LocalFeedLoader, completeWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
            let exp = expectation(description: "Wait for load completion")

            sut.load { receivedResult in
                switch (receivedResult, expectedResult) {
                case let (.success(receivedImages), .success(expectedImages)):
                    XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)

                case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                    XCTAssertEqual(receivedError, expectedError, file: file, line: line)

                default:
                    XCTFail("Expected result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
                }

                exp.fulfill()
            }

            action()
            wait(for: [exp], timeout: 1.0)
        }
}
