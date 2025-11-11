//
//  CoreDataFeedImageDataStoreTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 19.02.2025.
//

import XCTest
import EssentialFeed

@MainActor
class CoreDataFeedImageDataStoreTests: XCTestCase, FeedImageDataStoreSpecs{
    
    func test_retrieveImageData_deliversNotFoundWhenEmpty() throws {
        try makeSUT { sut, url in
            assertThatRetrieveImageDataDeliversNotFoundOnEmptyCache(on: sut, imageDataURL: url)
        }
    }
    
    func test_retrieveImageData_deliversNotFoundWhenStoredDataURLDoesNotMatch() throws {
        try makeSUT { sut, url in
            assertThatRetrieveImageDataDeliversNotFoundWhenStoredDataURLDoesNotMatch(on: sut, imageDataURL: url)
        }
    }
    
    func test_retrieveImageData_deliversFoundDataWhenThereIsAStoredImageDataMatchingURL() throws {
        try makeSUT { sut, imageDataURL in
            assertThatRetrieveImageDataDeliversFoundDataWhenThereIsAStoredImageDataMatchingURL(on: sut, imageDataURL: imageDataURL)
        }
    }
    
    func test_retrieveImageData_deliversLastInsertedValue() throws {
        try makeSUT { sut, imageDataURL in
            assertThatRetrieveImageDataDeliversLastInsertedValueForURL(on: sut, imageDataURL: imageDataURL)
        }
    }
    
    // - MARK: Private
    
    private func makeSUT(_ test: @Sendable @escaping (CoreDataFeedStore, URL) -> Void, file: StaticString = #file, line: UInt = #line) throws {
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try CoreDataFeedStore(storeUrl: storeURL)
        trackMemoryLeaks(sut, file: file, line: line)
        
        let exp = expectation(description: "wait for operation")
        sut.perform {
            let imageDataURL = URL(string: "http://a-url.com")!
            insertFeedImage(with: imageDataURL, into: sut, file: file, line: line)
            test(sut, imageDataURL)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 0.1)
    }
}

private func insertFeedImage(with url: URL, into sut: CoreDataFeedStore, file: StaticString = #filePath, line: UInt = #line) {
    let image = LocalFeedImage(id: UUID(), description: "any", location: "any", url: url)
    do {
        try sut.insert([image], timestamp: Date())
    } catch {
        XCTFail("Failed to insert feed image with URL \(url) - error: \(error)", file: file, line: line)
    }
}
