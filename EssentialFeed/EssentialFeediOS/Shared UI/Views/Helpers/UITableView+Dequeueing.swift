//
//  UITableView+Dequeueing.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 24.01.2025.
//

import UIKit

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        let identifier = String(describing: T.self)
        return dequeueReusableCell(withIdentifier: identifier) as! T
    }
}
