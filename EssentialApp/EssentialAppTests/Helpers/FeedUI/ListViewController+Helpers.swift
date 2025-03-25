//
//  ListViewController+Helpers.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//

import UIKit
import EssentialFeediOS

extension ListViewController {
    
    private var dataSource: (any UITableViewDataSource)? {
        return tableView.dataSource
    }
    private var delegate: (any UITableViewDelegate)? {
        return tableView.delegate
    }
    private var prefetchDataSource: (any UITableViewDataSourcePrefetching)? {
        return tableView.prefetchDataSource
    }
    
    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }
    
    var errorMessage: String? {
        return errorView.message
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
    
    func simulateUserInitiatedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    func simulateErrorViewTap() {
        errorView.simulateTap()
    }
}

extension ListViewController {
    
    private var feedImagesSection: Int {
        return 0
    }
    
    func numberOfRenderedFeedImageViews() -> Int {
        tableView.numberOfSections == 0 ? 0 : tableView.numberOfRows(inSection: feedImagesSection)
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
        guard numberOfRenderedFeedImageViews() > row else { return nil }
        let index = IndexPath(row: row, section: feedImagesSection)
        return dataSource?.tableView(tableView, cellForRowAt: index)
    }
    
    func renderedFeedImageData(at index: Int) -> Data? {
        return simulateFeedImageViewVisible(at: index)?.renderedImage
    }
    
    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        return feedImageView(at: index) as? FeedImageCell
    }
    
    @discardableResult
    func simulateFeedImageBecomingVisibleAgain(at row: Int) -> FeedImageCell? {
        let view = simulateFeedImageViewNotVisible(at: row)
        
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        delegate?.tableView?(tableView, willDisplay: view!, forRowAt: index)
        return view
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
    
    func simulateTapOnFeedImage(at row: Int) {
        let index = IndexPath(row: row, section: feedImagesSection)
        delegate?.tableView?(tableView, didSelectRowAt: index)
    }
}

extension ListViewController {
    
    private var commentsSection: Int {
        return 0
    }
    
    func numberOfRenderedComments() -> Int {
        tableView.numberOfSections == 0 ? 0 :  tableView.numberOfRows(inSection: commentsSection)
    }

    func commentMessage(at row: Int) -> String? {
        commentView(at: row)?.messageLabel.text
    }

    func commentDate(at row: Int) -> String? {
        commentView(at: row)?.dateLabel.text
    }

    func commentUsername(at row: Int) -> String? {
        commentView(at: row)?.usernameLabel.text
    }

    private func commentView(at row: Int) -> ImageCommentCell? {
        guard numberOfRenderedComments() > row else { return nil }
        let index = IndexPath(row: row, section: commentsSection)
        return dataSource?.tableView(tableView, cellForRowAt: index) as? ImageCommentCell
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
