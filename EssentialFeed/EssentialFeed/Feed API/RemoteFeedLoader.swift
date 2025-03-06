//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 09.12.2024.
//
import Foundation

public typealias RemoteFeedLoader = RemoteLoader<[FeedImage]>
public extension RemoteFeedLoader {
    convenience init(client: HTTPClient, url: URL) {
        self.init(client: client, url: url, mapper: RemoteFeedLoaderDataMapper.map)
    }
}
