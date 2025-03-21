//
//  FeedAcceptanceTests.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 27.02.2025.
//
import XCTest
import EssentialFeed
import EssentialFeediOS
@testable import EssentialApp

final class FeedAcceptanceTests: XCTestCase {
    
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
        let feed = launch(httpClient: .online(successResult), store: .empty)
    
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 2)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData())
    }
    
    func test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity() {
        let store = InMemoryFeedStore.empty
        
        let onlineFeed = launch(httpClient: .online(successResult), store: store)
        onlineFeed.simulateFeedImageViewVisible(at: 0)
        onlineFeed.simulateFeedImageViewVisible(at: 1)
        
        let offlineFeed = launch(httpClient: .offline, store: store)
        
        XCTAssertEqual(offlineFeed.numberOfRenderedFeedImageViews(), 2)
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 0), makeImageData())
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 1), makeImageData())
    }
    
    func test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndNoCache() {
        let feed = launch(httpClient: .offline, store: .empty)
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 0)
    }
    
    func test_onEnteringBackground_deletesExpiredFeedCache() {
        let store = InMemoryFeedStore.withExpiredFeedCache
        
        enterBackground(store: store)
        
        XCTAssertNil(store.feedCache, "Expected to delete expired cache")
    }
    
    func test_onEnteringBackground_keepsNonExpiredFeedCache() {
        let store = InMemoryFeedStore.withNonExpiredFeedCache
        
        enterBackground(store: store)
        
        XCTAssertNotNil(store.feedCache, "Expected to keep non-expired cache")
    }
    //MARK: - Private
    
    private func launch(
        httpClient: HTTPClientStub = .offline,
        store: InMemoryFeedStore = .empty
    ) -> ListViewController {
        let sut = SceneDelegate(httpClient: httpClient, store: store)
        sut.window = UIWindow()
        sut.configureWindow()
        
        let nav = sut.window?.rootViewController as? UINavigationController
        let ctrl = nav?.topViewController as! ListViewController
        ctrl.simulateAppearance()
        
        return ctrl
    }
    
    private func enterBackground(httpClient: HTTPClientStub = .offline, store: InMemoryFeedStore) {
        let sut = SceneDelegate(httpClient: httpClient, store: store)
        let scene = UIApplication.shared.connectedScenes.first!
        sut.sceneWillResignActive(scene)
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
        return UIImage.make(withColor: .red).pngData()!
    }
        
    private func successResult(for url: URL) -> HTTPClient.Result {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let data = data(for: url)
        return .success((data, response))
    }
}
