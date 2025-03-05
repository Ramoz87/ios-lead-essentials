//
//  LoadFeedFromRemoteUseCaseTests 2.swift
//  EssentialFeed
//
//  Created by Yury Ramazanov on 05.03.2025.
//
import XCTest
import EssentialFeed

final class LoadImageCommentsFromRemoteUseCaseTests: XCTestCase {

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
    
    func test_load_withNon2xxHTTPCode_shouldDeliverInvalidResponseError() {
        let (sut, client) = makeSut()
        let codes = [199, 300, 400, 500]
        codes.enumerated().forEach { index, code in
            expect(sut, completeWith: failure(.invalidResponse)) {
                client.complete(with: code, data: Data(), at: index)
            }
        }
    }
    
    func test_load_with2xxHTTPCodeAndInvalidJSON_shouldDeliverInvalidResponseError() {
        let (sut, client) = makeSut()
        let codes = [200, 201, 250, 280, 299]
        
        codes.enumerated().forEach { index, code in
            expect(sut, completeWith: failure(.invalidResponse), when: {
                let invalidJSON = Data("invalid json".utf8)
                client.complete(with: code, data: invalidJSON, at: index)
            })
        }
    }
    
    func test_load_with2xxHTTPCodeAndEmptyJSON_shouldDeliverEmptyResult() {
        let (sut, client) = makeSut()
        let codes = [200, 201, 250, 280, 299]
        
        codes.enumerated().forEach { index, code in
            expect(sut, completeWith: .success([])) {
                client.complete(with: code, data: makeJSON([]), at: index)
            }
        }
    }
    
    func test_load_with2xxHTTPCodeAndNotEmptyJSON_shouldDeliverResult() {
        let (sut, client) = makeSut()
        let codes = [200, 201, 250, 280, 299]
        let item1 = makeItem(id: UUID(),
                             message: "a message",
                             createdAt: (Date(timeIntervalSince1970: 1598627222), "2020-08-28T15:07:02+00:00"),
                             username: "a username")
        let item2 = makeItem(id: UUID(),
                             message: "another message",
                             createdAt: (Date(timeIntervalSince1970: 1577881882), "2020-01-01T12:31:22+00:00"),
                             username: "another username")
        let items = [item1.model, item2.model]
        let json = makeJSON([item1.json, item2.json])
        
        codes.enumerated().forEach { index, code in
            expect(sut, completeWith: .success(items)) {
                client.complete(with: code, data:json, at: index)
            }
        }
    }
    
    func test_load_deallocatedBeforeCompletion_shouldNotDeliverResult() {
        let client = HTTPClientSpy()
        let url = URL(string: "https://remote-feed-test-url.com")!
        var sut: RemoteImageCommentsLoader? = RemoteImageCommentsLoader(client: client, url: url)
    
        var capturedResults = [RemoteImageCommentsLoader.Result]()
        sut?.load { capturedResults.append($0) }
        sut = nil
        client.complete(with: 200, data: makeJSON([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    //MARK: - Helpers
    
    private func makeSut(url: URL = URL(string: "https://remote-feed-url.com")!, file: StaticString = #file, line: UInt = #line) -> (RemoteImageCommentsLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteImageCommentsLoader(client: client, url: url)
        trackMemoryLeaks(client, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
        
    private func makeItem(id: UUID, message: String, createdAt: (date: Date, iso8601String: String), username: String) -> (model: ImageComment, json: [String: Any]) {
        let item = ImageComment(id: id, message: message, createdAt: createdAt.date, username: username)
        let json: [String: Any] = [
            "id": id.uuidString,
            "message": message,
            "created_at": createdAt.iso8601String,
            "author": [
                "username": username
            ]
        ]
        return (item, json)
    }
    
    private func makeJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(_ sut: RemoteImageCommentsLoader, completeWith expectedResult: RemoteImageCommentsLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        let exp = expectation(description: "Wait for RemoteImageCommentsLoader load completion")
        sut.load { recievedResult in
         
            switch(recievedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let (.failure(receivedError as RemoteImageCommentsLoader.Error), .failure(expectedError as RemoteImageCommentsLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult) got \(recievedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1)
    }
    
    private func failure(_ error: RemoteImageCommentsLoader.Error) -> RemoteImageCommentsLoader.Result {
        return .failure(error)
    }
}
