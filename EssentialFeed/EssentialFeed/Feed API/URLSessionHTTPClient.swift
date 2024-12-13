//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 13.12.2024.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
   
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedError: Error {}
    
    public func get(from url: URL, completeion: @escaping (HTTPClientResult) -> Void) {
        let request = URLRequest(url: url)
        session.dataTask(with: request) { data, response, error in
            if let data, let response = response as? HTTPURLResponse {
                completeion(.success(data, response))
            } else if let error {
                completeion(.failure(error))
            } else {
                completeion(.failure(UnexpectedError()))
            }
        }.resume()
    }
}
