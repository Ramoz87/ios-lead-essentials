//
//  XCTestCase+MemoryLeaks.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 13.12.2024.
//

import XCTest

extension XCTestCase {
    func trackMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
