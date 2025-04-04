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
    
    private typealias FeedPresentationAdapter = LoadResourcePresenterAdapter<Paginated<FeedImage>, FeedViewAdapter>
    
    public static func feedViewController(
        feedLoader: @escaping () -> AnyPublisher<Paginated<FeedImage>, Error>,
        imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher,
        selection: @escaping (FeedImage) -> Void = { _ in }
    ) -> ListViewController {
        let presenterAdapter = FeedPresentationAdapter(loader: feedLoader)
        let feedController = makeListViewController(title: FeedPresenter.title)
        feedController.onRefresh = presenterAdapter.loadResource
        presenterAdapter.presenter = LoadResourcePresenter (
            resourceView: FeedViewAdapter(
                controller: feedController,
                imageLoader: imageLoader,
                selection: selection),
            loadingView: WeakReference(object: feedController),
            errorView: WeakReference(object: feedController),
            mapper: FeedPresenter.map)
        
        return feedController
    }
    
    private static func makeListViewController(title: String) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyBoard = UIStoryboard(name: "Feed", bundle: bundle)
        let ctrl = storyBoard.instantiateInitialViewController() as! ListViewController
        ctrl.title = title
        return ctrl
    }
}
