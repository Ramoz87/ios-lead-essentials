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
    
    private let queue = DispatchQueue(label:  "\(CodableFeedStore.self)Queue", qos: .userInitiated, attributes: .concurrent)
    
    public func retrieve(completion: @escaping RetrieveCompletion) {
        let url = storeUrl
        queue.async {
            guard let data = try? Data(contentsOf: url) else {
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
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertCompletion) {
        let url = storeUrl
        queue.async(flags: .barrier) {
            do {
                let encoder = JSONEncoder()
                let codableFeed = feed.map(CodableFeedImage.init)
                let cache = Cache(feed: codableFeed, timestamp: timestamp)
                let encoded = try encoder.encode(cache)
                try encoded.write(to: url)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeleteCompletion) {
        let url = storeUrl
        queue.async(flags: .barrier) {
            guard FileManager.default.fileExists(atPath: url.path) else {
                return completion(nil)
            }
            
            do {
                try FileManager.default.removeItem(at: url)
                completion(nil)
            } catch {
                completion(error)
            }
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
