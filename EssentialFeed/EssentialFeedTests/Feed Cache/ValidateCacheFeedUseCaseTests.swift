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

        sut.validateCache { _ in }
        store.completeRetrieve(with: anyNSError())
        
        XCTAssertEqual(store.commands, [.retrieve, .delete])
    }
    
    func test_validate_emptyCache_doesNotDeleteCache() {
        let (sut, store) = makeSUT()
        
        sut.validateCache { _ in }
        store.completeRetrieveWithEmptyCache()
        
        XCTAssertEqual(store.commands, [.retrieve])
    }
    
    func test_validate_cacheNotExpired_doesNotDeleteCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanCacheExpirationDate = fixedCurrentDate.maxFeedCacheAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache { _ in }
        store.completeRetrieve(with: feed.local, timestamp: lessThanCacheExpirationDate)
        
        XCTAssertEqual(store.commands, [.retrieve])
    }
    
    func test_validate_cacheExpirationDate_deleteCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let cacheExpirationDate = fixedCurrentDate.maxFeedCacheAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache { _ in }
        store.completeRetrieve(with: feed.local, timestamp: cacheExpirationDate)
        
        XCTAssertEqual(store.commands, [.retrieve, .delete])
    }
    
    func test_validate_cacheExpired_deleteCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let cacheExpiredDate = fixedCurrentDate.maxFeedCacheAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache { _ in }
        store.completeRetrieve(with: feed.local, timestamp: cacheExpiredDate)
        
        XCTAssertEqual(store.commands, [.retrieve, .delete])
    }
    
    func test_validate_deallocatedBeforeCompletion_doesNotDeleteCache() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, date: Date.init)
        
        sut?.validateCache { _ in }
        sut = nil
        store.completeRetrieve(with: anyNSError())
        
        XCTAssertEqual(store.commands, [.retrieve])
    }
    
    func test_validate_failsOnDeletionErrorOfFailedRetrieval() {
        let (sut, store) = makeSUT()
        let error = anyNSError()
        
        expect(sut, completeWith: .failure(error), when: {
            store.completeRetrieve(with: anyNSError())
            store.completeDelete(with: error)
        })
    }
    
    func test_validate_succeedsOnSuccessfulDeletionOfFailedRetrieval() {
        let (sut, store) = makeSUT()
        
        expect(sut, completeWith: .success(()), when: {
            store.completeRetrieve(with: anyNSError())
            store.completeDelete(with: .none)
        })
    }
    
    func test_validate_succeedsOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        expect(sut, completeWith: .success(()), when: {
            store.completeRetrieveWithEmptyCache()
        })
    }
    
    func test_validate_succeedsOnNonExpiredCache() {
        let feed = uniqueImageFeed()
        let currentDate = Date()
        let validDate = currentDate.maxFeedCacheAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        expect(sut, completeWith: .success(()), when: {
            store.completeRetrieve(with: feed.local, timestamp: validDate)
        })
    }
    
    func test_validate_failsOnDeletionErrorOfExpiredCache() {
        let feed = uniqueImageFeed()
        let currentDate = Date()
        let expiredTimestamp = currentDate.maxFeedCacheAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        let error = anyNSError()
        
        expect(sut, completeWith: .failure(error), when: {
            store.completeRetrieve(with: feed.local, timestamp: expiredTimestamp)
            store.completeDelete(with: error)
        })
    }
    
    func test_validate_succeedsOnSuccessfulDeletionOfExpiredCache() {
        let feed = uniqueImageFeed()
        let currentDate = Date()
        let expiredTimestamp = currentDate.maxFeedCacheAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        expect(sut, completeWith: .success(()), when: {
            store.completeRetrieve(with: feed.local, timestamp: expiredTimestamp)
            store.completeDelete(with: .none)
        })
    }
    
    //MARK: - Helpers
        
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, date: currentDate)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, completeWith expectedResult: LocalFeedLoader.ValidationResult, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
            let exp = expectation(description: "Wait for load completion")

            sut.validateCache { receivedResult in
                switch (receivedResult, expectedResult) {
                case (.success, .success):
                    break

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
