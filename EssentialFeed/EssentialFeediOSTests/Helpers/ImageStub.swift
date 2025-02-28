//
//  ImageStub.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 28.02.2025.
//
import UIKit
import EssentialFeediOS
@testable import EssentialFeed

final class ImageStub: FeedImageCellControllerDelegate {
    let viewModel: FeedImageViewModel<UIImage>
    weak var controller: FeedImageCellController?

    init(description: String?, location: String?, image: UIImage?) {
        viewModel = FeedImageViewModel(
            description: description,
            location: location,
            image: image,
            isLoading: false,
            shouldRetry: image == nil)
    }
    
    func didRequestImage() {
        controller?.display(viewModel)
    }
    
    func didCancelImageRequest() {}
}

extension FeedViewController {
    func display(_ images: [ImageStub]) {
        let model = images.map { stub in
            let cellController = FeedImageCellController(delegate: stub)
            stub.controller = cellController
            return cellController
        }
        display(model)
    }
}
