//
//  FeedUIComposer.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//

import UIKit
import Combine
import EssentialFeed
import EssentialFeediOS

@MainActor
public final class CommentsUIComposer {
    private init() {}
    
    private typealias CommentsPresentationAdapter = LoadResourcePresenterAdapter<[ImageComment], CommentsViewAdapter>
    
    public static func commentsController(loader: @escaping () -> AnyPublisher<[ImageComment], Error>) -> ListViewController {
        let presenterAdapter = CommentsPresentationAdapter(loader: loader)
        let controller = makeViewController(title: ImageCommentsPresenter.title)
        controller.onRefresh = presenterAdapter.loadResource
        presenterAdapter.presenter = LoadResourcePresenter (
            resourceView: CommentsViewAdapter(controller: controller),
            loadingView: WeakReference(object: controller),
            errorView: WeakReference(object: controller),
            mapper: { ImageCommentsPresenter.map($0) } )
        
        return controller
    }
    
    private static func makeViewController(title: String) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyBoard = UIStoryboard(name: "ImageComments", bundle: bundle)
        let ctrl = storyBoard.instantiateInitialViewController() as! ListViewController
        ctrl.title = title
        return ctrl
    }
}
