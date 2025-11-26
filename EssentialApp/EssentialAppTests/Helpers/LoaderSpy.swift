//
//  LoaderSpy.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//

import Foundation
import Combine
import EssentialFeed
import EssentialFeediOS

@MainActor
class LoaderSpy {
    
    private var feedRequests = [PassthroughSubject<Paginated<FeedImage>, Error>]()
    private var loadMoreRequests = [PassthroughSubject<Paginated<FeedImage>, Error>]()
    
    var loadCallCount: Int {
        feedRequests.count
    }
    
    func loadPublisher() -> Paginated<FeedImage>.Publisher {
        let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
        feedRequests.append(publisher)
        return publisher.eraseToAnyPublisher()
    }
    
    func completeFeedLoading(with feed: [FeedImage] = [], at index: Int = 0) {
        feedRequests[index].send(Paginated(items: feed, loadMorePublisher: loadMorePublisher()))
        feedRequests[index].send(completion: .finished)
    }
    
    func completeFeedLoadingWithError(at index: Int = 0) {
        feedRequests[index].send(completion: .failure(anyNSError()))
    }
    
    //MARK: - FeedLoadMore
    
    var loadMoreCallCount: Int {
        loadMoreRequests.count
    }
    
    func loadMorePublisher() -> () -> Paginated<FeedImage>.Publisher {
        return { [weak self] in
            let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
            self?.loadMoreRequests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }
    }
    
    func completeLoadMore(with feed: [FeedImage] = [], lastPage: Bool = false, at index: Int = 0) {
        loadMoreRequests[index].send(Paginated(items: feed, loadMorePublisher: lastPage ? nil : loadMorePublisher()))
    }
    
    func completeLoadMoreWithError(at index: Int = 0) {
        loadMoreRequests[index].send(completion: .failure(anyNSError()))
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
    
    func completeImageLoading(with imageData: Data = Data(), at index: Int = 0) {
        imageLoader.complete(with: imageData, at: index)
    }
    
    func completeImageLoadingWithError(at index: Int = 0) {
        imageLoader.fail(with: anyNSError(), at: index)
    }
    
    func result(at index: Int, timeout: TimeInterval = 1) async throws -> AsyncResult {
        try await imageLoader.result(at: index, timeout: timeout)
    }
    
    func cancelPendingRequests() async throws {
        try await imageLoader.cancelPendingRequests()
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
    
    func complete(with resource: Resource, at index: Int = 0) {
        requests[index].continuation.yield(resource)
        requests[index].continuation.finish()
        
        while requests[index].result == nil { RunLoop.current.run(until: Date()) }
    }
    
    func fail(with error: Error, at index: Int = 0) {
        requests[index].continuation.finish(throwing: error)
        
        while requests[index].result == nil { RunLoop.current.run(until: Date()) }
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
