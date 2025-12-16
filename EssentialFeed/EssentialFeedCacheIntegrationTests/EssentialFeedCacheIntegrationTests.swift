//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by Yury Ramazanov on 31.12.2024.
//

import XCTest
import EssentialFeed

@MainActor 
final class EssentialFeedCacheIntegrationTests: XCTestCase {
   
    override func setUp() async throws {
        try await super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        undoStoreSideEffects()
    }
    
    func test_load_emptyCache_deliversEmptyFeed() throws {
        let sut = try makeFeedLoader()
        
        expect(sut, load: [])
    }
    
    func test_load_deliversItemsSavedOnASeparateInstance() throws {
        let sutToPerformSave = try makeFeedLoader()
        let sutToPerformLoad = try makeFeedLoader()
        let feed = uniqueImageFeed().models
        
        save(feed, on: sutToPerformSave)
        
        expect(sutToPerformLoad, load: feed)
    }
    
    func test_save_overridesItemsSavedOnASeparateInstance() throws {
        let sutToPerformFirstSave = try makeFeedLoader()
        let sutToPerformLastSave = try makeFeedLoader()
        let sutToPerformLoad = try makeFeedLoader()
        let firstFeed = uniqueImageFeed().models
        let latestFeed = uniqueImageFeed().models
        
        save(firstFeed, on: sutToPerformFirstSave)
        save(latestFeed, on: sutToPerformLastSave)
        
        expect(sutToPerformLoad, load: latestFeed)
    }
  
    func test_validateFeedCache_doesNotDeleteRecentlySavedFeed() throws {
        let feedLoaderToPerformSave = try makeFeedLoader()
        let feedLoaderToPerformValidation = try makeFeedLoader()
        let feed = uniqueImageFeed().models
        
        save(feed, on: feedLoaderToPerformSave)
        validateCache(with: feedLoaderToPerformValidation)
        
        expect(feedLoaderToPerformSave, load: feed)
    }
    
    func test_validateFeedCache_deletesFeedSavedInADistantPast() throws {
        let feedLoaderToPerformSave = try makeFeedLoader(currentDate: .distantPast)
        let feedLoaderToPerformValidation = try makeFeedLoader(currentDate: Date())
        let feed = uniqueImageFeed().models
        
        save(feed, on: feedLoaderToPerformSave)
        validateCache(with: feedLoaderToPerformValidation)
        
        expect(feedLoaderToPerformSave, load: [])
    }

    // MARK: - LocalFeedImageDataLoader
    
    func test_loadImageData_deliversSavedDataOnASeparateInstance() throws {
        let feedLoader = try makeFeedLoader()
        let imageLoaderToPerformSave = try makeImageLoader()
        let imageLoaderToPerformLoad = try makeImageLoader()
        let image = uniqueImage()
        let data = anyData()
        
        save([image], on: feedLoader)
        save(data, for: image.url, on: imageLoaderToPerformSave)
        
        expect(imageLoaderToPerformLoad, load: data, for: image.url)
    }
    
    func test_saveImageData_overridesSavedImageDataOnASeparateInstance() throws {
        let feedLoader = try makeFeedLoader()
        let imageLoaderToPerformFirstSave = try makeImageLoader()
        let imageLoaderToPerformLastSave = try makeImageLoader()
        let imageLoaderToPerformLoad = try makeImageLoader()
        let image = uniqueImage()
        let firstImageData = Data("first".utf8)
        let lastImageData = Data("last".utf8)
        
        save([image], on: feedLoader)
        save(firstImageData, for: image.url, on: imageLoaderToPerformFirstSave)
        save(lastImageData, for: image.url, on: imageLoaderToPerformLastSave)
        
        expect(imageLoaderToPerformLoad, load: lastImageData, for: image.url)
    }
        
    // MARK: Helpers
    
    private func makeFeedLoader(currentDate: Date = Date(), file: StaticString = #filePath, line: UInt = #line) throws -> LocalFeedLoader {
        let store = try CoreDataFeedStore(storeUrl: testStoreUrl)
        let sut = LocalFeedLoader(store: store, date: { currentDate })
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func makeImageLoader(file: StaticString = #filePath, line: UInt = #line) throws -> LocalFeedImageDataLoader {
        let store = try CoreDataFeedStore(storeUrl: testStoreUrl)
        let sut = LocalFeedImageDataLoader(store: store)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func expect(_ sut: LocalFeedLoader, load expectedResult: [FeedImage],  file: StaticString = #filePath, line: UInt = #line) {
        do {
            let loadedFeed = try sut.load()
            XCTAssertEqual(loadedFeed, expectedResult, file: file, line: line)
        } catch {
            XCTFail("Expected successful feed result, got \(error) instead", file: file, line: line)
        }
    }
    
    private func save(_ feed: [FeedImage], on sut: LocalFeedLoader, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try sut.save(feed)
        } catch {
            XCTFail("Expected to save feed successfully, got error: \(error)", file: file, line: line)
        }
    }
    
    private func save(_ data: Data, for url: URL, on sut: LocalFeedImageDataLoader, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try sut.save(data, for: url)
        } catch {
            XCTFail("Expected to save image data successfully, got error: \(error)", file: file, line: line)
        }
    }
    
    private func expect(_ sut: LocalFeedImageDataLoader, load expectedData: Data, for url: URL, file: StaticString = #filePath, line: UInt = #line) {
        do {
            let loadedData = try sut.loadImageData(from: url)
            XCTAssertEqual(loadedData, expectedData, file: file, line: line)
        } catch {
            XCTFail("Expected successful image data result, got \(error) instead", file: file, line: line)
        }
    }
        
    private func validateCache(with loader: LocalFeedLoader, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try loader.validateCache()
        } catch {
            XCTFail("Expected to validate feed successfully, got error: \(error)", file: file, line: line)
        }
    }
    
    private var testStoreUrl: URL {
        cachesDirectory.appendingPathComponent("\(type(of: self)).store")
    }
    
    private var cachesDirectory: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testStoreUrl)
    }
}
