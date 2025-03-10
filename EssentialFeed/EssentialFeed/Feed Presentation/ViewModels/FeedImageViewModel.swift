//
//  FeedImageViewModel.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 05.02.2025.
//

public struct FeedImageViewModel {
    public let description: String?
    public let location: String?
  
    public var hasLocation: Bool {
        return location != nil
    }
}
