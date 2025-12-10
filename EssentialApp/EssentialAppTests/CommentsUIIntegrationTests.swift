//
//  ListViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Yury Ramazanov on 16.01.2025.
//

import XCTest
import EssentialFeed
import EssentialFeediOS
import EssentialApp

@MainActor 
final class CommentsUIIntegrationTests: XCTestCase {

    func test_comments_hasTitle() {
        let (sut, _) = makeSUT()
        
        sut.simulateAppearance()

        XCTAssertEqual(sut.title, commentsTitle)
    }
    
    func test_loadCommentsActions_requestCommentsFromLoader() async {
        let (sut, loader) = makeSUT()
                
        sut.simulateAppearance()
        XCTAssertEqual(loader.requestsCount, 1, "Expected loading requests when view appears first time")
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.requestsCount, 1, "Expected no request until previous completes")
        
        await loader.completeLoading(at: 0)
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.requestsCount, 2, "Expected another loading request once user initiates a reload")
        
        await loader.completeLoading(at: 1)
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.requestsCount, 3, "Expected yet another loading request once user initiates another reload")
    }
    
    func test_loadCommentsActions_loadingIndicatorIsVisibleWhileLoadingFeed() async {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.isShowingLoadingIndicator, true, "Expected loading indicator is visible when view appears")
        
        await loader.completeLoading()
        XCTAssertEqual(sut.isShowingLoadingIndicator, false, "Expected loading indicator hides when loading completes successfully")
        
        sut.simulateAppearance()
        XCTAssertEqual(sut.isShowingLoadingIndicator, false, "Expected loading indicator is not visible anymore when view appears next time")
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.isShowingLoadingIndicator, true, "Expected loading indicator visible when user initiates a reload")
       
        await loader.completeLoading(at: 1)
        XCTAssertEqual(sut.isShowingLoadingIndicator, false, "Expected loading indicator hides when user initiated reload completes with error")
    }
    
    func test_loadCommentsCompletion_rendersSuccessfullyLoadedComments() async {
        let comment0 = makeComment(message: "a message", username: "a username")
        let comment1 = makeComment(message: "another message", username: "another username")
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [ImageComment]())

        await loader.completeLoading(with: [comment0], at: 0)
        assertThat(sut, isRendering: [comment0])
        
        sut.simulateUserInitiatedReload()
        await loader.completeLoading(with: [comment0, comment1], at: 1)
        assertThat(sut, isRendering: [comment0, comment1])
    }
    
    func test_loadCommentsCompletion_rendersSuccessfullyLoadedEmptyCommentsAfterNonEmptyComments() async {
        let comment = makeComment()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        await loader.completeLoading(with: [comment], at: 0)
        assertThat(sut, isRendering: [comment])
        
        sut.simulateUserInitiatedReload()
        await loader.completeLoading(with: [], at: 1)
        assertThat(sut, isRendering: [ImageComment]())
    }
    
    func test_loadCommentsCompletion_doesNotAlterCurrentRenderingStateOnError() async {
        let comment = makeComment()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        await loader.completeLoading(with: [comment], at: 0)
        assertThat(sut, isRendering: [comment])
        
        sut.simulateUserInitiatedReload()
        await loader.completeLoadingWithError(at: 1)
        assertThat(sut, isRendering: [comment])
    }
    
    func test_loadCommentsCompletion_rendersErrorMessageOnErrorUntilNextReload() async {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        
        XCTAssertEqual(sut.errorMessage, nil)
        
        await loader.completeLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_tapOnErrorView_hidesErrorMessage() async {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        await loader.completeLoadingWithError(at: 0)
        XCTAssertEqual(sut.errorMessage, loadError)
        
        sut.simulateErrorViewTap()
        XCTAssertEqual(sut.errorMessage, nil)
    }
    
    func test_deinit_cancelsRunningRequest() async throws {
        let loader = LoaderSpy()
        
        addTeardownBlock {
            XCTAssertEqual(loader.cancelledRequestsCount, 1)
        }
        
        var sut: ListViewController? = CommentsUIComposer.commentsController(loader: loader.load)
        sut?.simulateAppearance()
        
        sut = nil
        
        let result = try await loader.result(at: 0)
        XCTAssertEqual(result, .cancelled)
        XCTAssertEqual(loader.cancelledRequestsCount, 1)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (ListViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = CommentsUIComposer.commentsController(loader: loader.load)
        trackMemoryLeaks(sut, file: file, line: line)
        trackMemoryLeaks(loader, file: file, line: line)
        
        addTeardownBlock { [weak loader] in
            try await loader?.cancelPendingRequests()
        }
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
    
    @MainActor
    private class LoaderSpy {
        
        private var loader = AsyncLoaderSpy<Void, [ImageComment]>()
        
        var requestsCount: Int {
            return loader.requests.count
        }
        
        var cancelledRequestsCount: Int {
            return loader.requests.count { $0.result == .cancelled }
        }
        
        func load() async throws -> [ImageComment] {
            try await loader.load(())
        }
        
        func completeLoading(with feed: [ImageComment] = [], at index: Int = 0) async {
            await loader.complete(with: feed, at: index)
        }
        
        func completeLoadingWithError(at index: Int = 0) async {
            await loader.fail(with: anyNSError(), at: index)
        }
        
        func result(at index: Int, timeout: TimeInterval = 1) async throws -> AsyncResult {
            try await loader.result(at: index, timeout: timeout)
        }
        
        func cancelPendingRequests() async throws {
            try await loader.cancelPendingRequests()
        }
    }
}
