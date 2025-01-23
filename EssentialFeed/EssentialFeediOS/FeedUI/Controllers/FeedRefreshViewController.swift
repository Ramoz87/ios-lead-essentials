//
//  FeedRefreshViewController.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//

import UIKit

protocol FeedRefreshViewControllerDelegate {
    func didRequestFeedRefresh()
}

public class FeedRefreshViewController: NSObject, FeedLoadingView {
    typealias LoadFeed = () -> Void
   
    private let delegate: FeedRefreshViewControllerDelegate

    init(delegate: FeedRefreshViewControllerDelegate) {
        self.delegate = delegate
    }
    
    public lazy var view: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()
        
    @objc func refresh() {
        delegate.didRequestFeedRefresh()
    }
        
    func display(_ model: FeedLoadingViewModel) {
        if model.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
}
