//
//  HTTPClientResult.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 12.12.2024.
//

import Foundation

public protocol HTTPClientTask {
    func cancel()
}

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    @discardableResult
    @available(*, deprecated, message: "Use async alternative")
    func get(from url: URL, completion: @Sendable @escaping (Result) -> Void) -> HTTPClientTask
    
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}

@MainActor
public extension HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        nonisolated(unsafe) var task: HTTPClientTask?
        
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                task = get(from: url) { continuation.resume(with: $0) }
            }
        } onCancel: {
            task?.cancel()
        }
    }
}
