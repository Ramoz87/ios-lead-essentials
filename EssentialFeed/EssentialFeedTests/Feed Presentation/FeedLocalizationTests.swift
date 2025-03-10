//
//  FeedLocalizationTests.swift
//  EssentialFeediOSTests
//
//  Created by Yury Ramazanov on 28.01.2025.
//

import XCTest
import EssentialFeed

final class FeedLocalizationTests: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Feed"
        let bundle = Bundle(for: FeedPresenter.self)
        assertLocalizedStringExist(in: bundle, table: table)
    }
}
