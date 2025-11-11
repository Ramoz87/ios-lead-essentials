//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Yury Ramazanov on 13.12.2024.
//

import XCTest
import EssentialFeed

@MainActor
final class URLSessionHTTPClientTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        URLProtocolStub.removeStub()
    }
    
    func test_getFromURL_performRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            exp.fulfill()
        }
    
        makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() async {
        assertNotNil(await resultErrorFor((data: nil, response: nil, error: nil)))
        assertNotNil(await resultErrorFor((data: nil, response: nonHTTPURLResponse(), error: nil)))
        assertNotNil(await resultErrorFor((data: anyData(), response: nil, error: nil)))
        assertNotNil(await resultErrorFor((data: anyData(), response: nil, error: anyNSError())))
        assertNotNil(await resultErrorFor((data: nil, response: nonHTTPURLResponse(), error: anyNSError())))
        assertNotNil(await resultErrorFor((data: nil, response: anyHTTPURLResponse(), error: anyNSError())))
        assertNotNil(await resultErrorFor((data: anyData(), response: nonHTTPURLResponse(), error: anyNSError())))
        assertNotNil(await resultErrorFor((data: anyData(), response: anyHTTPURLResponse(), error: anyNSError())))
        assertNotNil(await resultErrorFor((data: anyData(), response: nonHTTPURLResponse(), error: nil)))
    }
    
    func test_getFromUrl_failedWithError() async {
        let error = anyNSError()
        
        let result = await resultErrorFor((data: nil, response: nil, error: error)) as? NSError
                
        XCTAssertEqual(result?.code, error.code)
        XCTAssertEqual(result?.domain, error.domain)
    }
    
    func test_getFromUrl_successWithDataAndResponse() async  {
        let data = anyData()
        let response = anyHTTPURLResponse()
         
        let result = await resultValuesFor((data: data, response: response, error: nil))
        
        XCTAssertEqual(result?.data, data)
        XCTAssertEqual(result?.response.url, response.url)
        XCTAssertEqual(result?.response.statusCode, response.statusCode)
    }
    
    func test_getFromUrl_successWithEmptyDataAndResponse() async {
        let response = anyHTTPURLResponse()
         
        let result = await resultValuesFor((data: nil, response: response, error: nil))
        
        XCTAssertEqual(result?.data, Data())
        XCTAssertEqual(result?.response.url, response.url)
        XCTAssertEqual(result?.response.statusCode, response.statusCode)
    }
    
    func test_cancelGetFromURLTask_cancelsURLRequest() async {
        var task: HTTPClientTask?
        URLProtocolStub.onStartLoading { task?.cancel() }
        let receivedError = await resultErrorFor(taskHandler: { task = $0 }) as NSError?
        XCTAssertEqual(receivedError?.code, URLError.cancelled.rawValue)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultValuesFor(_ values: (data: Data?, response: URLResponse?, error: Error?)? = nil, taskHandler: (HTTPClientTask) -> Void = { _ in }, file: StaticString = #file, line: UInt = #line) async -> (data: Data, response: HTTPURLResponse)? {
        let result = await resultFor(values,taskHandler: taskHandler, file: file, line: line)
        
        switch result {
        case let .success((data, response)):
            return (data, response)
        default:
            XCTFail("Expected success, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultErrorFor(_ values: (data: Data?, response: URLResponse?, error: Error?)? = nil, taskHandler: (HTTPClientTask) -> Void = { _ in }, file: StaticString = #file, line: UInt = #line) async -> Error? {
        let result = await resultFor(values, taskHandler: taskHandler, file: file, line: line)
        
        switch result {
        case let .failure(error):
            return error
        default:
            XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultFor(_ values: (data: Data?, response: URLResponse?, error: Error?)?, taskHandler: (HTTPClientTask) -> Void = { _ in },  file: StaticString = #file, line: UInt = #line) async -> HTTPClient.Result {
        
        values.map { URLProtocolStub.stub(data: $0, response: $1, error: $2) }
        
        let sut = makeSUT(file: file, line: line)
        
        return await withCheckedContinuation { continuation in
            taskHandler(sut.get(from: anyURL()) { result in
                continuation.resume(returning: result)
            })
        }
    }
            
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func assertNotNil(_ value: Any?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        XCTAssertNotNil(value, message(), file: file, line: line)
    }
}
