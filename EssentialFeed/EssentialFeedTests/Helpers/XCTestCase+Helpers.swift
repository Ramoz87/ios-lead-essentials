//
//  XCTestCase+Helpers.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 23.12.2024.
//

import XCTest

extension XCTestCase {
    func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    func anyNSError() -> NSError {
        return NSError(domain: "Test Error", code: 0)
    }
}
