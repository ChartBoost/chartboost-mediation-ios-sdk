// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension LoadedAd {
    /// A convenience factory method to obtain an instance with minimum boilerplate code.
    static func test(
        ilrd: [String: Any]? = nil,
        bidInfo: [String: String] = ["asdfasdf": "1234"],
        rewardedCallback: RewardedCallback? = .test(),
        partnerAd: PartnerAd = PartnerFullscreenAdMock(),
        bannerSize: BannerSize = .init(size: .zero, type: .fixed),
        request: InternalAdLoadRequest = .test()
    ) -> Self {
        let bids: [Bid] = [
            Bid.test(ilrd: ilrd, rewardedCallback: rewardedCallback),
            Bid.test(ilrd: ilrd, rewardedCallback: rewardedCallback),
            Bid.test(ilrd: ilrd, rewardedCallback: rewardedCallback)
        ]
        return LoadedAd(
            bids: bids,
            winner: bids[0],
            bidInfo: bidInfo,
            partnerAd: partnerAd,
            bannerSize: bannerSize,
            request: request
        )
    }
}

extension Bid {
    static func test(
        ilrd: [String: Any]? = nil,
        rewardedCallback: RewardedCallback? = .test()
    ) -> Bid {
        Bid(
            identifier: "some identifier \(Int.random(in: 1...99999))",
            partnerID: "some partnerIdentifier",
            partnerPlacement: "some partnerPlacement",
            adm: "some adm \(Int.random(in: 1...99999))",
            partnerDetails: ["a": "1", "2": "b", "92jfo92": "_asfd!#d"],
            lineItemIdentifier: "some lineItemIdentifier",
            ilrd: ilrd,
            cpmPrice: rewardedCallback?.cpmPrice ?? 2.4,
            adRevenue: rewardedCallback?.adRevenue ?? 4.2,
            auctionID: "some auctionIdentifier",
            isProgrammatic: true,
            rewardedCallback: rewardedCallback,
            clearingPrice: 42.24,
            winURL: "winURL",
            lossURL: "lossURL",
            size: nil,
            eventTrackers: [:]
        )
    }
}
