//
//  HTTPClient+Publisher.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 10.04.2025.
//

import Combine
import Foundation
import EssentialFeed

@MainActor
public extension HTTPClient {
    typealias Publisher = AnyPublisher<(Data, HTTPURLResponse), Error>
    
    func getPublisher(url: URL) -> Publisher {
        var task: Task<Void, Never>?
        
        return Deferred {
            Future { completion in
                nonisolated(unsafe) let uncheckedCompletion = completion
                task = Task.immediate {
                    do {
                        let result = try await self.get(from: url)
                        uncheckedCompletion(.success(result))
                    } catch {
                        uncheckedCompletion(.failure(error))
                    }
                }
            }
        }
        .handleEvents(receiveCancel: { task?.cancel() })
        .eraseToAnyPublisher()
    }
}
