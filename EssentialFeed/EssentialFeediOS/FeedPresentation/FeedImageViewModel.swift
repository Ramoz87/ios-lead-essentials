//
//  FeedImageViewModel.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 23.01.2025.
//

struct FeedImageViewModel<Image> {
    let description: String?
    let location: String?
    let image: Image?
    let isLoading: Bool
    let shouldRetry: Bool
    
    var hasLocation: Bool {
        return location != nil
    }
}
