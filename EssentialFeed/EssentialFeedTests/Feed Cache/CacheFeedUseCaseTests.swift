//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Yury Ramazanov on 23.12.2024.
//

import XCTest
import EssentialFeed

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    
    private var deleteCompletions = [DeletionCompletion]()
    var deleteCahcedFeedCallCount: Int = 0
    var insertCallCount: Int = 0
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deleteCahcedFeedCallCount += 1
        deleteCompletions.append(completion)
    }
    
    func completeDelete(with error: Error?) {
        deleteCompletions.last?(error)
    }
    
    func insert(_ items: [FeedItem]) {
        insertCallCount += 1
    }
}

class LocalFeedLoader {
    let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed {[unowned self] error in
            if error == nil {
                self.store.insert(items)
            }
        }
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCache() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.deleteCahcedFeedCallCount, 0)
    }
    
    func test_save_performaCacheDelete() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        sut.save(items)
        
        XCTAssertEqual(store.deleteCahcedFeedCallCount, 1)
    }
    
    func test_save_errorOnDelete_doesNotInsertCache() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let deleteError = anyNSError()
        
        sut.save(items)
        store.completeDelete(with: deleteError)
        
        XCTAssertEqual(store.insertCallCount, 0)
    }
    
    func test_save_successOnDelete_insertCache() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items)
        store.completeDelete(with: nil)
        
        XCTAssertEqual(store.insertCallCount, 1)
    }
    
    //MARK: - Helpers
    
    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
}
