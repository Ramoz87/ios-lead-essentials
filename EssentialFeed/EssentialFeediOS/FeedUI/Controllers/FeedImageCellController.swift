//
//  FeedImageCellController.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//

import UIKit
import EssentialFeed

public class FeedImageCellController {
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader
    private var task: FeedImageDataLoaderTask?
    
    init(model: FeedImage, imageLoader: FeedImageDataLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }
    
    func view() -> UITableViewCell {
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = (model.location == nil)
        cell.locationLabel.text = model.location
        cell.descriptionLabel.text = model.description
        cell.feedImageRetryButton.isHidden = true
        cell.feedImageContainer.startShimmering()
        
        let loadImage = { [weak self, weak cell] in
            guard let self = self else { return }
            
            let url = self.model.url
            self.task = self.imageLoader.loadImageData(from: url) { [weak cell] result in
                let data = try? result.get()
                let image = data.map(UIImage.init) ?? nil
                cell?.feedImageView.image = image
                cell?.feedImageRetryButton.isHidden = (image != nil)
                cell?.feedImageContainer.stopShimmering()
            }
        }
        cell.onRetry = loadImage
        loadImage()
        
        return cell
    }
    
    func load() {
        task = imageLoader.loadImageData(from: model.url) { _ in }
    }
    
    func cancel() {
        task?.cancel()
        task = nil
    }
}
