//
//  FeedViewController.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 16.01.2025.
//

import UIKit
import EssentialFeed

public class FeedViewController: UITableViewController {

    private var onViewIsAppearing: (() -> Void)?
    private var feedLoader: FeedLoader?
    
    public convenience init(loader: FeedLoader) {
        self.init()
        self.feedLoader = loader
    }
    
    public override func viewDidLoad() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        
        onViewIsAppearing = { [weak self] in
            self?.load()
            self?.onViewIsAppearing = nil
        }
    }
    
    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        onViewIsAppearing?()
    }
    
    @objc private func load() {
        refreshControl?.beginRefreshing()
        feedLoader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}
