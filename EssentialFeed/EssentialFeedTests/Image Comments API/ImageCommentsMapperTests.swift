//
//  ImageCommentsMapperTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 05.03.2025.
//
import XCTest
import EssentialFeed

final class ImageCommentsMapperTests: XCTestCase {

    func test_map_throwErrorOnNon2xxHTTPCode() throws {
        let json = makeJSON([])
        let codes = [199, 300, 400, 500]
        
        try codes.forEach { code in
            XCTAssertThrowsError(
                try ImageCommentsMapper.map(json, HTTPURLResponse(statusCode: code))
            )
        }
    }
    
    func test_map_throwErrorOn2xxHTTPCodeAndInvalidJSON() throws {
        let json = Data("invalid json".utf8)
        let codes = [200, 201, 250, 280, 299]
        
        try codes.forEach { code in
            XCTAssertThrowsError(
                try ImageCommentsMapper.map(json, HTTPURLResponse(statusCode: code))
            )
        }
    }
    
    func test_map_deliverEmptyResultOn2xxHTTPCodeAndEmptyJSON() throws {
        let json = makeJSON([])
        let codes = [200, 201, 250, 280, 299]
        
        try codes.forEach { code in
            let result = try ImageCommentsMapper.map(json, HTTPURLResponse(statusCode: code))
            XCTAssertEqual(result, [])
        }
    }
    
    func test_map_deliverResultOn2xxHTTPCodeAndNotEmptyJSON() throws {
        let codes = [200, 201, 250, 280, 299]
        let item1 = makeItem(id: UUID(),
                             message: "a message",
                             createdAt: (Date(timeIntervalSince1970: 1598627222), "2020-08-28T15:07:02+00:00"),
                             username: "a username")
        let item2 = makeItem(id: UUID(),
                             message: "another message",
                             createdAt: (Date(timeIntervalSince1970: 1577881882), "2020-01-01T12:31:22+00:00"),
                             username: "another username")
        let items = [item1.model, item2.model]
        let json = makeJSON([item1.json, item2.json])
        
        try codes.forEach { code in
            let result = try ImageCommentsMapper.map(json, HTTPURLResponse(statusCode: code))
            XCTAssertEqual(result, items)
        }
    }
    
    //MARK: - Helpers
    
    private func makeItem(id: UUID, message: String, createdAt: (date: Date, iso8601String: String), username: String) -> (model: ImageComment, json: [String: Any]) {
        let item = ImageComment(id: id, message: message, createdAt: createdAt.date, username: username)
        let json: [String: Any] = [
            "id": id.uuidString,
            "message": message,
            "created_at": createdAt.iso8601String,
            "author": [
                "username": username
            ]
        ]
        return (item, json)
    }
}
