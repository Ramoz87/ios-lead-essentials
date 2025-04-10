//
//  LoaderSpy.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 21.01.2025.
//

import Foundation
import Combine
import EssentialFeed
import EssentialFeediOS

class LoaderSpy {
    
    private var feedRequests = [PassthroughSubject<Paginated<FeedImage>, Error>]()
    private var loadMoreRequests = [PassthroughSubject<Paginated<FeedImage>, Error>]()
    
    var loadCallCount: Int {
        feedRequests.count
    }
    
    func loadPublisher() -> Paginated<FeedImage>.Publisher {
        let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
        feedRequests.append(publisher)
        return publisher.eraseToAnyPublisher()
    }
    
    func completeFeedLoading(with feed: [FeedImage] = [], at index: Int = 0) {
        feedRequests[index].send(Paginated(items: feed, loadMorePublisher: loadMorePublisher()))
        feedRequests[index].send(completion: .finished)
    }
    
    func completeFeedLoadingWithError(at index: Int = 0) {
        feedRequests[index].send(completion: .failure(anyNSError()))
    }
    
    //MARK: - FeedLoadMore
    
    var loadMoreCallCount: Int {
        loadMoreRequests.count
    }
    
    func loadMorePublisher() -> () -> Paginated<FeedImage>.Publisher {
        return { [weak self] in
            let publisher = PassthroughSubject<Paginated<FeedImage>, Error>()
            self?.loadMoreRequests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }
    }
    
    func completeLoadMore(with feed: [FeedImage] = [], lastPage: Bool = false, at index: Int = 0) {
        loadMoreRequests[index].send(Paginated(items: feed, loadMorePublisher: lastPage ? nil : loadMorePublisher()))
    }
    
    func completeLoadMoreWithError(at index: Int = 0) {
        loadMoreRequests[index].send(completion: .failure(anyNSError()))
    }
    
    //MARK: - FeedImageDataLoader
    
    private var imageRequests = [(url: URL, publisher: PassthroughSubject<Data, Error>)]()
    private(set) var cancelledImageURLs = [URL]()
    var loadedImageURLs: [URL] {
        return imageRequests.map { $0.url }
    }
    
    func loadImageDataPublisher(from url: URL) -> AnyPublisher<Data, Error> {
        let publisher = PassthroughSubject<Data, Error>()
        imageRequests.append((url, publisher))
        return publisher.handleEvents(receiveCancel: { [weak self] in
            self?.cancelledImageURLs.append(url)
        }).eraseToAnyPublisher()
    }
    
    func completeImageLoading(with imageData: Data = Data(), at index: Int = 0) {
        imageRequests[index].publisher.send(imageData)
        imageRequests[index].publisher.send(completion: .finished)
    }
    
    func completeImageLoadingWithError(at index: Int = 0) {
        imageRequests[index].publisher.send(completion: .failure(anyNSError()))
    }
}
