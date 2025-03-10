//
//  LoadResourcePresenter.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 05.02.2025.
//

import Foundation

public protocol ResourceView {
    associatedtype ResourceViewModel
    func display(_ viewModel: ResourceViewModel)
}

public protocol ResourceLoadingView {
    func display(_ viewModel: ResourceLoadingViewModel)
}

public protocol ResourceErrorView {
    func display(_ viewModel: ResourceErrorViewModel)
}

public final class LoadResourcePresenter<Resource, View: ResourceView> {
    
    public typealias Mapper = (Resource) -> View.ResourceViewModel
    
    let resourceView: View
    let errorView: ResourceErrorView
    let loadingView: ResourceLoadingView
    let mapper: Mapper
    
    public init(resourceView: View, loadingView: ResourceLoadingView, errorView: ResourceErrorView, mapper: @escaping Mapper) {
        self.resourceView = resourceView
        self.loadingView = loadingView
        self.errorView = errorView
        self.mapper = mapper
    }
    
    public static var loadError: String {
        return NSLocalizedString("GENERIC_CONNECTION_ERROR",
                                 tableName: "Shared",
                                 bundle: Bundle(for: Self.self),
                                 comment: "Error message displayed when we can't load the image feed from the server")
    }
    
    public func didStartLoading() {
        errorView.display(.init(message: .none))
        loadingView.display(.init(isLoading: true))
    }
    
    public func didFinishLoading(with resource: Resource) {
        resourceView.display(mapper(resource))
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
    }
    
    public func didFinishLoading(with error: Error) {
        errorView.display(ResourceErrorViewModel(message: Self.loadError))
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
    }
}
