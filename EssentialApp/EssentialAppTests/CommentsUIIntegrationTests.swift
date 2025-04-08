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

final class CommentsUIIntegrationTests: XCTestCase {

    func test_comments_hasTitle() {
        let (sut, _) = makeSUT()
        
        sut.simulateAppearance()

        XCTAssertEqual(sut.title, commentsTitle)
    }
    
    func test_loadCommentsActions_requestCommentsFromLoader() {
        let (sut, loader) = makeSUT()
                
        sut.simulateAppearance()
        XCTAssertEqual(loader.loadCallCount, 1, "Expected loading requests when view appears first time")
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadCallCount, 1, "Expected no request until previous completes")
        
        loader.completeLoading(at: 0)
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadCallCount, 2, "Expected another loading request once user initiates a reload")
        
        loader.completeLoading(at: 1)
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadCallCount, 3, "Expected yet another loading request once user initiates another reload")
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
    
    func test_loadCommentsCompletion_rendersSuccessfullyLoadedComments() {
        let comment0 = makeComment(message: "a message", username: "a username")
        let comment1 = makeComment(message: "another message", username: "another username")
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [ImageComment]())

        loader.completeLoading(with: [comment0], at: 0)
        assertThat(sut, isRendering: [comment0])
        
        sut.simulateUserInitiatedReload()
        loader.completeLoading(with: [comment0, comment1], at: 1)
        assertThat(sut, isRendering: [comment0, comment1])
    }
    
    func test_loadCommentsCompletion_rendersSuccessfullyLoadedEmptyCommentsAfterNonEmptyComments() {
        let comment = makeComment()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeLoading(with: [comment], at: 0)
        assertThat(sut, isRendering: [comment])
        
        sut.simulateUserInitiatedReload()
        loader.completeLoading(with: [], at: 1)
        assertThat(sut, isRendering: [ImageComment]())
    }
    
    func test_loadCommentsCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let comment = makeComment()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeLoading(with: [comment], at: 0)
        assertThat(sut, isRendering: [comment])
        
        sut.simulateUserInitiatedReload()
        loader.completeLoadingWithError(at: 1)
        assertThat(sut, isRendering: [comment])
    }
    
    func test_loadCommentsCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
       
        sut.simulateAppearance()
        let exp = expectation(description: "Wait for background queue")
        DispatchQueue.global().async {
            loader.completeLoading(at: 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadCommentsCompletion_rendersErrorMessageOnErrorUntilNextReload() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        
        XCTAssertEqual(sut.errorMessage, nil)
        
        loader.completeLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_tapOnErrorView_hidesErrorMessage() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateErrorViewTap()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_deinit_cancelsRunningRequest() {
        var cancelCallCount = 0
        var sut: ListViewController?
        
        addTeardownBlock {
            XCTAssertEqual(cancelCallCount, 1)
        }
        
        sut = CommentsUIComposer.commentsController(loader: {
            PassthroughSubject<[ImageComment], Error>().handleEvents(receiveCancel: {
                cancelCallCount += 1
            }).eraseToAnyPublisher()
        })
        
        sut?.simulateAppearance()
        XCTAssertEqual(cancelCallCount, 0)
        
        sut = nil
    }
    
    //MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (ListViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = CommentsUIComposer.commentsController(loader: loader.loadPublisher)
        trackMemoryLeaks(sut, file: file, line: line)
        trackMemoryLeaks(loader, file: file, line: line)
        return (sut, loader)
    }
    
    private func assertThat(_ sut: ListViewController, isRendering comments: [ImageComment], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(sut.numberOfRenderedComments(), comments.count, "comments count", file: file, line: line)
        
        let viewModel = ImageCommentsPresenter.map(comments)
        
        viewModel.comments.enumerated().forEach { index, comment in
            XCTAssertEqual(sut.commentMessage(at: index), comment.message, "message at \(index)", file: file, line: line)
            XCTAssertEqual(sut.commentDate(at: index), comment.date, "date at \(index)", file: file, line: line)
            XCTAssertEqual(sut.commentUsername(at: index), comment.username, "username at \(index)", file: file, line: line)
        }
    }
   
    private func makeComment(message: String = "any message", username: String = "any username") -> ImageComment {
        return ImageComment(id: UUID(), message: message, createdAt: Date(), username: username)
    }
    
    private class LoaderSpy {
        
        private var requests = [PassthroughSubject<[ImageComment], Error>]()
        var loadCallCount: Int {
            return requests.count
        }
        
        func loadPublisher() -> AnyPublisher<[ImageComment], Error> {
            let publisher = PassthroughSubject<[ImageComment], Error>()
            requests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }
        
        func completeLoading(with feed: [ImageComment] = [], at index: Int = 0) {
            requests[index].send(feed)
            requests[index].send(completion: .finished)
        }
        
        func completeLoadingWithError(at index: Int = 0) {
            requests[index].send(completion: .failure(anyNSError()))
        }
    }
}
