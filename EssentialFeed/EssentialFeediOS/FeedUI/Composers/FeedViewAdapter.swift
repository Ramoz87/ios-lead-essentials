//
//  FeedViewAdapter.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 28.01.2025.
//

import UIKit

final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageLoader: FeedImageDataLoader
    
    init(controller: FeedViewController, imageLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }
    
    func display(_ model: FeedViewModel) {
        controller?.tableModel = model.feed.map { model in
            let adapter = FeedImagePresenterAdapter<WeakReference<FeedImageCellController>, UIImage>(model: model, imageLoader: imageLoader)
           
            let ctrl = FeedImageCellController(delegate: adapter)
            adapter.presenter = FeedImagePresenter(view: WeakReference(object: ctrl),
                                                   imageTransformer: UIImage.init)
            return ctrl
        }
    }
}
