//
//  FeedUIComposer.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//

import UIKit
import EssentialFeed

public final class FeedUIComposer {
    private init() {}

    public static func feedViewController(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let presenterAdapter = FeedPresenterAdapter(feedLoader: MainQueueDispatchDecorator(decoratee: feedLoader))
        let feedController = makeFeedViewController(delegate: presenterAdapter,
                                                    title: FeedPresenter.title)
        presenterAdapter.presenter = FeedPresenter(feedView: FeedViewAdapter(controller: feedController,
                                                                             imageLoader: MainQueueDispatchDecorator(decoratee:imageLoader)),
                                                   loadingView: WeakReference(object: feedController),
                                                   errorView: WeakReference(object: feedController))
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
