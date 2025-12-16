//
//  XCTestCase+FailableDeleteFeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 30.12.2024.
//

import XCTest
import EssentialFeed

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assertThatDeleteDeliversErrorOnDeletionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let deletionError = delete(from: sut)
        
        XCTAssertNotNil(deletionError, "Expected cache deletion to fail", file: file, line: line)
    }
    
    func assertThatDeleteHasNoSideEffectsOnDeletionError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        delete(from: sut)
        
        expect(sut, retrieve: .success(nil), file: file, line: line)
    }
}
