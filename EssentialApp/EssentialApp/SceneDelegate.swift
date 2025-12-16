//
//  SceneDelegate.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 19.02.2025.
//

import UIKit
import EssentialFeed
import EssentialFeediOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    private lazy var feedService = FeedService()
    
    private lazy var navigationController = {
        let controller = FeedUIComposer.feedViewController(
            feedLoader: feedService.loadRemoteFeedWithLocalFallback,
            imageLoader: feedService.loadLocalImageWithRemoteFallback,
            selection: showComments)
        return UINavigationController(rootViewController: controller)
    }()

    convenience init(httpClient: HTTPClient, store: FeedStore & FeedImageDataStore & Scheduler & Sendable) {
        self.init()
        self.feedService = FeedService(httpClient: httpClient, store: store)
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
        feedService.validateCache()
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
    
    func showComments(for image: FeedImage) {
        let comments = CommentsUIComposer.commentsController(loader: feedService.loadComments(for: image))
        navigationController.pushViewController(comments, animated: true)
    }
}
