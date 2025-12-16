//
//  XCTestcCase+FailableInsertFeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 30.12.2024.
//

import XCTest
import EssentialFeed

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let insertionError = insert(feed:uniqueImageFeed().local, timestamp: Date(), to: sut)
        
        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error", file: file, line: line)
    }
    
    func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(feed: uniqueImageFeed().local, timestamp: Date(), to: sut)
        
        expect(sut, retrieve: .success(nil), file: file, line: line)
    }
}
