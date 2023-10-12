// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class NetworkManagerTests: HeliumTestCase {

    private static let mockURLString = "https://mock.com"
    private static let mockURL = URL(unsafeString: "https://mock.com")!
    private static let httpResponseExpectationName = "HTTP response"
    private static let malformedJSON = "<html>Backend might return HTML body while JSON is expected.</html>"
    private static let malformedJSONData = malformedJSON.data(using: .utf8)
    private static let errorMock = NSError(domain: "ErrorMock", code: 777)
    private static let retryDelay = TimeInterval(0.1)

    @Injected(\.environment) private var environment
    @Injected(\.networkManager) private var networkManager

    override func setUp() {
        super.setUp()
        URLProtocolMock.unregisterAllHTTPRequestHandlers()
        mocks.initializationStatusProvider.isInitialized = true
        mocks.taskDispatcher.executesDelayedWorkImmediately = true
    }

    // MARK: - Headers

    func testRequestHeaders() throws {
        let mockIDFV = UUID().uuidString
        mocks.appTrackingInfo.idfv = mockIDFV

        let requests = [
            HTTPRequestWithRawDataResponseMock(urlString: Self.mockURLString),
            // request #2, `HTTPRequestURL.url`, no session ID
            HTTPRequestWithRawDataResponseMock(urlString: Self.mockURLString, shouldIncludeSessionID: false),
            HTTPRequestWithRawDataResponseMock(urlString: Self.mockURLString, shouldIncludeIDFV: false)
        ]
        let headersWithSessionIDAndIDFV = [
            "Accept": "application/json; charset=utf-8",
            "Content-Type": "application/json; charset=utf-8",
            "X-Helium-SessionID": environment.session.sessionID.uuidString,
            "x-mediation-idfv": mockIDFV
        ]
        let headersWithOutSessionID = [
            "Accept": "application/json; charset=utf-8",
            "Content-Type": "application/json; charset=utf-8",
            "x-mediation-idfv": mockIDFV
        ]
        let headersWithOutIDFV = [
            "Accept": "application/json; charset=utf-8",
            "Content-Type": "application/json; charset=utf-8",
            "X-Helium-SessionID": environment.session.sessionID.uuidString
        ]

        for (index, httpRequest) in requests.enumerated() {
            let expectation = XCTestExpectation(description: Self.httpResponseExpectationName)
            let successStatusCode = 200

            try URLProtocolMock.registerHTTPRequest(httpRequest) { request in
                switch index { // test against the headers
                case 0:
                    XCTAssertEqual(try XCTUnwrap(request.allHTTPHeaderFields), headersWithSessionIDAndIDFV)
                case 1:
                    XCTAssertEqual(try XCTUnwrap(request.allHTTPHeaderFields), headersWithOutSessionID)
                case 2:
                    XCTAssertEqual(try XCTUnwrap(request.allHTTPHeaderFields), headersWithOutIDFV)
                default:
                    XCTFail("Unexpected index \(index) and reqeust \(httpRequest)")
                }

                return (
                    response: HTTPURLResponse(
                        url: Self.mockURL,
                        statusCode: successStatusCode,
                        httpVersion: nil,
                        headerFields: nil
                    ),
                    data: nil
                )
            }

            networkManager.send(httpRequest) { result in
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1)
        }
    }

    func testRequestHeadersWhenIDFVIsNil() throws {
        mocks.appTrackingInfo.idfv = nil

        // We want to make sure to set the flag to include the IDFV, however it will not actually
        // be included because the IDFV is nil.
        let httpRequest = HTTPRequestWithRawDataResponseMock(urlString: Self.mockURLString, shouldIncludeIDFV: true)
        let headersWithOutIDFV = [
            "Accept": "application/json; charset=utf-8",
            "Content-Type": "application/json; charset=utf-8",
            "X-Helium-SessionID": environment.session.sessionID.uuidString
        ]

        let expectation = XCTestExpectation(description: Self.httpResponseExpectationName)
        let successStatusCode = 200

        try URLProtocolMock.registerHTTPRequest(httpRequest) { request in
            XCTAssertEqual(try XCTUnwrap(request.allHTTPHeaderFields), headersWithOutIDFV)

            return (
                response: HTTPURLResponse(
                    url: Self.mockURL,
                    statusCode: successStatusCode,
                    httpVersion: nil,
                    headerFields: nil
                ),
                data: nil
            )
        }

        networkManager.send(httpRequest) { result in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    // MARK: - Failure

    func testSDKNotInitializedError() throws {
        struct HTTPGETRequestMock: HTTPRequestWithRawDataResponse {
            let url = URL(unsafeString: "https://www.mock.com\(NetworkManagerTests.urlPathFromTestName())")!
            let method = HTTP.Method.get
        }

        let httpRequest = HTTPGETRequestMock()
        let expectation = XCTestExpectation(description: Self.httpResponseExpectationName)
        mocks.initializationStatusProvider.isInitialized = false

        networkManager.send(httpRequest) { result in
            guard case .failure(.sdkNotInitialized(_)) = result else {
                XCTFail("Unexpected result: \(result)")
                return
            }

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testURLRequestCreationError() throws {
        struct CorruptedHTTPRequestMock: HTTPRequestWithEncodableBody, HTTPRequestWithRawDataResponse {
            struct EmptyEncodableBody: Encodable {}

            let url = URL(unsafeString: "https://www.mock.com\(NetworkManagerTests.urlPathFromTestName())")!
            let method = HTTP.Method.post
            let body = EmptyEncodableBody()
            let requestKeyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys
            var bodyData: Data? {
                get throws {
                    throw NetworkManagerTests.errorMock // failure with corrupted body data
                }
            }
        }

        let httpRequest = CorruptedHTTPRequestMock()
        let expectation = XCTestExpectation(description: Self.httpResponseExpectationName)

        networkManager.send(httpRequest) { result in
            guard case let .failure(.urlRequestCreationError(_, originalError)) = result else {
                XCTFail("Unexpected result: \(result)")
                return
            }

            let originalNSError = originalError as NSError
            XCTAssertEqual(originalNSError.domain, Self.errorMock.domain)
            XCTAssertEqual(originalNSError.code, Self.errorMock.code)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testDataTaskError() throws {
        let httpRequest = HTTPRequestWithRawDataResponseMock(endpoint: .load, urlPath: Self.urlPathFromTestName())
        let expectation = XCTestExpectation(description: Self.httpResponseExpectationName)

        try URLProtocolMock.registerHTTPRequest(httpRequest) { request in
            throw Self.errorMock // failure with an error in the data task completion
        }

        networkManager.send(httpRequest) { result in
            guard case let .failure(.dataTaskError(request, response, originalError)) = result else {
                XCTFail("Unexpected result: \(result)")
                return
            }

            XCTAssertEqual(try! request.url, httpRequest.url)
            XCTAssertNil(response)

            let originalNSError = originalError as NSError
            XCTAssertEqual(originalNSError.domain, Self.errorMock.domain)
            XCTAssertEqual(originalNSError.code, Self.errorMock.code)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testNotHTTPURLResponseError() throws {
        let httpRequest = HTTPRequestWithRawDataResponseMock(endpoint: .load, urlPath: Self.urlPathFromTestName())
        let expectation = XCTestExpectation(description: Self.httpResponseExpectationName)

        try URLProtocolMock.registerHTTPRequest(httpRequest) { request in
            (response: URLResponse(), data: nil)  // failure with `URLResponse` instead of the expected `HTTPURLResponse`
        }

        networkManager.send(httpRequest) { result in
            guard case let .failure(.notHTTPURLResponseError(request)) = result else {
                XCTFail("Unexpected result: \(result)")
                return
            }

            XCTAssertEqual(try! request.url, httpRequest.url)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testResponseStatusCodeOutOfRangeError() throws {
        let httpRequest = HTTPRequestWithRawDataResponseMock(endpoint: .load, urlPath: Self.urlPathFromTestName())

        for badStatusCode in [199, 400] { // failure with a status code out of the [200, 400) range
            let expectation = XCTestExpectation(description: Self.httpResponseExpectationName)

            try URLProtocolMock.registerHTTPRequest(httpRequest) { request in
                (
                    response: HTTPURLResponse(
                        url: Self.mockURL,
                        statusCode: badStatusCode,
                        httpVersion: nil,
                        headerFields: nil
                    ),
                    data: Data()
                )
            }

            networkManager.send(httpRequest) { result in
                guard case let .failure(.responseStatusCodeOutOfRangeError(request, response, 0)) = result else {
                    XCTFail("Unexpected result: \(result)")
                    return
                }

                XCTAssertEqual(try! request.url, httpRequest.url)
                XCTAssertEqual(response.statusCode, badStatusCode)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1)
        }
    }

    func testResponseWithEmptyDataError() throws {
        let httpRequest = HTTPRequestWithDecodableResponseMock(endpoint: .load, urlPath: Self.urlPathFromTestName())
        let expectation = XCTestExpectation(description: Self.httpResponseExpectationName)
        let successStatusCode = 200

        try URLProtocolMock.registerHTTPRequest(httpRequest) { request in
            (
                response: HTTPURLResponse(
                    url: Self.mockURL,
                    statusCode: successStatusCode,
                    httpVersion: nil,
                    headerFields: nil
                ),
                data: nil // failure with empty data when status code 200 expects data
            )
        }

        networkManager.send(httpRequest) { result in
            guard case let .failure(.responseWithEmptyDataError(request, response)) = result else {
                XCTFail("Unexpected result: \(result)")
                return
            }

            XCTAssertEqual(try! request.url, httpRequest.url)
            XCTAssertEqual(response.statusCode, successStatusCode)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testJSONDecodeError() throws {
        let httpRequest = HTTPRequestWithDecodableResponseMock(endpoint: .load, urlPath: Self.urlPathFromTestName())
        let expectation = XCTestExpectation(description: Self.httpResponseExpectationName)
        let successStatusCode = 200

        try URLProtocolMock.registerHTTPRequest(httpRequest) { request in
            (
                response: HTTPURLResponse(
                    url: Self.mockURL,
                    statusCode: successStatusCode,
                    httpVersion: nil,
                    headerFields: nil
                ),
                data: Self.malformedJSONData // failure with malformed JSON
            )
        }

        networkManager.send(httpRequest) { result in
            guard case let .failure(.jsonDecodeError(request, response, data, error)) = result else {
                XCTFail("Unexpected result: \(result)")
                return
            }

            XCTAssertEqual(try! request.url, httpRequest.url)
            XCTAssertEqual(response.statusCode, successStatusCode)
            XCTAssertEqual(data, Self.malformedJSONData)
            XCTAssert(error is DecodingError)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    // MARK: - Success

    func testSuccessfulResponseWithEmptyData() throws {
        let httpRequest = HTTPRequestWithDecodableResponseMock(endpoint: .load, urlPath: Self.urlPathFromTestName())
        let expectation = XCTestExpectation(description: Self.httpResponseExpectationName)
        let successStatusCode = 204 // HTTP 204 = No Content

        try URLProtocolMock.registerHTTPRequest(httpRequest) { request in
            (
                response: HTTPURLResponse(
                    url: Self.mockURL,
                    statusCode: successStatusCode,
                    httpVersion: nil,
                    headerFields: nil
                ),
                data: nil // empty `Data`
            )
        }

        networkManager.send(httpRequest) { result in
            guard case let .success(response) = result else {
                XCTFail("Unexpected result: \(result)")
                return
            }

            XCTAssertEqual(response.httpURLResponse.statusCode, successStatusCode)
            XCTAssertNil(response.responseData)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testSuccessfulResponseWithDecodableData() throws {
        let httpRequest = HTTPRequestWithDecodableResponseMock(endpoint: .load, urlPath: Self.urlPathFromTestName())
        let expectation = XCTestExpectation(description: Self.httpResponseExpectationName)
        let successStatusCode = 200

        try URLProtocolMock.registerHTTPRequest(httpRequest) { request in
            (
                response: HTTPURLResponse(
                    url: Self.mockURL,
                    statusCode: successStatusCode,
                    httpVersion: nil,
                    headerFields: nil
                ),
                data: "{ \"string\": \"some value\", \"integer\": 123 }".data(using: .utf8)
            )
        }

        networkManager.send(httpRequest) { result in
            guard
                case let .success(response) = result,
                let responseData = response.responseData
            else {
                XCTFail("Unexpected result: \(result)")
                return
            }

            XCTAssertEqual(response.httpURLResponse.statusCode, successStatusCode)
            XCTAssertFalse(responseData.rawData.isEmpty)
            XCTAssertEqual(responseData.decodedData.string, "some value")
            XCTAssertNil(responseData.decodedData.optionalString)
            XCTAssertEqual(responseData.decodedData.integer, 123)
            XCTAssertNil(responseData.decodedData.optionalInteger)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    // MARK: - Retry Sending Request

    func testRetrySendingRequestWithFailureResult() throws {
        let httpRequest = HTTPRequestWithRawDataResponseMock(endpoint: .load, urlPath: Self.urlPathFromTestName())
        let expectation = XCTestExpectation(description: Self.httpResponseExpectationName)
        let retryStatusCode = 404
        let totalNumberOfRequests = 3
        var requestCount = 0

        try URLProtocolMock.registerHTTPRequest(httpRequest) { request in
            requestCount += 1
            return (
                response: HTTPURLResponse(
                    url: Self.mockURL,
                    statusCode: retryStatusCode, // always fails
                    httpVersion: nil,
                    headerFields: nil
                ),
                data: nil
            )
        }

        networkManager.send(
            httpRequest,
            maxRetries: totalNumberOfRequests - 1, // -1 because [ total = initial request + retry requests ]
            retryDelay: Self.retryDelay
        ) { result in
            guard requestCount == totalNumberOfRequests, case let .failure(.responseStatusCodeOutOfRangeError(_, response, 0)) = result else {
                XCTFail("Unexpected result: \(result)")
                return
            }

            XCTAssertEqual(response.statusCode, retryStatusCode)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testRetrySendingRequestWithSuccessResult() throws {
        let httpRequest = HTTPRequestWithRawDataResponseMock(endpoint: .load, urlPath: Self.urlPathFromTestName())
        let expectation = XCTestExpectation(description: Self.httpResponseExpectationName)
        let successStatusCode = 200
        let retryStatusCode = 404
        let totalNumberOfRequests = 3
        var requestCount = 0

        try URLProtocolMock.registerHTTPRequest(httpRequest) { request in
            requestCount += 1
            return (
                response: HTTPURLResponse(
                    url: Self.mockURL,
                    statusCode: requestCount == totalNumberOfRequests ? successStatusCode : retryStatusCode, // keep failing until the last attempt
                    httpVersion: nil,
                    headerFields: nil
                ),
                data: nil
            )
        }

        networkManager.send(
            httpRequest,
            maxRetries: totalNumberOfRequests - 1, // -1 because [ total = initial request + retry requests ]
            retryDelay: Self.retryDelay
        ) { result in
            guard requestCount == totalNumberOfRequests, case let .success(response) = result else {
                XCTFail("Unexpected result: \(result)")
                return
            }

            XCTAssertEqual(response.httpURLResponse.statusCode, successStatusCode)
            XCTAssert(response.rawData!.isEmpty)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout:  1)
    }
}
