//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Yury Ramazanov on 30.12.2024.
//

import XCTest
import EssentialFeed

func expect(_ sut: FeedStore, retrieve expectedResult: Result<CachedFeed?, Error>, file: StaticString = #filePath, line: UInt = #line) {
    
    let retrieveResult = Result { try sut.retrieve() }
    
    switch (retrieveResult, expectedResult) {
    case (.success(nil), .success(nil)),
        (.failure, .failure):
        break
        
    case let (.success(.some(retrieved)), .success(.some(expected))):
        XCTAssertEqual(retrieved.feed, expected.feed, file: file, line: line)
        XCTAssertEqual(retrieved.timestamp, expected.timestamp, file: file, line: line)
        
    default:
        XCTFail("Expected to retrieve \(expectedResult), got \(retrieveResult) instead", file: file, line: line)
    }
}

func expect(_ sut: FeedStore, retrieveTwice expectedResult: Result<CachedFeed?, Error>, file: StaticString = #filePath, line: UInt = #line) {
    expect(sut, retrieve: expectedResult, file: file, line: line)
    expect(sut, retrieve: expectedResult, file: file, line: line)
}

@discardableResult
func insert(feed: [LocalFeedImage], timestamp: Date, to sut: FeedStore) -> Error? {
    do {
        try sut.insert(feed, timestamp: timestamp)
        return nil
    } catch {
        return error
    }
}

@discardableResult
func delete(from sut: FeedStore) -> Error? {
    do {
        try sut.deleteCachedFeed()
        return nil
    } catch {
        return error
    }
}

func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
    expect(sut, retrieve: .success(nil), file: file, line: line)
}

func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
    expect(sut, retrieveTwice: .success(nil), file: file, line: line)
}

func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
    let feed = uniqueImageFeed().local
    let timestamp = Date()
    
    insert(feed: feed, timestamp: timestamp, to: sut)
    
    expect(sut, retrieve: .success(CachedFeed(feed: feed, timestamp: timestamp)), file: file, line: line)
}

func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
    let feed = uniqueImageFeed().local
    let timestamp = Date()
    
    insert(feed: feed, timestamp: timestamp, to: sut)
    
    expect(sut, retrieveTwice: .success(CachedFeed(feed: feed, timestamp: timestamp)), file: file, line: line)
}

func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
    let insertionError = insert(feed:uniqueImageFeed().local, timestamp: Date(), to: sut)
    
    XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
}

func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
    insert(feed:uniqueImageFeed().local, timestamp: Date(), to: sut)
    
    let insertionError = insert(feed:uniqueImageFeed().local, timestamp: Date(), to: sut)
    
    XCTAssertNil(insertionError, "Expected to override cache successfully", file: file, line: line)
}

func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
    insert(feed:uniqueImageFeed().local, timestamp: Date(), to: sut)
    
    let latestFeed = uniqueImageFeed().local
    let latestTimestamp = Date()
    insert(feed:latestFeed, timestamp: latestTimestamp, to: sut)
    
    expect(sut, retrieve: .success(CachedFeed(feed: latestFeed, timestamp: latestTimestamp)), file: file, line: line)
}

func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
    let deletionError = delete(from: sut)
    
    XCTAssertNil(deletionError, "Expected empty cache deletion to succeed", file: file, line: line)
}

func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
    delete(from: sut)
    
    expect(sut, retrieve: .success(nil), file: file, line: line)
}

func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
    insert(feed:uniqueImageFeed().local, timestamp: Date(), to: sut)
    
    let deletionError = delete(from: sut)
    
    XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed", file: file, line: line)
}

func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
    insert(feed:uniqueImageFeed().local, timestamp: Date(), to: sut)
    
    delete(from: sut)
    
    expect(sut, retrieve: .success(nil), file: file, line: line)
}
