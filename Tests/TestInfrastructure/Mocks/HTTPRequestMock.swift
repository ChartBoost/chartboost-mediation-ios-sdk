// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class HTTPRequestMock: HTTPRequest {
    let url: URL
    let method: HTTP.Method
    let customHeaders: HTTP.Headers
    let bodyData: Data?
    let shouldIncludeMediationHeaders: Bool

    convenience init(
        endpoint: BackendAPI.Endpoint,
        urlPath: String,
        method: HTTP.Method = .post,
        customHeaders: HTTP.Headers = [:],
        bodyData: Data? = nil,
        shouldIncludeMediationHeaders: Bool = true
    ) {
        self.init(
            urlString: "\(endpoint.scheme)://\(endpoint.host)\(urlPath)",
            method: method,
            customHeaders: customHeaders,
            bodyData: bodyData,
            shouldIncludeMediationHeaders: shouldIncludeMediationHeaders
        )
    }

    init(
        urlString: String,
        method: HTTP.Method = .post,
        customHeaders: HTTP.Headers = [:],
        bodyData: Data? = nil,
        shouldIncludeMediationHeaders: Bool = true
    ) {
        self.url = URL(unsafeString: urlString)!
        self.method = method
        self.customHeaders = customHeaders
        self.bodyData = bodyData
        self.shouldIncludeMediationHeaders = shouldIncludeMediationHeaders
    }
}

final class HTTPRequestWithDecodableResponseMock: HTTPRequestMock, HTTPRequestWithDecodableResponse {
    typealias DecodableResponse = ResponseMock

    struct ResponseMock: Decodable {
        let string: String
        let optionalString: String?
        let integer: Int
        let optionalInteger: Int?
    }

    let responseKeyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase
}

final class HTTPRequestWithRawDataResponseMock: HTTPRequestMock, HTTPRequestWithRawDataResponse {
    // Intentionally empty so that `HTTPRequestWithRawDataResponseMock` and `HTTPRequest` are 1:1.
}
