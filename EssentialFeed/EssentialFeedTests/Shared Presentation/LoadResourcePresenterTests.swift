//
//  LoadResourcePresenterTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 05.02.2025.
//

import XCTest
import EssentialFeed

class LoadResourcePresenterTests: XCTestCase {
    
    func test_init_doesNotSendMessageToView() {
        let (_, view) = makeSUT()
        XCTAssertTrue(view.messages.isEmpty, "Expected no view messages")
    }
    
    func test_didStartLoading_displaysNoErrorMessageAndStartsLoading() {
        let (sut, view) = makeSUT()
        
        sut.didStartLoading()
        
        XCTAssertEqual(view.messages, [
            .display(errorMessage: .none),
            .display(isLoading: true)
        ])
    }
    
    func test_didFinishLoading_displaysResourceAndStopsLoading() {
        let (sut, view) = makeSUT(mapper: { $0 + " view model" })
        let feed = "resource"
        
        sut.didFinishLoading(with: feed)
        
        XCTAssertEqual(view.messages, [
            .display(resourceViewModel: "resource view model"),
            .display(isLoading: false)
        ])
    }
    
    func test_didFinishLoadingFeedWithError_displaysLocalizedErrorMessageAndStopsLoading() {
        let (sut, view) = makeSUT()
        
        sut.didFinishLoadingFeed(with: anyNSError())
        
        XCTAssertEqual(view.messages, [
            .display(errorMessage: localized("FEED_VIEW_CONNECTION_ERROR")),
            .display(isLoading: false)
        ])
    }
    
    //MARK: - Private
    
    private typealias SUT = LoadResourcePresenter<String, ViewSpy>
    
    private func makeSUT(
        mapper: @escaping SUT.Mapper = { _ in "any" },
        file: StaticString = #file,
        line: UInt = #line) -> (sut: SUT, view: ViewSpy) {
            let view = ViewSpy()
            let sut = SUT(resourceView: view, loadingView: view, errorView: view, mapper: mapper)
            trackMemoryLeaks(view, file: file, line: line)
            trackMemoryLeaks(sut, file: file, line: line)
            return (sut, view)
        }
    
    func localized(_ key: String, file: StaticString = #file, line: UInt = #line) -> String {
            let table = "Feed"
        let bundle = Bundle(for: SUT.self)
            let value = bundle.localizedString(forKey: key, value: nil, table: table)
            if value == key {
                XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
            }
            return value
        }
    
    private class ViewSpy: ResourceView, FeedErrorView, FeedLoadingView {
        
        typealias ResourceViewModel = String
        
        enum Message: Hashable {
            case display(resourceViewModel: ResourceViewModel)
            case display(errorMessage: String?)
            case display(isLoading: Bool)
        }
        
        private(set) var messages = Set<Message>()
        
        func display(_ viewModel: String) {
            messages.insert(.display(resourceViewModel: viewModel))
        }
        
        func display(_ viewModel: FeedErrorViewModel) {
            messages.insert(.display(errorMessage: viewModel.message))
        }
        
        func display(_ viewModel: FeedLoadingViewModel) {
            messages.insert(.display(isLoading: viewModel.isLoading))
        }
    }
}
