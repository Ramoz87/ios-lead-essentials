//
//  FeedCacheHelpers.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 26.12.2024.
//

import Foundation
import EssentialFeed

func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
}

func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let models = [uniqueImage(), uniqueImage()]
    let local = models.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    return (models, local)
}

extension Date {
    private var feedCacheMaxAgeInDays: Int {
        return 7
    }
    
    func maxFeedCacheAge() -> Date {
        return adding(days: -feedCacheMaxAgeInDays)
    }
}
