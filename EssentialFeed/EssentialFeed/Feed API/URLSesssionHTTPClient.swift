//
//  URLSesssionHTTPClient.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 13.12.2024.
//

import Foundation

public class URLSesssionHTTPClient: HTTPClient {
   
    private let session: URLSession
    
    public init(session: URLSession) {
        self.session = session
    }
    
    public func get(from url: URL, completeion: @escaping (HTTPClientResult) -> Void) {
        
        let request = URLRequest(url: url)
        session.dataTask(with: request) { data, response, error in
            if let error {
                completeion(.failure(error))
            }
        }.resume()
    }
}
