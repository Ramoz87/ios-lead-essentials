//
//  DebugSceneDelegate.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 24.02.2025.
//
#if DEBUG
import UIKit
import EssentialFeed
import EssentialFeediOS

final class DebugSceneDelegate: SceneDelegate {
   
    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if CommandLine.arguments.contains("-reset") {
            try? FileManager.default.removeItem(at: localUrl)
        }
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }
}

private class DebuggingHTTPClient: HTTPClient {
    private class Task: HTTPClientTask {
        func cancel() {}
    }
    
    private let connectivity: String
    
    init(connectivity: String) {
        self.connectivity = connectivity
    }
    
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        switch connectivity {
        case "online": completion(successResult(for: url))
        default: completion(failureResult())
        }
        return Task()
    }
    
    private func failureResult() -> HTTPClient.Result {
        .failure(NSError(domain: "offline", code: 0))
    }
    
    private func successResult(for url: URL) -> HTTPClient.Result {
        .success(makeSuccessfulResponse(for: url))
    }
    
    private func makeSuccessfulResponse(for url: URL) -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (data(for: url), response)
    }
    
    private let imageUrl = "http://image.com"
    
    private func data(for url: URL) -> Data {
        switch url.absoluteString {
        case imageUrl: makeImageData()
        default: makeFeedData()
        }
    }
    
    private func makeFeedData() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": [
            ["id": UUID().uuidString, "image": imageUrl],
            ["id": UUID().uuidString, "image": imageUrl]
        ]])
    }
    
    private func makeImageData() -> Data {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!.pngData()!
    }
}
#endif
