//
//  FeedImagePresenter.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 05.02.2025.
//

import Foundation

final public class FeedImagePresenter {
    public static func map(_ image: FeedImage) -> FeedImageViewModel {
        FeedImageViewModel(
            description: image.description,
            location: image.location)
    }
}
