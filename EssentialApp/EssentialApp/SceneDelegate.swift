//
//  SceneDelegate.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 19.02.2025.
//

import UIKit
import CoreData
import os
import EssentialFeed
import EssentialFeediOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    private lazy var baseURL = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed")!
    private lazy var logger = Logger(subsystem: "com.essentialdeveloper.EssentialApp", category: "main")
    
    private lazy var client: HTTPClient = {
        URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    }()
    
    private lazy var store: FeedStore & FeedImageDataStore & Scheduler & Sendable = {
        do {
            return try CoreDataFeedStore(
                storeUrl: NSPersistentContainer
                    .defaultDirectoryURL()
                    .appendingPathComponent("feed-store.sqlite"))
        } catch {
            assertionFailure("Failed to instantiate CoreData store with error: \(error.localizedDescription)")
            logger.fault("Failed to instantiate CoreData store with error: \(error.localizedDescription)")
            return InMemoryFeedStore()
        }
    }()
    
    private lazy var navigationController = {
        let controller = FeedUIComposer.feedViewController(
            feedLoader: loadRemoteFeedWithLocalFallback,
            imageLoader: loadLocalImageWithRemoteFallback,
            selection: showComments)
        return UINavigationController(rootViewController: controller)
    }()

    convenience init(httpClient: HTTPClient, store: FeedStore & FeedImageDataStore & Scheduler & Sendable) {
        self.init()
        self.client = httpClient
        self.store = store
    }
   
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        configureWindow()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        validateCache()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    func configureWindow() {
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    private func showComments(for image: FeedImage) {
        let url = ImageCommentsEndpoint.get(image.id).url(baseURL: baseURL)
        let comments = CommentsUIComposer.commentsController(loader: loadRemoteComments(url: url))
        navigationController.pushViewController(comments, animated: true)
    }
    
    private func loadRemoteFeedWithLocalFallback() async throws -> Paginated<FeedImage> {
        do {
            let feed = try await loadAndCacheRemoteFeed()
            return makePage(items: feed, last: feed.last)
        }
        catch {
            let feed = try await loadLocalFeed()
            return makePage(items: feed, last: feed.last)
        }
    }
    
    private func loadAndCacheRemoteFeed() async throws -> [FeedImage] {
        let feed = try await loadRemoteFeed()
        await store.schedule { [store] in
            let localFeedLoader = LocalFeedLoader(store: store, date: Date.init)
            try? localFeedLoader.save(feed)
        }
        return feed
    }
    
    private func loadLocalFeed() async throws -> [FeedImage] {
        try await store.schedule { [store] in
            let localFeedLoader = LocalFeedLoader(store: store, date: Date.init)
            return try localFeedLoader.load()
        }
    }
    
    private func loadRemoteFeed(after: FeedImage? = nil) async throws -> [FeedImage] {
        let url = FeedEndpoint.get(after: after).url(baseURL: baseURL)
        let (data, response) = try await client.get(from: url)
        return try RemoteFeedLoaderDataMapper.map(data, response)
    }
    
    private func loadMoreRemoteFeed(last: FeedImage?) async throws -> Paginated<FeedImage> {
        async let cachedFeed = try await loadLocalFeed()
        async let newFeed = try await loadRemoteFeed(after: last)
       
        let items = try await cachedFeed + newFeed
        
        await store.schedule { [store] in
            let localFeedLoader = LocalFeedLoader(store: store, date: Date.init)
            try? localFeedLoader.save(items)
        }
        
        return try await makePage(items: items, last: newFeed.last)
    }
    
    private func loadLocalImageWithRemoteFallback(url: URL) async throws -> Data {
        do {
            return try await loadLocalImage(url: url)
        } catch {
            return try await loadAndCacheRemoteImage(url: url)
        }
    }
    
    private func loadAndCacheRemoteImage(url: URL) async throws -> Data {
        let (data, response) = try await client.get(from: url)
        let imageData = try RemoteFeedImageDataMapper.map(data, from: response)
        await store.schedule { [store] in
            let localImageLoader = LocalFeedImageDataLoader(store: store)
            try? localImageLoader.save(data, for: url)
        }
        return imageData
    }
    
    private func loadLocalImage(url: URL) async throws -> Data {
        try await store.schedule { [store] in
            let localImageLoader = LocalFeedImageDataLoader(store: store)
            let imageData = try localImageLoader.loadImageData(from: url)
            return imageData
        }
    }
    
    private func loadRemoteComments(url: URL) -> () async throws -> [ImageComment] {
        return { [client] in
            let (data, response) = try await client.get(from: url)
            return try ImageCommentsMapper.map(data, response)
        }
    }
    
    private func makePage(items: [FeedImage], last: FeedImage?) -> Paginated<FeedImage> {
        Paginated(items: items, loadMore: last.map { last in
            { @MainActor @Sendable in try await self.loadMoreRemoteFeed(last: last) }
        })
    }
    
    private func validateCache() {
        Task.immediate {
            await store.schedule { [store, logger] in
                do {
                    let localFeedLoader = LocalFeedLoader(store: store, date: Date.init)
                    try localFeedLoader.validateCache()
                } catch {
                    logger.error("Failed to validate cache with error: \(error.localizedDescription)")
                }
            }
        }
    }
}

protocol Scheduler {
    @MainActor
    func schedule<T>(_ action: @escaping @Sendable () throws -> T) async rethrows -> T
}

extension CoreDataFeedStore: Scheduler {
    @MainActor
    func schedule<T>(_ action: @escaping @Sendable () throws -> T) async rethrows -> T {
        if contextQueue == .main {
            return try action()
        } else {
            return try await perform(action)
        }
    }
}

extension InMemoryFeedStore: Scheduler {
    @MainActor
    func schedule<T>(_ action: @escaping @Sendable () throws -> T) async rethrows -> T {
        try action()
    }
}
