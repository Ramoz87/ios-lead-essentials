//
//  Scheduler.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 16.12.2025.
//

import EssentialFeed

protocol Scheduler {
    @MainActor
    func schedule<T>(_ action: @escaping @Sendable () throws -> T) async rethrows -> T
}

extension CoreDataFeedStore: Scheduler {
    func schedule<T>(_ action: @escaping @Sendable () throws -> T) async rethrows -> T {
        if contextQueue == .main {
            return try action()
        } else {
            return try await perform(action)
        }
    }
}

extension InMemoryFeedStore: Scheduler {
    func schedule<T>(_ action: @escaping @Sendable () throws -> T) async rethrows -> T {
        try action()
    }
}
