//
//  UIRefreshcontrol+Helper.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 04.02.2025.
//

import UIKit

extension UIRefreshControl {
    func update(isRefreshing: Bool) {
        isRefreshing ? beginRefreshing() : endRefreshing()
    }
}
