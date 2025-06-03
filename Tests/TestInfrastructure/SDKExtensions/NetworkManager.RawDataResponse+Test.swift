// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension NetworkManager.RawDataResponse {
    /// A convenience factory method to obtain an instance with minimum boilerplate code.
    static func test(
        url: URL = .init(unsafeString: "https://google.com")!,
        statusCode: Int = 200,
        sdkInitHash: String? = nil,
        rawData: Data? = nil
    ) -> NetworkManager.RawDataResponse {
        var headers: HTTP.Headers = [:]
        headers["x-mediation-sdk-init-hash"] = sdkInitHash
        return NetworkManager.RawDataResponse(
            httpURLResponse: HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: headers
            )!,
            rawData: rawData
        )
    }
}
