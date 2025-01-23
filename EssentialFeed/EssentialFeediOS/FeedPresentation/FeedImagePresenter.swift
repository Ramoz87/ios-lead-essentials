//
//  FeedImagePresenter.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 23.01.2025.
//

import Foundation
import EssentialFeed

protocol FeedImageView {
    associatedtype Image

    func display(_ model: FeedImageViewModel<Image>)
}

final class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image {
    
    private struct InvalidImageDataError: Error {}
    
    private let view: View
    private let imageTransformer: (Data) -> Image?
    
    init(view: View, imageTransformer: @escaping (Data) -> Image?) {
        self.view = view
        self.imageTransformer = imageTransformer
    }
    
    func didStartImageLoading(for model: FeedImage) {
        view.display(.init(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: true,
            shouldRetry: false))
    }
    
    func didFinishImageLoading(with data: Data, for model: FeedImage) {
        guard let image = imageTransformer(data) else {
            return didFinishImageLoading(with: InvalidImageDataError(), for: model)
        }
        
        view.display(.init(
            description: model.description,
            location: model.location,
            image: image,
            isLoading: false,
            shouldRetry: false))
    }
    
    func didFinishImageLoading(with error: Error, for model: FeedImage) {
        view.display(.init(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: false,
            shouldRetry: true))
    }
}
