//
//  LoadFeedImageDataFromRemoteUseCaseTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 18.02.2025.
//

import XCTest
import EssentialFeed

class LoadFeedImageDataFromRemoteUseCaseTests: XCTestCase {
    
    func test_map_throwsErrorOnNon200HTTPResponse() throws {
        let codes = [199, 300, 400, 500]
        
        try codes.forEach { code in
            XCTAssertThrowsError(
                try RemoteFeedImageDataMapper.map(anyData(), from: HTTPURLResponse(statusCode: code))
            )
        }
    }
    
    func test_map_deliversInvalidDataErrorOn200HTTPResponseWithEmptyData() {
        XCTAssertThrowsError(
            try RemoteFeedImageDataMapper.map(Data(), from: HTTPURLResponse(statusCode: 200))
        )
    }
    
    func test_map_deliversReceivedNonEmptyDataOn200HTTPResponse() throws {
        let data = anyData()
        let result = try RemoteFeedImageDataMapper.map(data, from: HTTPURLResponse(statusCode: 200))
        XCTAssertEqual(result, data)
    }
}
