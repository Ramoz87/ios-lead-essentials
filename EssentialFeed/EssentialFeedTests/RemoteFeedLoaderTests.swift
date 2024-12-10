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
        
        var capturedErrors = [RemoteFeedLoader.Result]()
        sut.load { capturedErrors.append($0) }
        
        let error = NSError(domain: "Test", code: 0)
        client.requestCompletionHandlers.last?.completion(.failure(error))
        
        XCTAssertEqual(capturedErrors, [.failure(.connection)])
    }
    
    func test_load_withNon200HTTPCode_shouldDeliverInvalidResponseError() {
        let (sut, client) = makeSut()
        
        let codes = [199, 300, 400, 500]
        
        codes.enumerated().forEach { index, code in
            var capturedErrors = [RemoteFeedLoader.Result]()
            sut.load { capturedErrors.append($0) }
            
            let response = response(url: client.requestedUrls[index], code: code)
            let data = Data()
            client.requestCompletionHandlers.last?.completion(.success(data, response))
            
            XCTAssertEqual(capturedErrors, [.failure(.invalidResponse)])
        }
    }
    
    func test_load_with200HTTPCodeAndInvalidJSON_shouldDeliverInvalidResponseError() {
        let (sut, client) = makeSut()
        
        var capturedErrors = [RemoteFeedLoader.Result]()
        sut.load { capturedErrors.append($0) }
        
        let response = response(url: client.requestedUrls.last!, code: 200)
        let data = Data()
        client.requestCompletionHandlers.last?.completion(.success(data, response))
        
        XCTAssertEqual(capturedErrors, [.failure(.invalidResponse)])
    }
    
    func test_load_with200HTTPCodeAndEmptyJSON_shouldDeliverEmptyResult() {
        let (sut, client) = makeSut()
        
        var capturedErrors = [RemoteFeedLoader.Result]()
        sut.load { capturedErrors.append($0) }
        
        let response = response(url: client.requestedUrls.last!, code: 200)
        let data = makeJSON([])
        client.requestCompletionHandlers.last?.completion(.success(data, response))
        
        XCTAssertEqual(capturedErrors, [.success([])])
    }
    
    func test_load_with200HTTPCodeAndNotEmptyJSON_shouldDeliverResult() {
        let (sut, client) = makeSut()
        
        var capturedErrors = [RemoteFeedLoader.Result]()
        sut.load { capturedErrors.append($0) }
        
        let response = response(url: client.requestedUrls.last!, code: 200)
        
        let item1 = makeItem(id: UUID(),
                             imageURL: URL(string: "http://a-url.com")!)
        
        let item2 = makeItem(id: UUID(),
                             description: "a description",
                             location: "a location",
                             imageURL: URL(string: "http://another-url.com")!)
        
        let items = [item1, item2]
        let data = makeJSON(items)
        client.requestCompletionHandlers.last?.completion(.success(data, response))
        
        XCTAssertEqual(capturedErrors, [.success(items)])
    }
    
    //MARK: - Helpers
    
    private func makeSut(url: URL = URL(string: "https://remote-feed-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private func response(url: URL, code: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: nil)!
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
    
    
    private class HTTPClientSpy: HTTPClient {
        var requestCompletionHandlers = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedUrls: [URL] {
            return requestCompletionHandlers.map(\.url)
        }
        
        func get(from url: URL, completeion: @escaping (HTTPClientResult) -> Void) {
            requestCompletionHandlers.append((url, completeion))
        }
    }
}
