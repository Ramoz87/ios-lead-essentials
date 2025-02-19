//
//  FeedImageDataStore.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 19.02.2025.
//

import Foundation

public protocol FeedImageDataStore {
    typealias Result = Swift.Result<Data?, Error>
    typealias InsertResult = Swift.Result<Void, Error>

    func retrieve(dataForURL url: URL, completion: @escaping (Result) -> Void)
    func insert(_ data: Data, for url: URL, completion: @escaping (InsertResult) -> Void)
}
