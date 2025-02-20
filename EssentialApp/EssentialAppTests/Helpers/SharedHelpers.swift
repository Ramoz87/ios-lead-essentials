//
//  SharedHelpers.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 20.02.2025.
//

import Foundation

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}

func anyNSError() -> NSError {
    return NSError(domain: "Test Error", code: 0)
}

func anyData() -> Data {
    return Data("any data".utf8)
}
