//
//  CommentsViewAdapter.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 25.03.2025.
//
import Foundation
import EssentialFeed
import EssentialFeediOS

@MainActor
final class CommentsViewAdapter: ResourceView {
    private weak var controller: ListViewController?
    
    init(controller: ListViewController) {
        self.controller = controller
    }
    
    func display(_ viewModel: ImageCommentsViewModel) {
        controller?.display(viewModel.comments.map { viewModel in
            CellController(id: viewModel, ImageCommentCellController(model: viewModel))
        })
    }
}
