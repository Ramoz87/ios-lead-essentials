//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 13.12.2024.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
   
    private struct URLSessionTaskWrapper: HTTPClientTask {
        let wrapped: URLSessionTask
        
        func cancel() {
            wrapped.cancel()
        }
    }
    
    private struct UnexpectedError: Error {}
    
    private let session: URLSession
    
    public init(session: URLSession) {
        self.session = session
    }
    
    @discardableResult
    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { data, response, error in
            completion(Result {
                if let data, let response = response as? HTTPURLResponse {
                    return (data, response)
                } else if let error {
                    throw error
                } else {
                    throw UnexpectedError()
                }
            })
        }
        task.resume()
        return URLSessionTaskWrapper(wrapped: task)
    }
}
