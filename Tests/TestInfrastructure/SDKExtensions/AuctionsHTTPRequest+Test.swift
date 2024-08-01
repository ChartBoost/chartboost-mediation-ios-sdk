// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension AuctionsHTTPRequest {

    /// A convenience factory method to obtain an instance with minimum boilerplate code.
    static func test(
        adFormat: AdFormat = .interstitial,
        bidRequest: OpenRTB.BidRequest = .init(imp: [], app: nil, device: nil, user: nil, regs: nil, ext: nil, test: nil),
        loadRateLimit: Int = 3,
        loadID: LoadID = "some load id"
    ) -> Self {
        AuctionsHTTPRequest(
            adFormat: adFormat,
            bidRequest: bidRequest,
            loadRateLimit: loadRateLimit,
            loadID: loadID
        )
    }
}
