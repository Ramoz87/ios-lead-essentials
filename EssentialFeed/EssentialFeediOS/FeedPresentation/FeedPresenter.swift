//
//  FeedRefreshViewModel.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 22.01.2025.
//

import EssentialFeed

struct FeedLoadingViewModel {
    var isLoading: Bool
}
protocol FeedLoadingView {
    func display(_ model: FeedLoadingViewModel)
}

struct FeedViewModel {
    var feed: [FeedImage]
}
protocol FeedView {
    func display(_ model: FeedViewModel)
}

public final class FeedPresenter {
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    var feedView: FeedView?
    var loadingView: FeedLoadingView?
    
    func loadFeed() {
        loadingView?.display(.init(isLoading: true))
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.feedView?.display(.init(feed: feed))
            }

            self?.loadingView?.display(.init(isLoading: false))
        }
    }
}
