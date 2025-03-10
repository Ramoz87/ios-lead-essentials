//
//  FeedViewAdapter.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 28.01.2025.
//

import UIKit
import EssentialFeed
import EssentialFeediOS

final class FeedViewAdapter: ResourceView {
    private weak var controller: FeedViewController?
    private let imageLoader: (URL) -> FeedImageDataLoader.Publisher
    
    init(controller: FeedViewController, imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher) {
        self.controller = controller
        self.imageLoader = imageLoader
    }
    
    func display(_ viewModel: FeedViewModel) {
        let cells = viewModel.feed.map { model in
            let adapter = FeedImagePresenterAdapter<WeakReference<FeedImageCellController>, UIImage>(model: model, imageLoader: imageLoader)
           
            let ctrl = FeedImageCellController(delegate: adapter)
            adapter.presenter = FeedImagePresenter(view: WeakReference(object: ctrl),
                                                   imageTransformer: UIImage.init)
            return ctrl
        }
        controller?.display(cells)
    }
}
