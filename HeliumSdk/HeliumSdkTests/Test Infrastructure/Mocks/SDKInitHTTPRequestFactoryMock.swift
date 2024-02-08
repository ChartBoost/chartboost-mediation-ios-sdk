// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class SDKInitHTTPRequestFactoryMock: Mock<SDKInitHTTPRequestFactoryMock.Method>, SDKInitHTTPRequestFactory {

    enum Method {
        case makeRequest
    }

    /// The result to pass to makeRequest() completion handlers.
    var autoCompletionResult: Result<SDKInitHTTPRequest, ChartboostMediationError>?

    func makeRequest(sdkInitHash: SDKInitHash?, completion: @escaping (Result<SDKInitHTTPRequest, ChartboostMediationError>) -> Void) {
        record(.makeRequest, parameters: [sdkInitHash, completion])
        if let autoCompletionResult {
            completion(autoCompletionResult)
        }
    }
}
