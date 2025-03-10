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

final class LoadResourcePresenterAdapter<Resource, View: ResourceView>: FeedViewControllerDelegate {

    private let loader: () -> AnyPublisher<Resource, Error>
    private var cancellable: AnyCancellable?
    var presenter: LoadResourcePresenter<Resource, View>?
    
    
    init(loader: @escaping () -> AnyPublisher<Resource, Error>) {
        self.loader = loader
    }
    
    func didRequestFeedRefresh() {
        presenter?.didStartLoading()
        
        cancellable = loader()
            .dispatchOnMainQueue()
            .sink { [weak self] completion in
                switch completion {
                case .finished: break
                case let .failure(error):
                    self?.presenter?.didFinishLoading(with: error)
                }
            } receiveValue: { [weak self] resource in
                self?.presenter?.didFinishLoading(with: resource)
            }
    }
}
