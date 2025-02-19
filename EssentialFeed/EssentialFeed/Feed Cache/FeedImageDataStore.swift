//
//  FeedImageDataStore.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 19.02.2025.
//

import Foundation

public protocol FeedImageDataStore {
    typealias RetrieveResult = Result<Data?, Error>
    typealias InsertResult = Result<Void, Error>

    func retrieve(dataForURL url: URL, completion: @escaping (RetrieveResult) -> Void)
    func insert(_ data: Data, for url: URL, completion: @escaping (InsertResult) -> Void)
}
