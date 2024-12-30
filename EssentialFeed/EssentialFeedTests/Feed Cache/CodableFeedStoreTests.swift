//
//  CodableFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 27.12.2024.
//

import XCTest
import EssentialFeed

protocol FeedStoreSpecs {

    func test_retrieve_emptyCache_deliverEmptyResult()
    func test_retrieve_emptyCache_noSideEffect()
    func test_retrieve_noEmptyCache_deliverCache()
    func test_retrieve_noEmptyCache_noSideEffect()

    func test_insert_emptyCache_deliverNoError()
    func test_insert_noEmptyCache_deliverNoError()
    func test_insert_noEmptyCache_overrideCache()

    func test_delete_emptyCache_deliverNoError()
    func test_delete_emptyCache_noSideEffect()
    func test_delete_noEmptyCache_deliverNoError()
    func test_delete_noEmptyCache_deleteCache()

    func test_sideEffectOperationsRunSerially()
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieve_retrieveError_deliverError()
    func test_retrieve_retrieveError_noSideEffect()
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_insertError_deliverError()
    func test_insert_insertError_noSideEffect()
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deleteError_deliverError()
    func test_delete_deleteError_noSideEffect()
}

typealias FailableFeedStoreSpecs = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs

final class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }
    
    func test_retrieve_emptyCache_deliverEmptyResult(){
        let sut = makeSUT()
        expect(sut, retrieve: .empty)
    }
    
    func test_retrieve_emptyCache_noSideEffect(){
        let sut = makeSUT()
        expect(sut, retrieveTwice: .empty)
    }
    
    func test_retrieve_noEmptyCache_deliverCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
       
        insert(feed: feed, timestamp: timestamp, to: sut)
        expect(sut, retrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieve_noEmptyCache_noSideEffect() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(feed: feed, timestamp: timestamp, to: sut)
        expect(sut, retrieveTwice: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieve_retrieveError_deliverError() {
        let storeUrl = testStoreUrl
        let sut = makeSUT(url: storeUrl)
        
        try! "invalid data".write(to: storeUrl, atomically: false, encoding: .utf8)
        
        expect(sut, retrieve: .failure(anyNSError()))
    }
    
    func test_retrieve_retrieveError_noSideEffect() {
        let storeUrl = testStoreUrl
        let sut = makeSUT(url: storeUrl)
        
        try! "invalid data".write(to: storeUrl, atomically: false, encoding: .utf8)
        
        expect(sut, retrieveTwice: .failure(anyNSError()))
    }
    
    
    func test_insert_emptyCache_deliverNoError() {
        let sut = makeSUT()
        
        let insertionError = insert(feed: uniqueImageFeed().local, timestamp: Date(), to: sut)
        
        XCTAssertNil(insertionError, "Expected to insert cache successfully")
    }
    
    func test_insert_noEmptyCache_deliverNoError() {
        let sut = makeSUT()

        insert(feed: uniqueImageFeed().local, timestamp: Date(), to: sut)
        let latestInsertionError = insert(feed: uniqueImageFeed().local, timestamp: Date(), to: sut)
        
        XCTAssertNil(latestInsertionError, "Expected to override cache successfully")
    }
    
    func test_insert_noEmptyCache_overrideCache() {
        let sut = makeSUT()
        
        let firstFeed = uniqueImageFeed().local
        let firstTimestamp = Date()
        insert(feed: firstFeed, timestamp: firstTimestamp, to: sut)
        
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        insert(feed: latestFeed, timestamp: latestTimestamp, to: sut)
        
        expect(sut, retrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    func test_insert_insertError_deliverError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(url: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        let insertionError = insert(feed: feed, timestamp: timestamp, to: sut)
        
        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
    }
    
    func test_insert_insertError_noSideEffect() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(url: invalidStoreURL)
        
        insert(feed: uniqueImageFeed().local, timestamp: Date(), to: sut)
        
        expect(sut, retrieve: .empty)
    }
    
    
    func test_delete_emptyCache_deliverNoError() {
        let sut = makeSUT()
        let deletionError = delete(from: sut)
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
    }
    
    func test_delete_emptyCache_noSideEffect() {
        let sut = makeSUT()
        
        delete(from: sut)

        expect(sut, retrieve: .empty)
    }
    
    func test_delete_noEmptyCache_deliverNoError() {
        let sut = makeSUT()
        
        insert(feed: uniqueImageFeed().local, timestamp: Date(), to: sut)
        let deletionError = delete(from: sut)
        
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
    }
    
    func test_delete_noEmptyCache_deleteCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(feed: feed, timestamp: timestamp, to: sut)
        delete(from: sut)
        
        expect(sut, retrieve: .empty)
    }
    
    func test_delete_deleteError_deliverError() {
        let noDeletePermissionURL = cachesDirectory
        let sut = makeSUT(url: noDeletePermissionURL)
        
        let deletionError = delete(from: sut)
        XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
    }
    
    func test_delete_deleteError_noSideEffect() {
        let noDeletePermissionURL = cachesDirectory
        let sut = makeSUT(url: noDeletePermissionURL)
        
        delete(from: sut)
        expect(sut, retrieve: .empty)
    }
    
    
    func test_sideEffectOperationsRunSerially() {
        let sut = makeSUT()
        var completeOperations = [XCTestExpectation]()
        
        let op1 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completeOperations.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completeOperations.append(op2)
            op2.fulfill()
        }
        
        let op3 = expectation(description: "Operation 3")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completeOperations.append(op3)
            op3.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        
        XCTAssertEqual(completeOperations, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order")
    }
    
    //MARK: - Helpers
    
    private func makeSUT(url: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeUrl: url ?? testStoreUrl)
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private var testStoreUrl: URL {
        cachesDirectory.appendingPathComponent("\(type(of: self)).store")
    }
    
    private var cachesDirectory: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testStoreUrl)
    }
    
    private func expect(_ sut: FeedStore, retrieve expectedResult: RetrieveFeedResult, file: StaticString = #file, line: UInt = #line) {
        
        let exp = expectation(description: "Wait for cache retrieval")
        sut.retrieve { retrieveResult in
           
            switch (retrieveResult, expectedResult) {
            case (.empty, .empty),
                (.failure, .failure):
                break
                
            case let (.found(retrieveFeed, retrieveTimestamp), .found(expectedFeed, expectedTimestamp)):
                XCTAssertEqual(retrieveFeed, expectedFeed, file: file, line: line)
                XCTAssertEqual(retrieveTimestamp, expectedTimestamp, file: file, line: line)
                
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrieveResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func expect(_ sut: FeedStore, retrieveTwice expectedResult: RetrieveFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, retrieve: expectedResult, file: file, line: line)
        expect(sut, retrieve: expectedResult, file: file, line: line)
    }
    
    @discardableResult
    private func insert(feed: [LocalFeedImage], timestamp: Date, to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insert")
        var error: Error?
        sut.insert(feed, timestamp: timestamp) { insertError in
            error = insertError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return error
    }
    
    @discardableResult
    private func delete(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache delete")
        var error: Error?
        sut.deleteCachedFeed { deleteError in
            error = deleteError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return error
    }
}
