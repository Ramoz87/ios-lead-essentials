//
//  CellController.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.03.2025.
//
import UIKit

public struct CellController {
    let id: any Hashable & Sendable
    let dataSource: UITableViewDataSource
    let delegate: UITableViewDelegate?
    let prefetching: UITableViewDataSourcePrefetching?
    
    public init(id: any Hashable & Sendable, _ dataSource: UITableViewDataSource) {
        self.id = id
        self.dataSource = dataSource
        self.delegate = dataSource as? UITableViewDelegate
        self.prefetching = dataSource as? UITableViewDataSourcePrefetching
    }
}

extension CellController: nonisolated Equatable {
    public nonisolated static func == (lhs: CellController, rhs: CellController) -> Bool {
        AnyHashable(lhs.id) == AnyHashable(rhs.id)
    }
}

extension CellController: nonisolated Hashable {
    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(AnyHashable(self.id))
    }
}
