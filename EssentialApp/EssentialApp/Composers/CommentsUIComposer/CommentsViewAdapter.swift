//
//  CommentsViewAdapter.swift
//  EssentialApp
//
//  Created by Yury Ramazanov on 25.03.2025.
//
import Foundation
import EssentialFeed
import EssentialFeediOS

final class CommentsViewAdapter: ResourceView {
    private weak var controller: ListViewController?
    
    private typealias ImageDataPresentationAdapter = LoadResourcePresenterAdapter<Data, WeakReference<FeedImageCellController>>
    
    init(controller: ListViewController) {
        self.controller = controller
    }
    
    func display(_ viewModel: ImageCommentsViewModel) {
        controller?.display(viewModel.comments.map { viewModel in
            CellController(id: viewModel, ImageCommentCellController(model: viewModel))
        })
    }
}
