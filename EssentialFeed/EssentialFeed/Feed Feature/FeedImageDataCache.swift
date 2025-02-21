//
//  FeedImageDataCache.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.02.2025.
//
import Foundation

public protocol FeedImageDataCache {
    typealias SaveResult = Result<Void, Swift.Error>
    func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void)
}
