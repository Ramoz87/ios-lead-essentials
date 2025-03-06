//
//  RemoteFeedLoader 2.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 05.03.2025.
//
import Foundation

public typealias RemoteImageCommentsLoader = RemoteLoader<[ImageComment]>
public extension RemoteImageCommentsLoader {
    convenience init(client: HTTPClient, url: URL) {
        self.init(client: client, url: url, mapper: ImageCommentsMapper.map)
    }
}
