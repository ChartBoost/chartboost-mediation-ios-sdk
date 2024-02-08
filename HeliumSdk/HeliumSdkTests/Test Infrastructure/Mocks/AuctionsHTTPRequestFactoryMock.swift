// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class AuctionsHTTPRequestFactoryMock: Mock<AuctionsHTTPRequestFactoryMock.Method>, AuctionsHTTPRequestFactory {

    enum Method {
        case makeRequest
    }

    /// The result to pass to makeRequest() completion handlers.
    var autoCompletionResult: AuctionsHTTPRequest?

    func makeRequest(request: AdLoadRequest, loadRateLimit: TimeInterval, bidderInformation: BidderInformation, completion: @escaping (AuctionsHTTPRequest) -> Void) {
        record(.makeRequest, parameters: [request, loadRateLimit, bidderInformation, completion])
        if let autoCompletionResult {
            completion(autoCompletionResult)
        }
    }
}
