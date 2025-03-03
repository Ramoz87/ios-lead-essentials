//
//  LocalFeedImageDataLoader.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 19.02.2025.
//
import Foundation

final public class LocalFeedImageDataLoader {

    private let store: FeedImageDataStore
    
    public init(store: FeedImageDataStore) {
        self.store = store
    }
}

extension LocalFeedImageDataLoader: FeedImageDataCache {
    public typealias SaveResult = FeedImageDataCache.SaveResult
    
    public enum SaveError: Error {
        case failed
    }
    
    public func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {
        store.insert(data, for: url) { [weak self] result in
            guard self != nil else { return }
            completion(result.mapError { _ in SaveError.failed })
        }
    }
}

extension LocalFeedImageDataLoader: FeedImageDataLoader {
    
    private final class LoadImageDataTask: FeedImageDataLoaderTask {
        private var completion: ((FeedImageDataLoader.Result) -> Void)?
                
        init(_ completion: @escaping (FeedImageDataLoader.Result) -> Void) {
            self.completion = completion
        }
        
        func complete(with result: FeedImageDataLoader.Result) {
            completion?(result)
        }
        
        func cancel() {
            completion = nil
        }
    }
    
    public enum LoadError: Swift.Error {
        case failed
        case notFound
    }
    
    public func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        let task = LoadImageDataTask(completion)
        store.retrieve(dataForURL: url) { [weak self] result in
            guard self != nil else { return }
            task.complete(with:  result
                .mapError { _ in LoadError.failed }
                .flatMap { data in data.map { .success($0) } ?? .failure(LoadError.notFound) })
        }
        return task
    }
}
