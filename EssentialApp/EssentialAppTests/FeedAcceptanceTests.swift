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
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData(at: 0))
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData(at: 1))
        XCTAssertTrue(feed.canLoadMoreFeed)
        
        feed.simulateLoadMoreFeedAction()
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 3)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData(at: 0))
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData(at: 1))
        XCTAssertEqual(feed.renderedFeedImageData(at: 2), makeImageData(at: 2))
        XCTAssertTrue(feed.canLoadMoreFeed)
        
        feed.simulateLoadMoreFeedAction()
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 3)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData(at: 0))
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData(at: 1))
        XCTAssertEqual(feed.renderedFeedImageData(at: 2), makeImageData(at: 2))
        XCTAssertFalse(feed.canLoadMoreFeed)
    }
    
    func test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity() {
        let store = InMemoryFeedStore.empty
        
        let onlineFeed = launch(httpClient: .online(successResult), store: store)
        onlineFeed.simulateFeedImageViewVisible(at: 0)
        onlineFeed.simulateFeedImageViewVisible(at: 1)
        
        onlineFeed.simulateLoadMoreFeedAction()
        onlineFeed.simulateFeedImageViewVisible(at: 2)
        
        let offlineFeed = launch(httpClient: .offline, store: store)
        
        XCTAssertEqual(offlineFeed.numberOfRenderedFeedImageViews(), 3)
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 0), makeImageData(at: 0))
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 1), makeImageData(at: 1))
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 2), makeImageData(at: 2))
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
    
    func test_onFeedImageSelection_displaysComments() {
        let comments = showCommentsForFirstImage()
        
        XCTAssertEqual(comments.numberOfRenderedComments(), 1)
        XCTAssertEqual(comments.commentMessage(at: 0), makeCommentMessage())
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
    
    private func showCommentsForFirstImage() -> ListViewController {
        let feed = launch(httpClient: .online(successResult), store: .empty)
        
        feed.simulateTapOnFeedImage(at: 0)
        RunLoop.current.run(until: Date() + 1)
        
        let ctrl = feed.navigationController?.topViewController as! ListViewController
        ctrl.simulateAppearance()
        return ctrl
    }
    
    private func data(for url: URL) -> Data {
        switch url.path {
        case "/image-0": makeImageData(at: 0)
        case "/image-1": makeImageData(at: 1)
        case "/image-2": makeImageData(at: 2)
        case "/essential-feed/v1/feed" where url.query?.contains("after_id") == false:
            makeFirstFeedPageData()
        case "/essential-feed/v1/feed" where url.query?.contains("after_id=A28F5FE3-27A7-44E9-8DF5-53742D0E4A5A") == true:
            makeSecondFeedPageData()
        case "/essential-feed/v1/feed" where url.query?.contains("after_id=166FCDD7-C9F4-420A-B2D6-CE2EAFA3D82F") == true:
            makeLastEmptyFeedPageData()
        case "/essential-feed/v1/image/2AB2AE66-A4B7-4A16-B374-51BBAC8DB086/comments": makeCommentsData()
        default: Data()
        }
    }
    
    private func makeFirstFeedPageData() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": [
            ["id": "2AB2AE66-A4B7-4A16-B374-51BBAC8DB086", "image": "http://feed.com/image-0"],
            ["id": "A28F5FE3-27A7-44E9-8DF5-53742D0E4A5A", "image": "http://feed.com/image-1"]
        ]])
    }
    
    private func makeSecondFeedPageData() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": [
            ["id": "166FCDD7-C9F4-420A-B2D6-CE2EAFA3D82F", "image": "http://feed.com/image-2"],
        ]])
    }
    
    private func makeLastEmptyFeedPageData() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": []])
    }
    
    private func makeImageData(at index: Int) -> Data {
        let colors: [UIColor] = [.red, .green, .blue]
        return UIImage.make(withColor: colors[index]).pngData()!
    }
    
    private func makeCommentsData() -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": [
            [
                "id": UUID().uuidString,
                "message": makeCommentMessage(),
                "created_at": "2020-05-20T11:24:59+0000",
                "author": [
                    "username": "a username"
                ]
            ],
        ]])
    }
    
    private func makeCommentMessage() -> String {
        "a message"
    }
        
    private func successResult(for url: URL) -> HTTPClient.Result {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let data = data(for: url)
        return .success((data, response))
    }
}
