//
//  FeedImageCellViewModel.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 22.01.2025.
//

import Foundation
import EssentialFeed

public class FeedImageCellViewModel<Image> {
    typealias Observer<T> = (T) -> Void
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader
    private let imageTransformer: (Data) -> Image?
    
    private var task: FeedImageDataLoaderTask?
    
    var onImageLoad: Observer<Image>?
    var onImageLoadingStateChange: Observer<Bool>?
    var onShouldRetryImageLoadStateChange: Observer<Bool>?
    
    init(model: FeedImage, imageLoader: FeedImageDataLoader, imageTransformer: @escaping (Data) -> Image?) {
        self.model = model
        self.imageLoader = imageLoader
        self.imageTransformer = imageTransformer
    }
    
    var description: String? {
        return model.description
    }
    
    var location: String?  {
        return model.location
    }
    
    var hasLocation: Bool {
        return location != nil
    }
    
    func loadImage() {
        startImageLoad()
        task = imageLoader.loadImageData(from: model.url) { [weak self] in self?.completeImageLoad($0) }
    }
    
    func cancelImageLoading() {
        task?.cancel()
        task = nil
    }
    
    private func startImageLoad() {
        onImageLoadingStateChange?(true)
        onShouldRetryImageLoadStateChange?(false)
    }
    
    private func completeImageLoad(_ result: FeedImageDataLoader.Result) {
        if let image = (try? result.get()).flatMap(imageTransformer) {
            onImageLoad?(image)
        } else {
            onShouldRetryImageLoadStateChange?(true)
        }
        onImageLoadingStateChange?(false)
    }
}
