//
//  FeedViewController.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 16.01.2025.
//

import UIKit
import EssentialFeed

public protocol FeedImageDataLoader {
    func loadImageData(from url: URL)
}

public class FeedViewController: UITableViewController {

    private var onViewIsAppearing: (() -> Void)?
    private var feedLoader: FeedLoader?
    private var imageLoader: FeedImageDataLoader?
    
    private var tableModel = [FeedImage]()
    
    public convenience init(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) {
        self.init()
        self.feedLoader = feedLoader
        self.imageLoader = imageLoader
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
        feedLoader?.load { [weak self] result in
            if let images = try? result.get() {
                self?.tableModel = images
                self?.tableView.reloadData()
            }
            
            self?.refreshControl?.endRefreshing()
        }
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = tableModel[indexPath.row]
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = (cellModel.location == nil)
        cell.locationLabel.text = cellModel.location
        cell.descriptionLabel.text = cellModel.description
        imageLoader?.loadImageData(from: cellModel.url)
        return cell
    }
}
