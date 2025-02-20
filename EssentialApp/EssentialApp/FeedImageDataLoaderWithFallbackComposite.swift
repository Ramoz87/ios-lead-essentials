//
//  FeedImageDataLoaderWithFallbackComposite.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 20.02.2025.
//
import Foundation
import EssentialFeed

final public class FeedImageDataLoaderWithFallbackComposite: FeedImageDataLoader {
    
    private let primary: FeedImageDataLoader
    private let fallback: FeedImageDataLoader
    
    private class WrappedTask: FeedImageDataLoaderTask {
        var wrapped: FeedImageDataLoaderTask?
        
        func cancel() {
            wrapped?.cancel()
        }
    }
    
    public init(primary: FeedImageDataLoader, fallback: FeedImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }

    public func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> any FeedImageDataLoaderTask {
        let task = WrappedTask()
        task.wrapped = primary.loadImageData(from: url) { [weak self] result in
            
            switch result {
            case .success: completion(result)
            case .failure: task.wrapped = self?.fallback.loadImageData(from: url, completion: completion)
            }
        }
        
        return task
    }
}
