//
//  RemoteLoaderTests.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 05.03.2025.
//
import XCTest
import EssentialFeed

final class RemoteLoaderTests: XCTestCase {

    func test_init_shouldNotRequestDataFromUrl() {
        let (_, client) = makeSut()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_shouldRequestDataFromUrl() {
        let url = URL(string: "https://remote-feed-test-url.com")!
        let (sut, client) = makeSut(url: url)
        sut.load {_ in }
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_twice_shouldRequestDataFromUrlTwice() {
        let url = URL(string: "https://remote-feed-test-url.com")!
        let (sut, client) = makeSut(url: url)
        sut.load {_ in }
        sut.load {_ in }
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_withConnectionError_shouldDeliverConnectionError() {
        let (sut, client) = makeSut()
        expect(sut, completeWith: failure(.connection)) {
            let error = NSError(domain: "Test", code: 0)
            client.complete(with: error)
        }
    }
    
    func test_load_deliversErrorOnMapperError() {
        let (sut, client) = makeSut(mapper: { _, _ in
            throw anyNSError()
        })
        
        expect(sut, completeWith: failure(.invalidResponse), when: {
            client.complete(with: 200, data: anyData())
        })
    }
    
    func test_load_deliversMappedResource() {
        let resource = "a resource"
        let (sut, client) = makeSut(mapper: { data, _ in
            String(data: data, encoding: .utf8)!
        })
        expect(sut, completeWith: .success(resource), when: {
            client.complete(with: 200, data: Data(resource.utf8))
        })
    }
    
    func test_load_deallocatedBeforeCompletion_shouldNotDeliverResult() {
        let client = HTTPClientSpy()
        let url = URL(string: "https://remote-feed-test-url.com")!
        var sut: RemoteLoader<String>? = RemoteLoader<String>(client: client, url: url, mapper: { _, _ in "any" })
       
        var capturedResults = [RemoteLoader<String>.Result]()
        sut?.load { capturedResults.append($0) }
        sut = nil
        client.complete(with: 200, data: makeJSON([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    //MARK: - Helpers
    
    private func makeSut(
        url: URL = URL(string: "https://a-url.com")!,
        mapper: @escaping RemoteLoader<String>.Mapper = { _, _ in "any" },
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: RemoteLoader<String>, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteLoader<String>(client: client, url: url, mapper: mapper)
        trackMemoryLeaks(client, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
        
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, url: URL) -> FeedImage {
        return FeedImage(id: id, description: description, location: location, url: url)
    }
    
    private func makeJSON(_ items: [FeedImage]) -> Data {
        let jsonItems = items.map { item in
            [
                "id": item.id.uuidString,
                "description": item.description,
                "location": item.location,
                "image": item.url.absoluteString
            ].compactMapValues { $0 }
        }
        let json = ["items": jsonItems]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(_ sut: RemoteLoader<String>, completeWith expectedResult: RemoteLoader<String>.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        let exp = expectation(description: "Wait for RemoteFeedLoader load completion")
        sut.load { recievedResult in
         
            switch(recievedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let (.failure(receivedError as RemoteLoader<String>.Error), .failure(expectedError as RemoteLoader<String>.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult) got \(recievedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1)
    }
    
    private func failure(_ error: RemoteLoader<String>.Error) -> RemoteLoader<String>.Result {
        return .failure(error)
    }
}
