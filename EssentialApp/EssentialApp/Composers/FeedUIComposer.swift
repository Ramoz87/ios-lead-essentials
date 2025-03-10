//
//  FeedUIComposer.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//

import UIKit
import Combine
import EssentialFeed
import EssentialFeediOS

public final class FeedUIComposer {
    private init() {}
    
    public static func feedViewController(feedLoader: @escaping () -> AnyPublisher<[FeedImage], Error>,
                                          imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher) -> FeedViewController {
        let presenterAdapter = FeedPresenterAdapter(feedLoader: feedLoader)
        let feedController = makeFeedViewController(delegate: presenterAdapter, title: FeedPresenter.title)
        presenterAdapter.presenter = LoadResourcePresenter (
            resourceView: FeedViewAdapter(
                controller: feedController,
                imageLoader: imageLoader),
            loadingView: WeakReference(object: feedController),
            errorView: WeakReference(object: feedController),
            mapper: FeedPresenter.map)
        
        return feedController
    }
    
    private static func makeFeedViewController(delegate: FeedViewControllerDelegate, title: String) -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyBoard = UIStoryboard(name: "Feed", bundle: bundle)
        let ctrl = storyBoard.instantiateInitialViewController() as! FeedViewController
        ctrl.title = title
        ctrl.delegate = delegate
        return ctrl
    }
}
