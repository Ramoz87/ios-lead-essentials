//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Yury Ramazanov on 09.12.2024.
//

import XCTest

protocol HTTPClient {
    func get(from url: URL)
}

struct RemoteFeedLoader {
    let client: HTTPClient
    let url: URL
    
    func load() {
        client.get(from: url)
    }
}

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_shouldNotRequestDataFromUrl() {
        let (_, client) = makeSut()
        XCTAssertNil(client.requestedUrl)
    }
    
    func test_load_shouldRequestDataFromUrl() {
        let url = URL(string: "https://remote-feed-test-url.com")!
        let (sut, client) = makeSut(url: url)
        sut.load()
        XCTAssertEqual(client.requestedUrl, url)
    }
    
    //MARK: - Helpers
    
    private func makeSut(url: URL = URL(string: "https://remote-feed-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedUrl: URL?
        
        func get(from url: URL) {
            requestedUrl = url
        }
    }
}
