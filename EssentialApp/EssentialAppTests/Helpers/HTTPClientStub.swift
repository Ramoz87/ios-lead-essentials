//
//  HTTPClientStub.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 27.02.2025.
//
import Foundation
import EssentialFeed

class HTTPClientStub: HTTPClient {
   
    private let stub: (URL) -> Result<(Data, HTTPURLResponse), Error>
    
    init(stub: @escaping (URL) -> Result<(Data, HTTPURLResponse), Error>) {
        self.stub = stub
    }
    
    static var offline: HTTPClientStub {
        HTTPClientStub(stub: { _ in .failure(NSError(domain: "offline", code: 0)) })
    }
    
    static func online(_ stub: @escaping (URL) -> Result<(Data, HTTPURLResponse), Error>) -> HTTPClientStub {
        HTTPClientStub { stub($0) }
    }
    
    //MARK: - HTTPClient
    
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        return try stub(url).get()
    }
}
