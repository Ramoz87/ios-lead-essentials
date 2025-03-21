//
//  FeedSnapshotTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 28.02.2025.
//
import XCTest
import EssentialFeediOS
@testable import EssentialFeed

final class FeedSnapshotTests: XCTestCase {
    
    func test_feedWithContent() {
        let sut = makeSUT()
        
        sut.display(images())
        
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_CONTENT_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_CONTENT_dark")
    }
    
    func test_feedWithFailedImageLoading() {
        let sut = makeSUT()
        
        sut.display(failedImages())
        
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_FAILED_IMAGE_LOADING_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_FAILED_IMAGE_LOADING_dark")
    }
    
    //MARK: - Private
    
    private func makeSUT() -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyBoard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyBoard.instantiateInitialViewController() as! ListViewController
        controller.loadViewIfNeeded()
        return controller
    }
        
    private func images() -> [ImageStub] {
        return [
            ImageStub(
                description: "The East Side Gallery is an open-air gallery in Berlin. It consists of a series of murals painted directly on a 1,316 m long remnant of the Berlin Wall, located near the centre of Berlin, on Mühlenstraße in Friedrichshain-Kreuzberg. The gallery has official status as a Denkmal, or heritage-protected landmark.",
                location: "East Side Gallery\nMemorial in Berlin, Germany",
                image: UIImage.make(withColor: .red)
            ),
            ImageStub(
                description: "Garth Pier is a Grade II listed structure in Bangor, Gwynedd, North Wales.",
                location: "Garth Pier",
                image: UIImage.make(withColor: .green)
            )]
    }
    
    private func failedImages() -> [ImageStub] {
        return [
            ImageStub(
                description: nil,
                location: "Cannon Street, London",
                image: nil
            ),
            ImageStub(
                description: nil,
                location: "Brighton Seafront",
                image: nil
            )
        ]
    }
}
