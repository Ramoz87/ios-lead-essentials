//
//  HTTPClient+Publisher.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 10.04.2025.
//

import Combine
import Foundation
import EssentialFeed

public extension HTTPClient {
    typealias Publisher = AnyPublisher<(Data, HTTPURLResponse), Error>

    func getPublisher(url: URL) -> Publisher {
        var task: HTTPClientTask?
        
        return Deferred {
            Future { completion in
                nonisolated(unsafe) let uncheckedCompletion = completion
                task = get(from: url, completion: { uncheckedCompletion($0) })
            }
        }
        .handleEvents(receiveCancel: { task?.cancel() })
        .eraseToAnyPublisher()
    }
}
