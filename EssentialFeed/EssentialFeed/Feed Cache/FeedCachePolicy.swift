//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 27.12.2024.
//

import Foundation

final class FeedCachePolicy {
    private static let calendar = Calendar(identifier: .gregorian)
    
    private static var maxCacheDays: Int {
        return 7
    }
    
    private init(){}
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheDays, to: timestamp) else {
            return false
        }
        return date < maxCacheAge
    }
}
