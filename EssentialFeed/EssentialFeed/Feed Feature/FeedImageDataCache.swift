//
//  FeedImageDataCache.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.02.2025.
//
import Foundation

public protocol FeedImageDataCache {
    func save(_ data: Data, for url: URL) throws
}
