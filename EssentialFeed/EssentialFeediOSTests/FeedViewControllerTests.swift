//
//  FeedViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Yury Ramazanov on 16.01.2025.
//

import XCTest
import EssentialFeed
import EssentialFeediOS

final class FeedViewControllerTests: XCTestCase {

    func test_loadFeedActions_requestFeedFromLoader() {
        let (sut, loader) = makeSUT()
                
        sut.simulateAppearance()
        XCTAssertEqual(loader.loadCallCount, 1, "Expected loading requests when view appears time")
        loader.completeFeedLoading()
        
        sut.simulateAppearance()
        XCTAssertEqual(loader.loadCallCount, 1, "Expected no loading requests when view appeares another time")
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadCallCount, 2, "Expected a loading request when user initiates a reload")
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadCallCount, 3, "Expected another loading request when user initiates a reload")
    }
    
    func test_loadFeedActions_loadingIndicatorIsVisibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.isShowingLoadingIndicator, true, "Expected loading indicator is visible when view appears")
        
        loader.completeFeedLoading()
        XCTAssertEqual(sut.isShowingLoadingIndicator, false, "Expected loading indicator hides when loading finished")
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.isShowingLoadingIndicator, false, "Expected loading indicator is not visible anymore when view appears next time")
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(sut.isShowingLoadingIndicator, true, "Expected loading indicator visible when user initiates a reload")
       
        loader.completeFeedLoading()
        XCTAssertEqual(sut.isShowingLoadingIndicator, false, "Expected loading indicator hides when user initiated reload finished")
    }
    
    //MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (FeedViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackMemoryLeaks(sut, file: file, line: line)
        trackMemoryLeaks(loader, file: file, line: line)
        return (sut, loader)
    }
    
    class LoaderSpy: FeedLoader {
        private var completions = [(FeedLoader.Result) -> Void]()
        var loadCallCount: Int {
            return completions.count
        }
        
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            completions.append(completion)
        }
        
        func completeFeedLoading(at index: Int = 0) {
            completions[index](.success([]))
        }
    }
}

private extension FeedViewController {
 
    func replaceRefreshControlWithFakeForiOS17() {
        let fakeRefreshControl = FakeRefreshControl()
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                fakeRefreshControl.addTarget(target, action: Selector($0), for: .valueChanged)
            }
        }
        refreshControl = fakeRefreshControl
    }
    
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            replaceRefreshControlWithFakeForiOS17()
        }
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    
    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }
}

private extension UIRefreshControl {
    
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}

private class FakeRefreshControl: UIRefreshControl {
    
    private var _isRefreshing: Bool = false
    
    override var isRefreshing: Bool {
        return _isRefreshing
    }
    
    override func beginRefreshing() {
        _isRefreshing = true
    }
    
    override func endRefreshing() {
        _isRefreshing = false
    }
}
