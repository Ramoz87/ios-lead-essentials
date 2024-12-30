//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 30.12.2024.
//

import Foundation

final public class CodableFeedStore: FeedStore {
    
    private let storeUrl: URL
    
    public init(storeUrl: URL) {
        self.storeUrl = storeUrl
    }
    
    public func retrieve(completion: @escaping RetrieveCompletion) {
        guard let data = try? Data(contentsOf: storeUrl) else {
            return completion(.empty)
        }
        
        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
        do {
            let encoder = JSONEncoder()
            let codableFeed = feed.map(CodableFeedImage.init)
            let cache = Cache(feed: codableFeed, timestamp: timestamp)
            let encoded = try encoder.encode(cache)
            try encoded.write(to: storeUrl)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        guard FileManager.default.fileExists(atPath: storeUrl.path) else {
            return completion(nil)
        }
        
        do {
            try FileManager.default.removeItem(at: storeUrl)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

private extension CodableFeedStore {
    
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            return feed.map { $0.local }
        }
    }
    
    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id,
                                  description: description,
                                  location: location,
                                  url: url)
        }
    }
}
