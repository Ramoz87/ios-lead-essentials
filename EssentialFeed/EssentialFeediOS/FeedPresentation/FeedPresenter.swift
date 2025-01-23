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
        
    var feedView: FeedView?
    var loadingView: FeedLoadingView?
    
    func didStartLoadingFeed() {
        loadingView?.display(.init(isLoading: true))
    }
    
    func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView?.display(FeedViewModel(feed: feed))
        loadingView?.display(FeedLoadingViewModel(isLoading: false))
    }
    
    func didFinishLoadingFeed(with error: Error) {
        loadingView?.display(FeedLoadingViewModel(isLoading: false))
    }
}
