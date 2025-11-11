//
//  InMemoryFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 10.04.2025.
//

import XCTest
import EssentialFeed

@MainActor 
class InMemoryFeedStoreTests: XCTestCase, FeedStoreSpecs {
    
	func test_retrieve_emptyCache_deliverEmptyResult() throws {
		let sut = makeSUT()

		assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
	}

	func test_retrieve_emptyCache_noSideEffect() throws {
		let sut = makeSUT()

		assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
	}

	func test_retrieve_noEmptyCache_deliverCache() throws {
		let sut = makeSUT()

		assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
	}

	func test_retrieve_noEmptyCache_noSideEffect() throws {
		let sut = makeSUT()

		assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
	}

	func test_insert_emptyCache_deliverNoError() throws {
		let sut = makeSUT()

		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
	}

	func test_insert_noEmptyCache_deliverNoError() throws {
		let sut = makeSUT()

		assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
	}

	func test_insert_noEmptyCache_overrideCache() throws {
		let sut = makeSUT()

		assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
	}

	func test_delete_emptyCache_deliverNoError() throws {
		let sut = makeSUT()

		assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
	}

	func test_delete_emptyCache_noSideEffect() throws {
		let sut = makeSUT()

		assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
	}

	func test_delete_noEmptyCache_deliverNoError() throws {
		let sut = makeSUT()

		assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
	}

	func test_delete_noEmptyCache_deleteCache() throws {
		let sut = makeSUT()

		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}

	// - MARK: Helpers

	private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> InMemoryFeedStore {
		let sut = InMemoryFeedStore()
		trackMemoryLeaks(sut, file: file, line: line)
		return sut
	}

}
