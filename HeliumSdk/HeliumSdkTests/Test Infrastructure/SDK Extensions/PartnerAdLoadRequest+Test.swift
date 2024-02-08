// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension PartnerAdLoadRequest {
    /// A convenience factory method to obtain an instance with minimum boilerplate code.
    static func test(
        partnerIdentifier: String = "some partner id",
        chartboostPlacement: String = "some chartboost placement",
        partnerPlacement: String = "some partner placement",
        format: AdFormat = .interstitial,
        size: CGSize? = CGSize(width: 20.5, height: 353),
        adm: String? = "some adm",
        partnerSettings: [String: String] = ["1": "a", "vs": "23,2"],
        identifier: String = "id\(Int.random(in: 1...999999))",
        auctionIdentifier: String = "auction id\(Int.random(in: 1...999999))"
    ) -> PartnerAdLoadRequest {
        PartnerAdLoadRequest(
            partnerIdentifier: partnerIdentifier,
            chartboostPlacement: chartboostPlacement,
            partnerPlacement: partnerPlacement,
            format: format,
            size: size,
            adm: adm,
            partnerSettings: partnerSettings,
            identifier: identifier,
            auctionIdentifier: auctionIdentifier
        )
    }
}
