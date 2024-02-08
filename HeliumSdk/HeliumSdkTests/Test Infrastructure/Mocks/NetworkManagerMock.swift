// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

/// Networking is actually mocked by `URLProtocolMock`. The recommended usage is checking the sent request
/// and mocking the response with `URLProtocolMock` instead of checking `XCTAssertMethodCallCount()` against
/// `send()` like in regular unit tests.
///
/// See this "Testing Tips & Tricks" WWDC session for demo:
///   https://developer.apple.com/videos/play/wwdc2018/417/
class NetworkManagerMock: NetworkManagerProtocol {

    private static let urlSessionConfig: URLSessionConfiguration = {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        URLProtocol.registerClass(URLProtocolMock.self)
        return config
    }()
    
    private lazy var networkManager = NetworkManager(urlSessionConfig: Self.urlSessionConfig)

    func send(_ httpRequest: HTTPRequestWithRawDataResponse, maxRetries: Int, retryDelay: TimeInterval, completion: @escaping NetworkManager.RequestCompletionWithRawDataResponse) {
        networkManager.send(httpRequest, maxRetries: maxRetries, retryDelay: retryDelay, completion: completion)
    }
    
    func send<T>(_ httpRequest: T, maxRetries: Int, retryDelay: TimeInterval, completion: @escaping NetworkManager.RequestCompletionWithJSONResponse<T.DecodableResponse>) where T : HTTPRequestWithDecodableResponse {
        networkManager.send(httpRequest, maxRetries: maxRetries, retryDelay: retryDelay, completion: completion)
    }
}

/// Networking is completely mocked.
class CompleteNetworkManagerMock: Mock<CompleteNetworkManagerMock.Method>, NetworkManagerProtocol {

    enum Method {
        case send
    }

    func send(_ httpRequest: HTTPRequestWithRawDataResponse, maxRetries: Int, retryDelay: TimeInterval, completion: @escaping NetworkManager.RequestCompletionWithRawDataResponse) {
        record(.send, parameters: [httpRequest, maxRetries, retryDelay, completion])
    }

    func send<T>(_ httpRequest: T, maxRetries: Int, retryDelay: TimeInterval, completion: @escaping NetworkManager.RequestCompletionWithJSONResponse<T.DecodableResponse>) where T : HTTPRequestWithDecodableResponse {
        record(.send, parameters: [httpRequest, maxRetries, retryDelay, completion])
    }
}
