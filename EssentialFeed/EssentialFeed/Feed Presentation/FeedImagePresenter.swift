//
//  FeedImagePresenter.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 05.02.2025.
//

import Foundation

public protocol FeedImageView {
    associatedtype Image
    
    func display(_ model: FeedImageViewModel<Image>)
}

final public class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image {
    private let view: View
    private let imageTransformer: (Data) -> Image?
    
    public init(view: View, imageTransformer: @escaping (Data) -> Image?) {
        self.view = view
        self.imageTransformer = imageTransformer
    }
    
    public func didStartImageLoading(for model: FeedImage) {
        view.display(.init(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: true,
            shouldRetry: false))
    }
    
    public func didFinishImageLoading(with data: Data, for model: FeedImage) {
        let image = imageTransformer(data)
        view.display(.init(
            description: model.description,
            location: model.location,
            image: image,
            isLoading: false,
            shouldRetry: image == nil))
    }
    
    public func didFinishImageLoading(with error: Error, for model: FeedImage) {
        view.display(.init(
            description: model.description,
            location: model.location,
            image: nil,
            isLoading: false,
            shouldRetry: true))
    }
}
