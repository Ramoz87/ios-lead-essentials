//
//  FeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 30.12.2024.
//

protocol FeedStoreSpecs {

    func test_retrieve_emptyCache_deliverEmptyResult()
    func test_retrieve_emptyCache_noSideEffect()
    func test_retrieve_noEmptyCache_deliverCache()
    func test_retrieve_noEmptyCache_noSideEffect()

    func test_insert_emptyCache_deliverNoError()
    func test_insert_noEmptyCache_deliverNoError()
    func test_insert_noEmptyCache_overrideCache()

    func test_delete_emptyCache_deliverNoError()
    func test_delete_emptyCache_noSideEffect()
    func test_delete_noEmptyCache_deliverNoError()
    func test_delete_noEmptyCache_deleteCache()

    func test_sideEffectOperationsRunSerially()
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieve_retrieveError_deliverError()
    func test_retrieve_retrieveError_noSideEffect()
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_insertError_deliverError()
    func test_insert_insertError_noSideEffect()
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deleteError_deliverError()
    func test_delete_deleteError_noSideEffect()
}

typealias FailableFeedStoreSpecs = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs
