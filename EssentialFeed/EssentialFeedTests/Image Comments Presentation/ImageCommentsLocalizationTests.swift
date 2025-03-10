//
//  ImageCommentsLocalizationTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 10.03.2025.
//
import XCTest
import EssentialFeed

final class ImageCommentsLocalizationTests: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "ImageComments"
        let bundle = Bundle(for: ImageCommentsPresenter.self)
        assertLocalizedStringExist(in: bundle, table: table)
    }
}

