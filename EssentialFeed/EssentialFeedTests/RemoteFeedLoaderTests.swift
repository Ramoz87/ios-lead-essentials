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
    
    //MARK: - Helpers
    
    private func makeSut(url: URL = URL(string: "https://remote-feed-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private func response(url: URL, code: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: nil)!
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
