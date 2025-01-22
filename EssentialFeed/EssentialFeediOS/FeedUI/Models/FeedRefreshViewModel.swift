//
//  FeedRefreshViewModel.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 22.01.2025.
//

import UIKit
import EssentialFeed

public final class FeedRefreshViewModel {
    typealias Observer<T> = (T) -> Void
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    var onLoadingStateChange: Observer<Bool>?
    var onFeedLoaded: Observer<[FeedImage]>?

    func loadFeed() {
        onLoadingStateChange?(true)
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoaded?(feed)
            }

            self?.onLoadingStateChange?(false)
        }
    }
}
