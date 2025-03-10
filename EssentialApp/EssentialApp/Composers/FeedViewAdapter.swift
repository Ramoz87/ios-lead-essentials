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
    
    private struct InvalidImageData: Error {}
    
    init(controller: FeedViewController, imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher) {
        self.controller = controller
        self.imageLoader = imageLoader
    }
    
    func display(_ viewModel: FeedViewModel) {
        let cells = viewModel.feed.map { model in
            let adapter = LoadResourcePresenterAdapter<Data, WeakReference<FeedImageCellController>> (loader: { [imageLoader] in
                imageLoader(model.url)
            })
            
            let view = FeedImageCellController(viewModel: FeedImagePresenter<FeedImageCellController, UIImage>.map(model),
                                               delegate: adapter)
            adapter.presenter = LoadResourcePresenter(
                resourceView: WeakReference(object: view),
                loadingView: WeakReference(object: view),
                errorView: WeakReference(object: view),
                mapper: { data in
                    guard let image = UIImage(data: data) else {
                        throw InvalidImageData()
                    }
                    return image
                })
            return view
        }
        controller?.display(cells)
    }
}
