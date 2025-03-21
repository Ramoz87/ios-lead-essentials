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
    
    func test_configureWindow_setsWindowAsKeyAndVisible() {
        let window = UIWindowSpy()
        let sut = SceneDelegate()
        sut.window = window
    
        sut.configureWindow()

        XCTAssertEqual(window.makeKeyAndVisibleCallCount, 1, "Expected to make window key and visible")
    }
    
    func test_configureWindow_configuresRootViewController() {
        let sut = SceneDelegate()
        sut.window = UIWindow()
        
        sut.configureWindow()
     
        let rootController = sut.window?.rootViewController
        let navigationController = rootController as? UINavigationController
        let topController = navigationController?.topViewController
        
        XCTAssertNotNil(navigationController, "Expected a navigation controller as root, got \(String(describing: rootController)) instead")
        XCTAssertTrue(topController is ListViewController, "Expected a feed controller as top view controller, got \(String(describing: topController)) instead")
    }
}

private class UIWindowSpy: UIWindow {
  var makeKeyAndVisibleCallCount = 0

  override func makeKeyAndVisible() {
    makeKeyAndVisibleCallCount += 1
  }
}
