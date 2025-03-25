//
//  ListViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Yury Ramazanov on 16.01.2025.
//

import XCTest
import Combine
import EssentialFeed
import EssentialFeediOS
import EssentialApp

final class CommentsUIIntegrationTests: FeedUIIntegrationTests {

    func test_comments_hasTitle() {
        let (sut, _) = makeSUT()
        
        sut.simulateAppearance()

        XCTAssertEqual(sut.title, commentsTitle)
    }
    
    func test_loadCommentsActions_requestCommentsFromLoader() {
        let (sut, loader) = makeSUT()
                
        sut.simulateAppearance()
        XCTAssertEqual(loader.loadCallCount, 1, "Expected loading requests when view appears time")
        loader.completeLoading()
        
        sut.simulateAppearance()
        XCTAssertEqual(loader.loadCallCount, 1, "Expected no loading requests when view appeares another time")
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadCallCount, 2, "Expected a loading request when user initiates a reload")
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadCallCount, 3, "Expected another loading request when user initiates a reload")
    }
    
    func test_loadCommentsActions_loadingIndicatorIsVisibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.isShowingLoadingIndicator, true, "Expected loading indicator is visible when view appears")
        
        loader.completeLoading()
        XCTAssertEqual(sut.isShowingLoadingIndicator, false, "Expected loading indicator hides when loading completes successfully")
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.isShowingLoadingIndicator, false, "Expected loading indicator is not visible anymore when view appears next time")
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.isShowingLoadingIndicator, true, "Expected loading indicator visible when user initiates a reload")
       
        loader.completeLoading(at: 1)
        XCTAssertEqual(sut.isShowingLoadingIndicator, false, "Expected loading indicator hides when user initiated reload completes with error")
    }
    
    override func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let image0 = makeImage(description: "a description", location: "a location")
        let image1 = makeImage(description: nil, location: "another location")
        let image2 = makeImage(description: "another description", location: nil)
        let image3 = makeImage(description: nil, location: nil)
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [])

        loader.completeLoading(with: [image0], at: 0)
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedReload()
        loader.completeLoading(with: [image0, image1, image2, image3], at: 1)
        assertThat(sut, isRendering: [image0, image1, image2, image3])
    }
    
    override func test_loadFeedCompletion_rendersSuccessfullyLoadedEmptyFeedAfterNonEmptyFeed() {
        let image0 = makeImage()
        let image1 = makeImage()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeLoading(with: [image0, image1], at: 0)
        assertThat(sut, isRendering: [image0, image1])
        
        sut.simulateUserInitiatedReload()
        loader.completeLoading(with: [], at: 1)
        assertThat(sut, isRendering: [])
    }
    
    override func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let image0 = makeImage()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeLoading(with: [image0], at: 0)
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedReload()
        loader.completeLoadingWithError(at: 1)
        assertThat(sut, isRendering: [image0])
    }
    
    override func test_loadFeedCompletion_rendersErrorMessageOnErrorUntilNextReload() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        
        XCTAssertEqual(sut.errorMessage, nil)
        
        loader.completeLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    override func test_loadFeedCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
       
        sut.simulateAppearance()
        let exp = expectation(description: "Wait for background queue")
        DispatchQueue.global().async {
            loader.completeLoading(at: 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    override func test_tapOnErrorView_hidesErrorMessage() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateErrorViewTap()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (ListViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = CommentsUIComposer.commentsController(feedLoader: loader.loadPublisher)
        trackMemoryLeaks(sut, file: file, line: line)
        trackMemoryLeaks(loader, file: file, line: line)
        return (sut, loader)
    }
   
    private func makeImage(description: String? = nil, location: String? = nil, url: URL = anyURL()) -> FeedImage {
        return FeedImage(id: UUID(), description: description, location: location, url: url)
    }
    
    private class LoaderSpy {
        
        private var requests = [PassthroughSubject<[FeedImage], Error>]()
        var loadCallCount: Int {
            return requests.count
        }
        
        func loadPublisher() -> AnyPublisher<[FeedImage], Error> {
            let publisher = PassthroughSubject<[FeedImage], Error>()
            requests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }
        
        func completeLoading(with feed: [FeedImage] = [], at index: Int = 0) {
            requests[index].send(feed)
        }
        
        func completeLoadingWithError(at index: Int = 0) {
            requests[index].send(completion: .failure(anyNSError()))
        }
    }
}
