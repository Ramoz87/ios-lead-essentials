//
//  CoreDataFeedImageDataStoreTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 19.02.2025.
//

import XCTest
import EssentialFeed

extension CoreDataFeedStore: @retroactive FeedImageDataStore {

    public func insert(_ data: Data, for url: URL, completion: @escaping (FeedImageDataStore.InsertResult) -> Void) {
    }

    public func retrieve(dataForURL url: URL, completion: @escaping (FeedImageDataStore.RetrieveResult) -> Void) {
        completion(.success(.none))
    }
}

class CoreDataFeedImageDataStoreTests: XCTestCase {
    
    func test_retrieveImageData_deliversNotFoundWhenEmpty() {
        let sut = makeSUT()
        expect(sut, completeRetrieveWith: notFound(), for: anyURL())
    }
    
    // - MARK: Private
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CoreDataFeedStore {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataFeedStore(storeUrl: storeURL, bundle: storeBundle)
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func notFound() -> FeedImageDataStore.RetrieveResult {
        return .success(.none)
    }
    
    private func expect(_ sut: CoreDataFeedStore, completeRetrieveWith expectedResult: FeedImageDataStore.RetrieveResult, for url: URL,  file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        sut.retrieve(dataForURL: url) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success( receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}
