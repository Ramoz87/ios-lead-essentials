//
//  FeedErrorViewModel.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 05.02.2025.
//

import Foundation

public final class FeedPresenter {
    public static var title: String {
        return NSLocalizedString("FEED_VIEW_TITLE",
                                 tableName: "Feed",
                                 bundle: .init(for: FeedPresenter.self),
                                 comment: "Title for the feed view")
    }
}
