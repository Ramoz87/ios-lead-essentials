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
        let viewModel = FeedRefreshViewModel(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(viewModel: viewModel)
        let ctrl = FeedViewController(refreshController: refreshController)
        viewModel.onFeedLoaded = adaptFeedToCellControllers(forwardingTo: ctrl, loader: imageLoader)
        return ctrl
    }
    
    private static func adaptFeedToCellControllers(forwardingTo controller: FeedViewController, loader: FeedImageDataLoader) -> ([FeedImage]) -> Void {
        return { [weak controller] feed in
            controller?.tableModel = feed.map {
                FeedImageCellController(viewModel: FeedImageCellViewModel(model: $0, imageLoader: loader, imageTransformer: UIImage.init))
            }
        }
    }
}


