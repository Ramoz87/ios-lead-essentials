//
//  HTTPClientStub.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 27.02.2025.
//
import Foundation
import EssentialFeed

class HTTPClientStub: HTTPClient {
    private class Task: HTTPClientTask {
        func cancel() {}
    }
    
    private let stub: (URL) -> HTTPClient.Result
    
    init(stub: @escaping (URL) -> HTTPClient.Result) {
        self.stub = stub
    }
    
    static var offline: HTTPClientStub {
        HTTPClientStub(stub: { _ in .failure(NSError(domain: "offline", code: 0)) })
    }
    
    static func online(_ stub: @escaping (URL) -> HTTPClient.Result) -> HTTPClientStub {
        HTTPClientStub { stub($0) }
    }
    
    //MARK: - HTTPClient
    
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        completion(stub(url))
        return Task()
    }
}
