//
//  FeedItemsMapperTests.swift
//  EssentialFeedTests
//
//  Created by Yury Ramazanov on 09.12.2024.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderDataMapperTests: XCTestCase {
    
    func test_map_throwsErrorOnNon200HTTPCode() throws {
        let json = makeJSON([])
        let codes = [199, 300, 400, 500]
    
        try codes.forEach { code in
            XCTAssertThrowsError (
                try RemoteFeedLoaderDataMapper.map(json, HTTPURLResponse(statusCode: code))
            )
        }
    }
    
    func test_map_throwsErrorOn200HTTPCodeAndInvalidJSON() {
        let json = Data("invalid json".utf8)
        XCTAssertThrowsError (
            try RemoteFeedLoaderDataMapper.map(json, HTTPURLResponse(statusCode: 200))
        )
    }
    
    func test_map_deliverEmptyResultOn200HTTPCodeAndEmptyJSON() throws {
        let json = makeJSON([])
        let result = try RemoteFeedLoaderDataMapper.map(json, HTTPURLResponse(statusCode: 200))
        XCTAssertEqual(result, [])
    }
    
    func test_map_deliverResultOn200HTTPCodeAndNotEmptyJSON() throws {
        let item1 = makeItem(id: UUID(),
                             url: URL(string: "http://a-url.com")!)
        
        let item2 = makeItem(id: UUID(),
                             description: "a description",
                             location: "a location",
                             url: URL(string: "http://another-url.com")!)
        
        let items = [item1.model, item2.model]
        let json = makeJSON([item1.json, item2.json])
        let result = try RemoteFeedLoaderDataMapper.map(json, HTTPURLResponse(statusCode: 200))
        XCTAssertEqual(result, items)
    }
    
    //MARK: - Helpers
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, url: URL) -> (model: FeedImage, json: [String: Any]) {
        let item = FeedImage(id: id, description: description, location: location, url: url)
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": url.absoluteString
        ].compactMapValues { $0 }
        
        return (item, json)
    }
}
