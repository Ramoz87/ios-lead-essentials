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
        let presenter = FeedPresenter(feedLoader: feedLoader)
        
        let refreshController = FeedRefreshViewController(presenter: presenter)
        let feedController = FeedViewController(refreshController: refreshController)
        
        presenter.loadingView = WeakReference(object: refreshController)
        presenter.feedView = FeedViewAdapter(controller: feedController, imageLoader: imageLoader)
        
        return feedController
    }
}

private struct WeakReference<T: AnyObject> {
    private weak var object: T?
    
    init(object: T) {
        self.object = object
    }
}

extension WeakReference: FeedLoadingView where T: FeedLoadingView {
    func display(_ model: FeedLoadingViewModel) {
        object?.display(model)
    }
}

private struct FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageLoader: FeedImageDataLoader
    
    init(controller: FeedViewController, imageLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }
    
    func display(_ model: FeedViewModel) {
        controller?.tableModel = model.feed.map {
            FeedImageCellController(viewModel: FeedImageCellViewModel(model: $0,
                                                                      imageLoader: imageLoader,
                                                                      imageTransformer: UIImage.init))
        }
    }
}
