//
//  CoreDataFeedImageDataStoreTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 19.02.2025.
//

import XCTest
import EssentialFeed

class CoreDataFeedImageDataStoreTests: XCTestCase {
    
    func test_retrieveImageData_deliversNotFoundWhenEmpty() {
        makeSUT { sut in
            expect(sut, completeRetrieveWith: notFound(), for: anyURL())
        }
    }
    
    func test_retrieveImageData_deliversNotFoundWhenStoredDataURLDoesNotMatch() {
        makeSUT { sut in
            let url = URL(string: "http://a-url.com")!
            let anotherURL = URL(string: "http://another-url.com")!
            
            insert(anyData(), for: url, into: sut)
            
            expect(sut, completeRetrieveWith: notFound(), for: anotherURL)
        }
    }
    
    func test_retrieveImageData_deliversFoundDataWhenThereIsAStoredImageDataMatchingURL() {
        makeSUT { sut in
            let data = anyData()
            let url = anyURL()
            
            insert(data, for: url, into: sut)
            
            expect(sut, completeRetrieveWith: found(data), for: url)
        }
    }
    
    func test_retrieveImageData_deliversLastInsertedValue() {
        makeSUT { sut in
            let firstStoredData = Data("first".utf8)
            let lastStoredData = Data("last".utf8)
            let url = anyURL()
            
            insert(firstStoredData, for: url, into: sut)
            insert(lastStoredData, for: url, into: sut)
            
            expect(sut, completeRetrieveWith: found(lastStoredData), for: url)
        }
    }
    
    // - MARK: Private
    
    private func makeSUT(_ test: @escaping (CoreDataFeedStore) -> Void, file: StaticString = #file, line: UInt = #line) {
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataFeedStore(storeUrl: storeURL)
        trackMemoryLeaks(sut, file: file, line: line)
        
        let exp = expectation(description: "wait for operation")
        sut.perform {
            test(sut)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 0.1)
    }
}

private func notFound() -> Result<Data?, Error> {
    return .success(.none)
}

private func found(_ data: Data) -> Result<Data?, Error> {
    return .success(data)
}

private func localImage(url: URL) -> LocalFeedImage {
    return LocalFeedImage(id: UUID(), description: "any", location: "any", url: url)
}

private func expect(_ sut: CoreDataFeedStore, completeRetrieveWith expectedResult: Result<Data?, Error>, for url: URL, file: StaticString = #file, line: UInt = #line) {

    let receivedResult = Result { try sut.retrieve(dataForURL: url) }
    switch (receivedResult, expectedResult) {
    case let (.success( receivedData), .success(expectedData)):
        XCTAssertEqual(receivedData, expectedData, file: file, line: line)
        
    default:
        XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
    }
}

private func insert(_ data: Data, for url: URL, into sut: CoreDataFeedStore, file: StaticString = #file, line: UInt = #line) {
    let image = localImage(url: url)
    
    do {
        try sut.insert([image], timestamp: Date())
        try sut.insert(data, for: url)
    } catch {
        XCTFail("Failed to insert \(data) with error \(error)", file: file, line: line)
    }
}
