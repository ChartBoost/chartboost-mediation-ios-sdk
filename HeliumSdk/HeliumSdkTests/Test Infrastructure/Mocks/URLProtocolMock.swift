// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

/// This is for mocking `URLSession` data task handling. See this "Testing Tips & Tricks" WWDC
/// session for demo: https://developer.apple.com/videos/play/wwdc2018/417/
final class URLProtocolMock: URLProtocol {

    typealias URLRequestHandler = (URLRequest) throws -> (response: URLResponse?, data: Data?)

    private static var requestHandlerRegistry: [String: URLRequestHandler] = [:]

    static func registerHTTPRequest(
        _ urlRequest: HTTPRequest,
        withHandler handler: @escaping URLRequestHandler
    ) throws {
        requestHandlerRegistry[try urlRequest.registryKey] = handler
    }

    static func registerRequestHandler(
        httpMethod: String,
        urlString: String,
        withHandler handler: @escaping URLRequestHandler
    ) {
        requestHandlerRegistry[Self.registryKey(httpMethod: httpMethod, urlString: urlString)] = handler
    }

    static func unregisterAllHTTPRequestHandlers() {
        requestHandlerRegistry.removeAll()
    }

    // MARK: - URLProtocol Override

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let client = client else {
            assertionFailure("Client is nil")
            return
        }

        do {
            guard let handler = Self.requestHandlerRegistry[try request.registryKey] else {
                assertionFailure("Handler not found for request: \(request)")
                return
            }

            let (response, data) = try handler(request)
            if let response = response {
                client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = data {
                client.urlProtocol(self, didLoad: data)
            }
            client.urlProtocolDidFinishLoading(self)
        } catch {
            client.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // no-op
    }

    // MARK: - Private Helpers

    fileprivate static func registryKey(httpMethod: String, urlString: String) -> String {
        "\(httpMethod): \(urlString)"
    }
}

private extension URLRequest {
    var registryKey: String {
        get throws {
            URLProtocolMock.registryKey(
                httpMethod: try XCTUnwrap(httpMethod),
                urlString: try XCTUnwrap(url).absoluteString
            )
        }
    }
}

private extension HTTPRequest {
    var registryKey: String {
        get throws {
            try makeURLRequest().registryKey
        }
    }
}
