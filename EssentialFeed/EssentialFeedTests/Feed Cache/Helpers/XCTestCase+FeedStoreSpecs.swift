//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Yury Ramazanov on 30.12.2024.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    func expect(_ sut: FeedStore, retrieve expectedResult: RetrieveFeedResult, file: StaticString = #file, line: UInt = #line) {
        
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
    
    func expect(_ sut: FeedStore, retrieveTwice expectedResult: RetrieveFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, retrieve: expectedResult, file: file, line: line)
        expect(sut, retrieve: expectedResult, file: file, line: line)
    }
    
    @discardableResult
    func insert(feed: [LocalFeedImage], timestamp: Date, to sut: FeedStore) -> Error? {
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
    func delete(from sut: FeedStore) -> Error? {
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
