//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Yury Ramazanov on 09.12.2024.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {

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
        expect(sut, completeWith: .failure(.connection)) {
            let error = NSError(domain: "Test", code: 0)
            client.complete(with: error)
        }
    }
    
    func test_load_withNon200HTTPCode_shouldDeliverInvalidResponseError() {
        let (sut, client) = makeSut()
        let codes = [199, 300, 400, 500]
        codes.enumerated().forEach { index, code in
            expect(sut, completeWith: .failure(.invalidResponse)) {
                client.complete(withCode: 200, data: Data(), at: index)
            }
        }
    }
    
    func test_load_with200HTTPCodeAndInvalidJSON_shouldDeliverInvalidResponseError() {
        let (sut, client) = makeSut()
        expect(sut, completeWith: .failure(.invalidResponse)) {
            client.complete(withCode: 200, data: Data())
        }
    }
    
    func test_load_with200HTTPCodeAndEmptyJSON_shouldDeliverEmptyResult() {
        let (sut, client) = makeSut()
        let items = [FeedItem]()
        expect(sut, completeWith: .success(items)) {
            client.complete(withCode: 200, data: makeJSON(items))
        }
    }
    
    func test_load_with200HTTPCodeAndNotEmptyJSON_shouldDeliverResult() {
        let (sut, client) = makeSut()
        let item1 = makeItem(id: UUID(),
                             imageURL: URL(string: "http://a-url.com")!)
        
        let item2 = makeItem(id: UUID(),
                             description: "a description",
                             location: "a location",
                             imageURL: URL(string: "http://another-url.com")!)
        
        let items = [item1, item2]
        expect(sut, completeWith: .success(items)) {
            client.complete(withCode: 200,
                            data: makeJSON(items))
        }
    }
    
    //MARK: - Helpers
    
    private func makeSut(url: URL = URL(string: "https://remote-feed-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
        
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> FeedItem {
        return FeedItem(id: id, description: description, location: location, imageURL: imageURL)
    }
    
    private func makeJSON(_ items: [FeedItem]) -> Data {
        let jsonItems = items.map { item in
            [
                "id": item.id.uuidString,
                "description": item.description,
                "location": item.location,
                "image": item.imageURL.absoluteString
            ].compactMapValues { $0 }
        }
        let json = ["items": jsonItems]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(_ sut: RemoteFeedLoader, completeWith result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestCompletionHandlers = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedUrls: [URL] {
            return requestCompletionHandlers.map(\.url)
        }
        
        func get(from url: URL, completeion: @escaping (HTTPClientResult) -> Void) {
            requestCompletionHandlers.append((url, completeion))
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
            requestCompletionHandlers[index].completion(.success(data, response))
        }
    }
}
