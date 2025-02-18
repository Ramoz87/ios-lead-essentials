//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Yury Ramazanov on 09.12.2024.
//

import XCTest
import EssentialFeed

final class LoadFeedFromRemoteUseCaseTests: XCTestCase {

    func test_init_shouldNotRequestDataFromUrl() {
        let (_, client) = makeSut()
        XCTAssertTrue(client.requestedUrls.isEmpty)
    }
    
    func test_load_shouldRequestDataFromUrl() {
        let url = URL(string: "https://remote-feed-test-url.com")!
        let (sut, client) = makeSut(url: url)
        sut.load {_ in }
        XCTAssertEqual(client.requestedUrls, [url])
    }
    
    func test_load_twice_shouldRequestDataFromUrlTwice() {
        let url = URL(string: "https://remote-feed-test-url.com")!
        let (sut, client) = makeSut(url: url)
        sut.load {_ in }
        sut.load {_ in }
        XCTAssertEqual(client.requestedUrls, [url, url])
    }
    
    func test_load_withConnectionError_shouldDeliverConnectionError() {
        let (sut, client) = makeSut()
        expect(sut, completeWith: failure(.connection)) {
            let error = NSError(domain: "Test", code: 0)
            client.complete(with: error)
        }
    }
    
    func test_load_withNon200HTTPCode_shouldDeliverInvalidResponseError() {
        let (sut, client) = makeSut()
        let codes = [199, 300, 400, 500]
        codes.enumerated().forEach { index, code in
            expect(sut, completeWith: failure(.invalidResponse)) {
                client.complete(withCode: 200, data: Data(), at: index)
            }
        }
    }
    
    func test_load_with200HTTPCodeAndInvalidJSON_shouldDeliverInvalidResponseError() {
        let (sut, client) = makeSut()
        expect(sut, completeWith: failure(.invalidResponse)) {
            client.complete(withCode: 200, data: Data())
        }
    }
    
    func test_load_with200HTTPCodeAndEmptyJSON_shouldDeliverEmptyResult() {
        let (sut, client) = makeSut()
        let items = [FeedImage]()
        expect(sut, completeWith: .success(items)) {
            client.complete(withCode: 200, data: makeJSON(items))
        }
    }
    
    func test_load_with200HTTPCodeAndNotEmptyJSON_shouldDeliverResult() {
        let (sut, client) = makeSut()
        let item1 = makeItem(id: UUID(),
                             url: URL(string: "http://a-url.com")!)
        
        let item2 = makeItem(id: UUID(),
                             description: "a description",
                             location: "a location",
                             url: URL(string: "http://another-url.com")!)
        
        let items = [item1, item2]
        expect(sut, completeWith: .success(items)) {
            client.complete(withCode: 200,
                            data: makeJSON(items))
        }
    }
    
    func test_load_deallocatedBeforeCompletion_shouldNotDeliverResult() {
        let client = HTTPClientSpy()
        let url = URL(string: "https://remote-feed-test-url.com")!
        var sut: RemoteFeedLoader? = RemoteFeedLoader(client: client, url: url)
    
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }
        sut = nil
        client.complete(withCode: 200, data: makeJSON([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    //MARK: - Helpers
    
    private func makeSut(url: URL = URL(string: "https://remote-feed-url.com")!, file: StaticString = #file, line: UInt = #line) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        trackMemoryLeaks(client, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
        
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, url: URL) -> FeedImage {
        return FeedImage(id: id, description: description, location: location, url: url)
    }
    
    private func makeJSON(_ items: [FeedImage]) -> Data {
        let jsonItems = items.map { item in
            [
                "id": item.id.uuidString,
                "description": item.description,
                "location": item.location,
                "image": item.url.absoluteString
            ].compactMapValues { $0 }
        }
        let json = ["items": jsonItems]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(_ sut: RemoteFeedLoader, completeWith expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        let exp = expectation(description: "Wait for RemoteFeedLoader load completion")
        sut.load { recievedResult in
         
            switch(recievedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult) got \(recievedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1)
    }
    
    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }
    
    private class HTTPClientSpy: HTTPClient {
        
        private struct Task: HTTPClientTask {
            func cancel() {}
        }
        
        var requestCompletionHandlers = [(url: URL, completion: (HTTPClient.Result) -> Void)]()
        
        var requestedUrls: [URL] {
            return requestCompletionHandlers.map(\.url)
        }
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
            requestCompletionHandlers.append((url, completion))
            return Task()
        }
        
        func complete(with error: Error, at index: Int = 0) {
            requestCompletionHandlers[index].completion(.failure(error))
        }
        
        func complete(withCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedUrls[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            requestCompletionHandlers[index].completion(.success((data, response)))
        }
    }
}
