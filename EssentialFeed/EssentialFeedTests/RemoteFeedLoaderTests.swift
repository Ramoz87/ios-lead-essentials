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
        sut.load()
        XCTAssertEqual(client.requestedUrls, [url])
    }
    
    func test_loadTwice_shouldRequestDataFromUrlTwice() {
        let url = URL(string: "https://remote-feed-test-url.com")!
        let (sut, client) = makeSut(url: url)
        sut.load()
        sut.load()
        XCTAssertEqual(client.requestedUrls, [url, url])
    }
    
    //MARK: - Helpers
    
    private func makeSut(url: URL = URL(string: "https://remote-feed-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedUrls = [URL]()
        
        func get(from url: URL) {
            requestedUrls.append(url)
        }
    }
}
