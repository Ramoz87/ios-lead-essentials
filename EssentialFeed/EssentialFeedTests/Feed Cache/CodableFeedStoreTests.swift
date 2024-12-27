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
        
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertCompletion) {
        let encoder = JSONEncoder()
        let codableFeed = feed.map(CodableFeedImage.init)
        let cache = Cache(feed: codableFeed, timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeUrl)
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
    
    func test_retrieve_fromEmptyCache_deliverEmptyResult(){
        let sut = makeSUT()
        
        let exp = expectation(description: "Wait for cache retrieval")
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_retrieve_fromEmptyCacheTwice_deliverEmptyResultTwice(){
        let sut = makeSUT()
        
        let exp = expectation(description: "Wait for cache retrieval")
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected retrieving twice from empty cache to deliver same empty result, got \(firstResult) and \(secondResult) instead")
                }
                
                exp.fulfill()
            }
            
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_retrieve_afterInsertNewCache_deliverInsertedCache() {
        let sut = makeSUT()
        let insertFeed = uniqueImageFeed().local
        let insertTimestamp = Date()
        let exp = expectation(description: "Wait for cache retrieval")
        
        sut.insert(insertFeed, timestamp: insertTimestamp) { insertError in
            XCTAssertNil(insertError, "Expected feed to be inserted successfully")
            
            sut.retrieve { retrieveResult in
                switch retrieveResult {
                case let .found(retrieveFeed, retrieveTimestamp):
                    XCTAssertEqual(retrieveFeed, insertFeed)
                    XCTAssertEqual(retrieveTimestamp, insertTimestamp)
                    
                default:
                    XCTFail("Expected found result with feed \(insertFeed) and timestamp \(insertTimestamp), got \(retrieveResult) instead")
                }
                
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeUrl: testStoreUrl)
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
}
