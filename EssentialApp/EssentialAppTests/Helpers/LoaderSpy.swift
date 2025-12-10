//
//  LoaderSpy.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//

import Foundation
import EssentialFeed
import EssentialFeediOS

@MainActor
class LoaderSpy {
    
    private var feedLoader = AsyncLoaderSpy<Void, Paginated<FeedImage>>()
    
    var loadCallCount: Int {
        feedLoader.requests.count
    }
    
    func loadFeed() async throws -> Paginated<FeedImage> {
        return try await feedLoader.load(())
    }
    
    func completeFeedLoading(with feed: [FeedImage] = [], at index: Int = 0) async {
        let loadMore: @Sendable () async throws -> Paginated<FeedImage> = { @MainActor [weak self] in
            try await self?.loadMore() ?? Paginated(items: [])
        }
        
        await feedLoader.complete(
            with: Paginated(items: feed, loadMore: loadMore),
            at: index)
    }
    
    func completeFeedLoadingWithError(at index: Int = 0) async {
        await feedLoader.fail(with: anyNSError(), at: index)
    }
    
    //MARK: - FeedLoadMore
    
    private var loadMoreLoader = AsyncLoaderSpy<Void, Paginated<FeedImage>>()
    
    var loadMoreCallCount: Int {
        loadMoreLoader.requests.count
    }
    
    func loadMore() async throws -> Paginated<FeedImage> {
        try await loadMoreLoader.load(())
    }
    
    func completeLoadMore(with feed: [FeedImage] = [], lastPage: Bool = false, at index: Int = 0) async {
        let loadMore: @Sendable () async throws -> Paginated<FeedImage> = { @MainActor [weak self] in
            try await self?.loadMore() ?? Paginated(items: [])
        }
        
        await loadMoreLoader.complete(
            with: Paginated(items: feed, loadMore: lastPage ? nil : loadMore),
            at: index)
    }
    
    func completeLoadMoreWithError(at index: Int = 0) async {
        await loadMoreLoader.fail(with: anyNSError(), at: index)
    }
    
    //MARK: - FeedImageDataLoader
    
    private var imageLoader = AsyncLoaderSpy<URL, Data>()
    
    var loadedImageURLs: [URL] {
        return imageLoader.requests.map { $0.param }
    }
    
    var cancelledImageURLs: [URL] {
        return imageLoader.requests.filter({ $0.result == .cancelled }).map { $0.param }
    }
    
    func loadImageData(from url: URL) async throws -> Data {
        try await imageLoader.load(url)
    }
    
    func completeImageLoading(with imageData: Data = Data(), at index: Int = 0) async {
        await imageLoader.complete(with: imageData, at: index)
    }
    
    func completeImageLoadingWithError(at index: Int = 0) async {
        await imageLoader.fail(with: anyNSError(), at: index)
    }
    
    func result(at index: Int, timeout: TimeInterval = 1) async throws -> AsyncResult {
        try await imageLoader.result(at: index, timeout: timeout)
    }
    
    func cancelPendingRequests() async throws {
        try await imageLoader.cancelPendingRequests()
        try await loadMoreLoader.cancelPendingRequests()
        try await feedLoader.cancelPendingRequests()
    }
}

enum AsyncResult {
    case success
    case failure
    case cancelled
}

@MainActor
class AsyncLoaderSpy<Param, Resource> where Resource: Sendable {
    
    private(set) var requests = [(
        param: Param,
        publisher: AsyncThrowingStream<Resource, Error>,
        continuation: AsyncThrowingStream<Resource, Error>.Continuation,
        result: AsyncResult?
    )]()
    
    private struct NoResponse: Error {}
    private struct Timeout: Error {}
    
    func load(_ param: Param) async throws -> Resource {
        let (stream, continuation) = AsyncThrowingStream<Resource, Error>.makeStream()
        let index = requests.count
        requests.append((param, stream, continuation, nil))
        
        do {
            for try await result in stream {
                try Task.checkCancellation()
                requests[index].result = .success
                return result
            }
            try Task.checkCancellation()
            throw NoResponse()
        } catch {
            requests[index].result = Task.isCancelled ? .cancelled : .failure
            throw error
        }
    }
    
    func complete(with resource: Resource, at index: Int = 0) async {
        requests[index].continuation.yield(resource)
        requests[index].continuation.finish()
        
        while requests[index].result == nil { await Task.yield() }
    }
    
    func fail(with error: Error, at index: Int = 0) async {
        requests[index].continuation.finish(throwing: error)
        
        while requests[index].result == nil { await Task.yield() }
    }
    
    func result(at index: Int, timeout: TimeInterval = 1) async throws -> AsyncResult {
        let maxDate = Date() + timeout

        while Date() <= maxDate {
            if let result = requests[index].result {
                return result
            }
            //call await Task.yield() to suspend the current execution and allow other tasks to run before resuming to check for the result again.
            await Task.yield()
        }

        throw Timeout()
    }
    
    func cancelPendingRequests() async throws {
        for (index, request) in requests.enumerated() where request.result == nil {
            request.continuation.finish(throwing: CancellationError())
            while requests[index].result == nil { await Task.yield() }
        }
    }
}
