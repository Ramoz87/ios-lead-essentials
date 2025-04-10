//
//  Paginated+Publisher.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 10.04.2025.
//

import Foundation
import Combine
import EssentialFeed

public extension Paginated {
    typealias Publisher = AnyPublisher<Self, Error>
    
    init(items: [Item], loadMorePublisher: (() -> Publisher)?) {
        
        self.init(items: items, loadMore: loadMorePublisher.map { publisher in
            return { completion in
                
                publisher().subscribe(
                    Subscribers.Sink(
                        receiveCompletion: { result in
                            if case let .failure(error) = result {
                                completion(.failure(error))
                            }
                        },
                        receiveValue: { result in
                            completion(.success(result))
                        }))
            }
        })
    }
    
    var loadMorePublisher: Publisher? {
        guard let loadMore else { return nil }
        return Deferred { Future(loadMore) }.eraseToAnyPublisher()
    }
}
