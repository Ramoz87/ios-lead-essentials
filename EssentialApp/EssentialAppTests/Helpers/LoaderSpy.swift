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
    private struct NoResponse: Error {}
    private struct Timeout: Error {}
    
    private var imageRequests = [(
        url: URL,
        publisher: AsyncThrowingStream<Data, Error>,
        continuation: AsyncThrowingStream<Data, Error>.Continuation,
        result: AsyncResult?
    )]()
    
    enum AsyncResult {
        case success
        case failure
        case cancelled
    }
    
    private(set) var cancelledImageURLs = [URL]()
    var loadedImageURLs: [URL] {
        return imageRequests.map { $0.url }
    }
    
    func loadImageData(from url: URL) async throws -> Data {
        let (stream, continuation) = AsyncThrowingStream<Data, Error>.makeStream()
        let index = imageRequests.count
        imageRequests.append((url, stream, continuation, nil))
        
        do {
            for try await result in stream {
                try Task.checkCancellation()
                imageRequests[index].result = .success
                return result
            }
            try Task.checkCancellation()
            throw NoResponse()
        } catch {
            if Task.isCancelled {
                cancelledImageURLs.append(url)
                imageRequests[index].result = .cancelled
            } else {
                imageRequests[index].result = .failure
            }
            throw error
        }
    }
    
    func completeImageLoading(with imageData: Data = Data(), at index: Int = 0) {
        imageRequests[index].continuation.yield(imageData)
        imageRequests[index].continuation.finish()
        
        while imageRequests[index].result == nil { RunLoop.current.run(until: Date()) }
    }
    
    func completeImageLoadingWithError(at index: Int = 0) {
        imageRequests[index].continuation.finish(throwing: anyNSError())
        
        while imageRequests[index].result == nil { RunLoop.current.run(until: Date()) }
    }
    
    func result(at index: Int, timeout: TimeInterval = 1) async throws -> AsyncResult {
        let maxDate = Date() + timeout

        while Date() <= maxDate {
            if let result = imageRequests[index].result {
                return result
            }
            //call await Task.yield() to suspend the current execution and allow other tasks to run before resuming to check for the result again.
            await Task.yield()
        }

        throw Timeout()
    }
    
    func cancelPendingRequests() async throws {
        for (index, request) in imageRequests.enumerated() where request.result == nil {
            request.continuation.finish(throwing: CancellationError())
            while imageRequests[index].result == nil { await Task.yield() }
        }
    }
}
