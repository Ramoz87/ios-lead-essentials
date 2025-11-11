//
//  FeedViewAdapter.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 28.01.2025.
//

import UIKit
import EssentialFeed
import EssentialFeediOS

@MainActor
final class FeedViewAdapter: ResourceView {
    private weak var controller: ListViewController?
    private let imageLoader: (URL) -> FeedImageDataLoader.Publisher
    private let selection: (FeedImage) -> Void
    private let currentFeed: [FeedImage: CellController]
    
    private typealias ImageDataPresentationAdapter = LoadResourcePresenterAdapter<Data, WeakReference<FeedImageCellController>>
    private typealias LoadMorePresentationAdapter = LoadResourcePresenterAdapter<Paginated<FeedImage>, FeedViewAdapter>
    
    init(currentFeed: [FeedImage: CellController] = [:],
         controller: ListViewController,
         imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher,
         selection: @escaping (FeedImage) -> Void) {
        self.controller = controller
        self.imageLoader = imageLoader
        self.selection = selection
        self.currentFeed = currentFeed
    }
    
    func display(_ viewModel: Paginated<FeedImage>) {
        guard let controller else { return }
        
        var currentFeed = self.currentFeed
        let feedSection = viewModel.items.map { model in
            if let controller = currentFeed[model] { return controller }
            
            let adapter = ImageDataPresentationAdapter(loader: { [imageLoader] in imageLoader(model.url) })
            
            let view = FeedImageCellController(
                viewModel: FeedImagePresenter.map(model),
                delegate: adapter,
                selection: { [selection] in selection(model) })
            adapter.presenter = LoadResourcePresenter(
                resourceView: WeakReference(object: view),
                loadingView: WeakReference(object: view),
                errorView: WeakReference(object: view),
                mapper: UIImage.tryMake)
            let controller = CellController(id: model, view)
            currentFeed[model] = controller
            return controller
        }
        
        guard let loadMorePublisher = viewModel.loadMorePublisher else {
            controller.display(feedSection)
            return
        }
        
        let loadMoreAdapter = LoadMorePresentationAdapter(loader: { loadMorePublisher })
        let loadMoreCell = LoadMoreCellController(callback: loadMoreAdapter.loadResource)
        
        loadMoreAdapter.presenter = LoadResourcePresenter(
            resourceView: FeedViewAdapter(
                currentFeed: currentFeed,
                controller: controller,
                imageLoader: imageLoader,
                selection: selection),
            loadingView: WeakReference(object: loadMoreCell),
            errorView: WeakReference(object: loadMoreCell))
        
        let loadMoreSection = [CellController(id: UUID(), loadMoreCell)]
        
        controller.display(feedSection, loadMoreSection)
    }
}

extension UIImage {
    struct InvalidImageData: Error {}

    static func tryMake(data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else {
            throw InvalidImageData()
        }
        return image
    }
}
