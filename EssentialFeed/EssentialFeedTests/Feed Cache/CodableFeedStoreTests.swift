//
//  CodableFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 27.12.2024.
//

import XCTest
import EssentialFeed

final class CodableFeedStore {
    
    private let storeUrl: URL
    
    init(storeUrl: URL) {
        self.storeUrl = storeUrl
    }
    
    func retrieve(completion: @escaping FeedStore.RetrieveCompletion) {
        guard let data = try? Data(contentsOf: storeUrl) else {
            return completion(.empty)
        }
        
        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertCompletion) {
        do {
            let encoder = JSONEncoder()
            let codableFeed = feed.map(CodableFeedImage.init)
            let cache = Cache(feed: codableFeed, timestamp: timestamp)
            let encoded = try encoder.encode(cache)
            try encoded.write(to: storeUrl)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    func deleteCachedFeed(completion: @escaping FeedStore.DeleteCompletion) {
        guard FileManager.default.fileExists(atPath: storeUrl.path) else {
            return completion(nil)
        }
        
        try! FileManager.default.removeItem(at: storeUrl)
        completion(nil)
    }
}

extension CodableFeedStore {
    
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            return feed.map { $0.local }
        }
    }
    
    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id,
                                  description: description,
                                  location: location,
                                  url: url)
        }
    }
}

final class CodableFeedStoreTests: XCTestCase {
    
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
    
    func test_retrieve_emptyCacheTwice_deliverEmptyResultTwice(){
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
    
    func test_retrieve_noEmptyCacheTwice_deliverCacheTwice() {
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
    
    func test_retrieve_retrieveErrorTwice_deliverErrorTwice() {
        let storeUrl = testStoreUrl
        let sut = makeSUT(url: storeUrl)
        
        try! "invalid data".write(to: storeUrl, atomically: false, encoding: .utf8)
        
        expect(sut, retrieveTwice: .failure(anyNSError()))
    }
    
    
    func test_insert_noEmptyCache_overrideCache() {
        let sut = makeSUT()
        
        let firstFeed = uniqueImageFeed().local
        let firstTimestamp = Date()
        let firstInsertionError = insert(feed: firstFeed, timestamp: firstTimestamp, to: sut)
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")
        
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        let latestInsertionError = insert(feed: latestFeed, timestamp: latestTimestamp, to: sut)
        XCTAssertNil(latestInsertionError, "Expected to override cache successfully")
        
        expect(sut, retrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    func test_insert_insertError_deliverError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(url: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        let insertionError = insert(feed: feed, timestamp: timestamp, to: sut)
        
        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
        expect(sut, retrieve: .empty)
    }
    
    
    func test_delete_emptyCache_cacheIsEmpty() {
        let sut = makeSUT()
        
        let deletionError = delete(from: sut)
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
        
        expect(sut, retrieve: .empty)
    }
    
    func test_delete_noEmptyCache_cacheIsEmpty() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(feed: feed, timestamp: timestamp, to: sut)
        let deletionError = delete(from: sut)
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
        
        expect(sut, retrieve: .empty)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(url: URL? = nil, file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeUrl: url ?? testStoreUrl)
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private var testStoreUrl: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
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
    
    private func expect(_ sut: CodableFeedStore, retrieve expectedResult: RetrieveFeedResult, file: StaticString = #file, line: UInt = #line) {
        
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
    
    private func expect(_ sut: CodableFeedStore, retrieveTwice expectedResult: RetrieveFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, retrieve: expectedResult, file: file, line: line)
        expect(sut, retrieve: expectedResult, file: file, line: line)
    }
    
    @discardableResult
    private func insert(feed: [LocalFeedImage], timestamp: Date, to sut: CodableFeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insert")
        var error: Error?
        sut.insert(feed, timestamp: timestamp) { insertError in
            error = insertError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return error
    }
    
    private func delete(from sut: CodableFeedStore) -> Error? {
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
