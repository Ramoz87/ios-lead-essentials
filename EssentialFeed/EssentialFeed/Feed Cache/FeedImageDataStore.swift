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

    func retrieve(dataForURL url: URL) throws -> Data?
    func insert(_ data: Data, for url: URL) throws
    
    @available(*, deprecated)
    func retrieve(dataForURL url: URL, completion: @escaping (RetrieveResult) -> Void)
    @available(*, deprecated)
    func insert(_ data: Data, for url: URL, completion: @escaping (InsertResult) -> Void)
}

public extension FeedImageDataStore {
    func insert(_ data: Data, for url: URL) throws {
        let group = DispatchGroup()
        
        group.enter()
        var result: InsertResult!
        insert(data, for: url) {
            result = $0
            group.leave()
        }
        group.wait()
        
        return try result.get()
    }
    
    func retrieve(dataForURL url: URL) throws -> Data? {
        let group = DispatchGroup()
        
        group.enter()
        var result: RetrieveResult!
        retrieve(dataForURL: url) {
            result = $0
            group.leave()
        }
        group.wait()
        
        return try result.get()
    }
    
    func retrieve(dataForURL url: URL, completion: @escaping (RetrieveResult) -> Void) {}
    func insert(_ data: Data, for url: URL, completion: @escaping (InsertResult) -> Void) {}
}
