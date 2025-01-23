//
//  FeedRefreshViewController.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//

import UIKit

public class FeedRefreshViewController: NSObject, FeedLoadingView {
    typealias LoadFeed = () -> Void
   
    private let load: LoadFeed

    init(load: @escaping LoadFeed) {
        self.load = load
    }
    
    public lazy var view: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()
        
    @objc func refresh() {
        load()
    }
        
    func display(_ model: FeedLoadingViewModel) {
        if model.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
}
