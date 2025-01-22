//
//  FeedRefreshViewController.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//

import UIKit

public class FeedRefreshViewController: NSObject {
    
    private let viewModel: FeedRefreshViewModel

    init(viewModel: FeedRefreshViewModel) {
        self.viewModel = viewModel
    }
    
    public lazy var view = binded(UIRefreshControl())
        
    @objc func refresh() {
        viewModel.loadFeed()
    }
    
    private func binded(_ view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onLoadingStateChange = { [weak self] isLoading in
            if isLoading {
                self?.view.beginRefreshing()
            } else {
                self?.view.endRefreshing()
            }
        }
        
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
}
