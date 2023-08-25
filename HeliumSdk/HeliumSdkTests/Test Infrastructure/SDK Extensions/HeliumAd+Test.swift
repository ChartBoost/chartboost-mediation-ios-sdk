// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension HeliumAd {
    /// A convenience factory method to obtain an instance with minimum boilerplate code.
    static func test(
        ilrd: [String: Any]? = nil,
        bidInfo: [String: String] = ["asdfasdf": "1234"],
        rewardedCallback: RewardedCallback? = .test(),
        partnerAd: PartnerAd = PartnerAdMock(),
        request: HeliumAdLoadRequest = .test()
    ) -> Self {
        let bid = Bid(
            identifier: "some identifier \(Int.random(in: 1...99999))",
            partnerIdentifier: "some partnerIdentifier",
            partnerPlacement: "some partnerPlacement",
            adm: "some adm \(Int.random(in: 1...99999))",
            partnerDetails: ["a": "1", "2": "b", "92jfo92": "_asfd!#d"],
            lineItemIdentifier: "some lineItemIdentifier",
            ilrd: ilrd,
            cpmPrice: rewardedCallback?.cpmPrice ?? 2.4,
            adRevenue: rewardedCallback?.adRevenue ?? 4.2,
            auctionIdentifier: "some auctionIdentifier",
            isProgrammatic: true,
            rewardedCallback: rewardedCallback,
            clearingPrice: 42.24,
            winURL: "winURL",
            lossURL: "lossURL"
        )

        return HeliumAd(
            bid: bid,
            bidInfo: bidInfo,
            partnerAd: partnerAd,
            request: request
        )
    }
}
