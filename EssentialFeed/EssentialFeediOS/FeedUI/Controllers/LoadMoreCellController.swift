//
//  FeedImageCellController.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//

import UIKit
import EssentialFeed

public class LoadMoreCellController: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    private lazy var loadCell: LoadMoreCell = {
        let cell = LoadMoreCell()
        cell.selectionStyle = .none
        return cell
    }()
    
    private let callback: () -> Void
    
    public init(callback: @escaping () -> Void) {
        self.callback = callback
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return loadCell
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        loadIfNeeded()
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        loadIfNeeded()
    }
    
    private func loadIfNeeded() {
        guard !loadCell.isLoading else { return }
        callback()
    }
}

extension LoadMoreCellController: ResourceLoadingView, ResourceErrorView {
    public func display(_ viewModel: EssentialFeed.ResourceErrorViewModel) {
        loadCell.message = viewModel.message
    }
    
    public func display(_ viewModel: ResourceLoadingViewModel) {
        loadCell.isLoading = viewModel.isLoading
    }
}
