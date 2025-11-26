//
//  FeedPresenterAdapter.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 28.01.2025.
//

import Foundation
import Combine
import EssentialFeed
import EssentialFeediOS

@MainActor
final class AsyncLoadResourcePresenterAdapter<Resource, View: ResourceView> {

    private let loader: () async throws -> Resource
    private var cancellable: Task<Void, Never>?
    private var isLoading = false
    
    var presenter: LoadResourcePresenter<Resource, View>?
    
    init(loader: @escaping () async throws -> Resource) {
        self.loader = loader
    }
    
    deinit {
        cancellable?.cancel()
    }
    
    func loadResource() {
        guard !isLoading else { return }
        
        presenter?.didStartLoading()
        isLoading = true
        
        cancellable = Task.immediate { @MainActor [weak self] in
            defer { self?.isLoading = false }
            
            do {
                if let resource = try await self?.loader() {
                    if Task.isCancelled { return }
                    self?.presenter?.didFinishLoading(with: resource)
                }
            } catch {
                if Task.isCancelled { return }
                self?.presenter?.didFinishLoading(with: error)
            }
        }
    }
}

extension AsyncLoadResourcePresenterAdapter: FeedImageCellControllerDelegate {
    func didRequestImage() {
        loadResource()
    }
    
    func didCancelImageRequest() {
        cancellable?.cancel()
        cancellable = nil
        isLoading = false
    }
}


@MainActor
final class LoadResourcePresenterAdapter<Resource, View: ResourceView> {

    private let loader: () -> AnyPublisher<Resource, Error>
    private var cancellable: AnyCancellable?
    private var isLoading = false
    
    var presenter: LoadResourcePresenter<Resource, View>?
    
    init(loader: @escaping () -> AnyPublisher<Resource, Error>) {
        self.loader = loader
    }
    
    func loadResource() {
        guard !isLoading else { return }
        
        presenter?.didStartLoading()
        isLoading = true
        
        cancellable = loader()
            .dispatchOnMainQueue()
            .handleEvents(receiveCancel: { [weak self] in
                self?.isLoading = false
            })
            .sink { [weak self] completion in
                switch completion {
                case .finished: break
                case let .failure(error):
                    self?.presenter?.didFinishLoading(with: error)
                }
                self?.isLoading = false
            } receiveValue: { [weak self] resource in
                self?.presenter?.didFinishLoading(with: resource)
            }
    }
}

extension LoadResourcePresenterAdapter: FeedImageCellControllerDelegate {
    func didRequestImage() {
        loadResource()
    }
    
    func didCancelImageRequest() {
        cancellable?.cancel()
        cancellable = nil
    }
}
