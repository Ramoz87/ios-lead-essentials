//
//  CoreDataFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 31.12.2024.
//

import XCTest
import EssentialFeed

final class CoreDataFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    func test_retrieve_retrieveError_deliverError() {
        
    }
    
    func test_retrieve_retrieveError_noSideEffect() {
        
    }
    
    func test_insert_insertError_deliverError() {
        
    }
    
    func test_insert_insertError_noSideEffect() {
        
    }
    
    func test_delete_deleteError_deliverError() {
        
    }
    
    func test_delete_deleteError_noSideEffect() {
        
    }
    
    func test_retrieve_emptyCache_deliverEmptyResult() {
        let sut = makeSUT()
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_emptyCache_noSideEffect() {
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_noEmptyCache_deliverCache() {
        
    }
    
    func test_retrieve_noEmptyCache_noSideEffect() {
        
    }
    
    func test_insert_emptyCache_deliverNoError() {
        
    }
    
    func test_insert_noEmptyCache_deliverNoError() {
        
    }
    
    func test_insert_noEmptyCache_overrideCache() {
        
    }
    
    func test_delete_emptyCache_deliverNoError() {
        
    }
    
    func test_delete_emptyCache_noSideEffect() {
        
    }
    
    func test_delete_noEmptyCache_deliverNoError() {
        
    }
    
    func test_delete_noEmptyCache_deleteCache() {
        
    }
    
    func test_sideEffectOperationsRunSerially() {
        
    }
    
    // - MARK: Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let bundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataFeedStore(storeUrl: storeURL, bundle: bundle)
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
