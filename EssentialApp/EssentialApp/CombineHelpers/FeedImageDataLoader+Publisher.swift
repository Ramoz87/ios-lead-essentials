//
//  FeedImageDataLoader+Publisher.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 10.04.2025.
//

import Foundation
import Combine
import EssentialFeed

public extension FeedImageDataLoader {
    typealias Publisher = AnyPublisher<Data, Error>
    
    func loadPublisher(url: URL) -> Publisher {
    
        return Deferred {
            Future { completion in
                completion( Result { try loadImageData(from: url) } )
            }
        }
        .eraseToAnyPublisher()
    }
}
