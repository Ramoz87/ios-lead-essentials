//
//  FeedViewController+Helpers.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//

import UIKit
import EssentialFeediOS

extension FeedViewController {
 
    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }

    private var feedImagesSection: Int {
        return 0
    }
    
    private var dataSource: (any UITableViewDataSource)? {
        return tableView.dataSource
    }
    private var delegate: (any UITableViewDelegate)? {
        return tableView.delegate
    }
    private var prefetchDataSource: (any UITableViewDataSourcePrefetching)? {
        return tableView.prefetchDataSource
    }
    
    func replaceRefreshControlWithFakeForiOS17() {
        let fakeRefreshControl = FakeRefreshControl()
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                fakeRefreshControl.addTarget(target, action: Selector($0), for: .valueChanged)
            }
        }
        refreshControl = fakeRefreshControl
    }
    
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            replaceRefreshControlWithFakeForiOS17()
        }
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    func numberOfRenderedFeedImageViews() -> Int {
        return tableView.numberOfRows(inSection: feedImagesSection)
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
        let index = IndexPath(row: row, section: feedImagesSection)
        return dataSource?.tableView(tableView, cellForRowAt: index)
    }
    
    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        return feedImageView(at: index) as? FeedImageCell
    }
    
    @discardableResult
    func simulateFeedImageViewNotVisible(at index: Int) -> FeedImageCell? {
        let cell = simulateFeedImageViewVisible(at: index)
        let index = IndexPath(row: index, section: feedImagesSection)
        delegate?.tableView?(tableView, didEndDisplaying: cell!, forRowAt: index)
        return cell
    }
    
    func simulateFeedImageViewNearVisible(at row: Int) {
        let index = IndexPath(row: row, section: feedImagesSection)
        prefetchDataSource?.tableView(tableView, prefetchRowsAt: [index])
    }
    
    func simulateFeedImageViewNotNearVisible(at row: Int) {
        simulateFeedImageViewNearVisible(at: row)
        
        let index = IndexPath(row: row, section: feedImagesSection)
        prefetchDataSource?.tableView?(tableView, cancelPrefetchingForRowsAt: [index])
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
