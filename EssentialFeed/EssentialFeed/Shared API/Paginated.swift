//
//  Paginated.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 04.04.2025.
//
import Foundation

public struct Paginated<Item> {
    public typealias LoadMoreBlock = (Result<Self, Error>) -> Void

    public let items: [Item]
    public let loadMore: ((@escaping LoadMoreBlock) -> Void)?

    public init(items: [Item], loadMore: ((@escaping LoadMoreBlock) -> Void)? = nil) {
        self.items = items
        self.loadMore = loadMore
    }
}
