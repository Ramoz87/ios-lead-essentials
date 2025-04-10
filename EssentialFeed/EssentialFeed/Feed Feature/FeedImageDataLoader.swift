//
//  FeedImageDataLoader.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//
import Foundation

public protocol FeedImageDataLoader {
    func loadImageData(from url: URL) throws -> Data
}
