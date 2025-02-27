//
//  FeedImagePresenterAdapter.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 28.01.2025.
//

import EssentialFeed
import EssentialFeediOS

final class FeedImagePresenterAdapter<View: FeedImageView, Image>: FeedImageCellControllerDelegate where View.Image == Image {
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader
    private var task: FeedImageDataLoaderTask?

    var presenter: FeedImagePresenter<View, Image>?

    init(model: FeedImage, imageLoader: FeedImageDataLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }

    func didRequestImage() {
        presenter?.didStartImageLoading(for: model)

        let model = self.model
        task = imageLoader.loadImageData(from: model.url) { [weak self] result in
            switch result {
            case let .success(data):
                self?.presenter?.didFinishImageLoading(with: data, for: model)

            case let .failure(error):
                self?.presenter?.didFinishImageLoading(with: error, for: model)
            }
        }
    }

    func didCancelImageRequest() {
        task?.cancel()
        task = nil
    }
}
