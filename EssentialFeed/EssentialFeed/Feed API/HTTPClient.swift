//
//  HTTPClientResult.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 12.12.2024.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func get(from url: URL, completeion: @escaping (Result) -> Void)
}
