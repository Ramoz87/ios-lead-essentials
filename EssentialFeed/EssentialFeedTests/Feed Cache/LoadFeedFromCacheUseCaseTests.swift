//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 24.12.2024.
//

import XCTest
import EssentialFeed

@MainActor 
final class LoadFeedFromCacheUseCaseTests: XCTestCase {
    
    func test_init_doesNotPerformAnyCommands() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.commands, [])
    }
    
    func test_load_performRetrieve() {
        let (sut, store) = makeSUT()
        _ = try? sut.load()
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
        
        store.completeRetrieve(with: anyNSError())
        _ = try? sut.load()
    
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
        
        store.completeRetrieveWithEmptyCache()
        _ = try? sut.load()
        
        XCTAssertEqual(store.commands, [.retrieve])
    }
    
    func test_load_cacheNotExpired_completeWithResult() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanCacheExpirationDate = fixedCurrentDate.maxFeedCacheAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, completeWith: .success(feed.models), when: {
            store.completeRetrieve(with: feed.local, timestamp: lessThanCacheExpirationDate)
        })
    }
    
    func test_load_cacheNotExpired_hasNoSideEffects() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanCacheExpirationDate = fixedCurrentDate.maxFeedCacheAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        store.completeRetrieve(with: feed.local, timestamp: lessThanCacheExpirationDate)
        _ = try? sut.load()
        
        XCTAssertEqual(store.commands, [.retrieve])
    }
    
    func test_load_cacheExpirationDate_completeWithEmptyResult() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let cacheExpirationDate = fixedCurrentDate.maxFeedCacheAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, completeWith: .success([]), when: {
            store.completeRetrieve(with: feed.local, timestamp: cacheExpirationDate)
        })
    }
    
    func test_load_cacheExpirationDate_hasNoSideEffects() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let cacheExpirationDate = fixedCurrentDate.maxFeedCacheAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        store.completeRetrieve(with: feed.local, timestamp: cacheExpirationDate)
        _ = try? sut.load()
        
        XCTAssertEqual(store.commands, [.retrieve])
    }
    
    
    func test_load_cacheExpired_completeWithEmptyResult() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let cacheExpiredDate = fixedCurrentDate.maxFeedCacheAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, completeWith: .success([]), when: {
            store.completeRetrieve(with: feed.local, timestamp: cacheExpiredDate)
        })
    }
    
    func test_load_cacheExpired_hasNoSideEffects() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let cacheExpiredDate = fixedCurrentDate.maxFeedCacheAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        store.completeRetrieve(with: feed.local, timestamp: cacheExpiredDate)
        _ = try? sut.load()
        
        XCTAssertEqual(store.commands, [.retrieve])
    }
    
    //MARK: - Helpers
        
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, date: currentDate)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
 
    private func expect(_ sut: LocalFeedLoader, completeWith expectedResult: Result<[FeedImage], Error>, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        action()
        
        let receivedResult = Result { try sut.load() }
        switch (receivedResult, expectedResult) {
        case let (.success(receivedImages), .success(expectedImages)):
            XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
            
        case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
            XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            
        default:
            XCTFail("Expected result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
        }
        
    }
}
