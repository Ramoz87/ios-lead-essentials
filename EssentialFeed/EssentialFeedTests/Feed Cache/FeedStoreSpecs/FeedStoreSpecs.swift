//
//  FeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 30.12.2024.
//

protocol FeedStoreSpecs {

    func test_retrieve_emptyCache_deliverEmptyResult() throws
    func test_retrieve_emptyCache_noSideEffect() throws
    func test_retrieve_noEmptyCache_deliverCache() throws
    func test_retrieve_noEmptyCache_noSideEffect() throws

    func test_insert_emptyCache_deliverNoError() throws
    func test_insert_noEmptyCache_deliverNoError() throws
    func test_insert_noEmptyCache_overrideCache() throws

    func test_delete_emptyCache_deliverNoError() throws
    func test_delete_emptyCache_noSideEffect() throws
    func test_delete_noEmptyCache_deliverNoError() throws
    func test_delete_noEmptyCache_deleteCache() throws
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieve_retrieveError_deliverError() throws
    func test_retrieve_retrieveError_noSideEffect() throws
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_insertError_deliverError() throws
    func test_insert_insertError_noSideEffect() throws
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deleteError_deliverError() throws
    func test_delete_deleteError_noSideEffect() throws
}

typealias FailableFeedStoreSpecs = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs
