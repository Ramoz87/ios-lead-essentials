//
//  FeedViewControllerTests+Localization.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 28.01.2025.
//
import Foundation
import EssentialFeediOS
import XCTest

extension FeedUIIntegrationTests {
    func localized(_ key: String, file: StaticString = #file, line: UInt = #line) -> String {
            let table = "Feed"
            let bundle = Bundle(for: FeedViewController.self)
            let value = bundle.localizedString(forKey: key, value: nil, table: table)
            if value == key {
                XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
            }
            return value
        }
}
