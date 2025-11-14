//
//  CoreDataFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 31.12.2024.
//

import XCTest
import EssentialFeed

@MainActor
final class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
    
    func test_retrieve_emptyCache_deliverEmptyResult() async throws {
        try await makeSUT { sut in
            assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
        }
    }
    
    func test_retrieve_emptyCache_noSideEffect() async throws {
        try await makeSUT { sut in
            assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
        }
    }
    
    func test_retrieve_noEmptyCache_deliverCache() async throws {
        try await makeSUT { sut in
            assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
        }
    }
    
    func test_retrieve_noEmptyCache_noSideEffect() async throws {
        try await makeSUT { sut in
            assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
        }
    }
    
    func test_insert_emptyCache_deliverNoError() async throws {
        try await makeSUT { sut in
            assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
        }
    }
    
    func test_insert_noEmptyCache_deliverNoError() async throws {
        try await makeSUT { sut in
            assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
        }
    }
    
    func test_insert_noEmptyCache_overrideCache() async throws {
        try await makeSUT { sut in
            assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
        }
    }
    
    func test_delete_emptyCache_deliverNoError() async throws {
        try await makeSUT { sut in
            assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
        }
    }
    
    func test_delete_emptyCache_noSideEffect() async throws {
        try await makeSUT { sut in
            assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
        }
    }
    
    func test_delete_noEmptyCache_deliverNoError() async throws {
        try await makeSUT { sut in
            assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
        }
    }
    
    func test_delete_noEmptyCache_deleteCache() async throws {
        try await makeSUT { sut in
            assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
        }
    }
    
    //MARK: - Helpers
    
    private func makeSUT(_ test: @Sendable @escaping (CoreDataFeedStore) -> Void, file: StaticString = #file, line: UInt = #line) async throws {
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try CoreDataFeedStore(storeUrl: storeURL)
        trackMemoryLeaks(sut, file: file, line: line)
        
        await sut.perform {
            test(sut)
        }
    }
}
