//
//  LoaderSpy.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//

import Foundation
import EssentialFeed
import EssentialFeediOS

class LoaderSpy: FeedLoader, FeedImageDataLoader {
    
    private var completions = [(FeedLoader.Result) -> Void]()
    var loadCallCount: Int {
        return completions.count
    }
    
    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        completions.append(completion)
    }
    
    func completeFeedLoading(with feed: [FeedImage] = [], at index: Int = 0) {
        completions[index](.success(feed))
    }
    
    func completeFeedLoadingWithError(at index: Int = 0) {
        completions[index](.failure(anyNSError()))
    }
    
    //MARK: - FeedImageDataLoader
   
    private struct TaskSpy: FeedImageDataLoaderTask {
        let cancelCallback: () -> Void
        func cancel() {
            cancelCallback()
        }
    }
    var loadedImageURLs: [URL] {
        return imageRequests.map { $0.url }
    }
    
    private var imageRequests = [(url: URL, completion: (FeedImageDataLoader.Result) -> Void)]()
    private(set) var cancelledImageURLs = [URL]()
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        imageRequests.append((url, completion))
        return TaskSpy { [weak self] in self?.cancelledImageURLs.append(url) }
    }
    
    func completeImageLoading(with imageData: Data = Data(), at index: Int = 0) {
        imageRequests[index].completion(.success(imageData))
    }

    func completeImageLoadingWithError(at index: Int = 0) {
        imageRequests[index].completion(.failure(anyNSError()))
    }
}
