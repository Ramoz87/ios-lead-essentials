//
//  FeedRefreshViewModel.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 22.01.2025.
//

import Foundation
import EssentialFeed

protocol FeedLoadingView {
    func display(_ model: FeedLoadingViewModel)
}

protocol FeedView {
    func display(_ model: FeedViewModel)
}

public final class FeedPresenter {
        
    private let feedView: FeedView
    private let loadingView: FeedLoadingView
    
    init(feedView: FeedView, loadingView: FeedLoadingView) {
        self.feedView = feedView
        self.loadingView = loadingView
    }
    
    static var title: String {
        return NSLocalizedString("FEED_VIEW_TITLE",
                                 tableName: "Feed",
                                 bundle: .init(for: FeedPresenter.self),
                                 comment: "Title for the feed view")
    }
    
    func didStartLoadingFeed() {
        loadingView.display(.init(isLoading: true))
    }
    
    func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView.display(FeedViewModel(feed: feed))
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }
    
    func didFinishLoadingFeed(with error: Error) {
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }
}
