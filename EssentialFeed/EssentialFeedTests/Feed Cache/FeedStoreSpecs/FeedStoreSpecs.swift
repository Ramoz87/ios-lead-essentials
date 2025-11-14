//
//  FeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 30.12.2024.
//

@MainActor
protocol FeedStoreSpecs {

    func test_retrieve_emptyCache_deliverEmptyResult() async throws
    func test_retrieve_emptyCache_noSideEffect() async throws
    func test_retrieve_noEmptyCache_deliverCache() async throws
    func test_retrieve_noEmptyCache_noSideEffect() async throws

    func test_insert_emptyCache_deliverNoError() async throws
    func test_insert_noEmptyCache_deliverNoError() async throws
    func test_insert_noEmptyCache_overrideCache() async throws

    func test_delete_emptyCache_deliverNoError() async throws
    func test_delete_emptyCache_noSideEffect() async throws
    func test_delete_noEmptyCache_deliverNoError() async throws
    func test_delete_noEmptyCache_deleteCache() async throws
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieve_retrieveError_deliverError() async throws
    func test_retrieve_retrieveError_noSideEffect() async throws
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_insertError_deliverError() async throws
    func test_insert_insertError_noSideEffect() async throws
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deleteError_deliverError() async throws
    func test_delete_deleteError_noSideEffect() async throws
}

typealias FailableFeedStoreSpecs = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs
