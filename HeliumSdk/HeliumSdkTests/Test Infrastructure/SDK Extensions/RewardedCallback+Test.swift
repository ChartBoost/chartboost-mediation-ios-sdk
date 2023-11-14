// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension RewardedCallback {
    /// A convenience factory method to obtain an instance with minimum boilerplate code.
    static func test(
        adRevenue: Decimal? = 42.44,
        cpmPrice: Decimal? = 1243.20,
        partnerIdentifier: PartnerIdentifier = "some partner id",
        urlString: String = "http://chartboost.com",
        method: HTTP.Method = .get,
        maxRetries: Int = 2,
        retryDelay: TimeInterval = 1,
        body: String? = nil
    ) -> Self {
        RewardedCallback(
            adRevenue: adRevenue,
            cpmPrice: cpmPrice,
            partnerIdentifier: partnerIdentifier,
            urlString: urlString,
            method: method,
            maxRetries: maxRetries,
            retryDelay: retryDelay,
            body: body
        )
    }
}
