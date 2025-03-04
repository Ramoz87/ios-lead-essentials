//
//  FeedPresenterAdapter.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 28.01.2025.
//

import Foundation
import Combine
import EssentialFeed
import EssentialFeediOS

final class FeedPresenterAdapter: FeedViewControllerDelegate {

    private let feedLoader: FeedLoader.Publisher
    var presenter: FeedPresenter?
    private var cancellable: AnyCancellable?
    
    init(feedLoader: FeedLoader.Publisher) {
        self.feedLoader = feedLoader
    }
    
    func didRequestFeedRefresh() {
        presenter?.didStartLoadingFeed()
        
        cancellable = feedLoader.sink { [weak self] completion in
            switch completion {
            case .finished: break
            case let .failure(error):
                self?.presenter?.didFinishLoadingFeed(with: error)
            }
        } receiveValue: { [weak self] feed in
            self?.presenter?.didFinishLoadingFeed(with: feed)
        }
    }
}
