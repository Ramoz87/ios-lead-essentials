//
//  SceneDelegateTests.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 27.02.2025.
//
import XCTest
import EssentialFeediOS
@testable import EssentialApp

final class SceneDelegateTests: XCTestCase {
    
    func test_sceneWillConnectToSession_configuresRootViewController() {
        let sut = SceneDelegate()
        sut.window = UIWindow()
        
        sut.configureWindow()
     
        let rootController = sut.window?.rootViewController
        let navigationController = rootController as? UINavigationController
        let topController = navigationController?.topViewController
        
        XCTAssertNotNil(navigationController, "Expected a navigation controller as root, got \(String(describing: rootController)) instead")
        XCTAssertTrue(topController is FeedViewController, "Expected a feed controller as top view controller, got \(String(describing: topController)) instead")
    }
}
