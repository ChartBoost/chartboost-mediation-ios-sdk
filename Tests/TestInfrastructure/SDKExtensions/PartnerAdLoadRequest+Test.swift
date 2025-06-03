// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension PartnerAdLoadRequest {
    /// A convenience factory method to obtain an instance with minimum boilerplate code.
    static func test(
        partnerID: String = "some partner id",
        mediationPlacement: String = "some chartboost placement",
        partnerPlacement: String = "some partner placement",
        bannerSize: BannerSize? = BannerSize(size: CGSize(width: 20.5, height: 353), type: .fixed),
        adm: String? = "some adm",
        keywords: [String: String] = ["PartnerAdLoadRequest+Test key": "PartnerAdLoadRequest+Test value"],
        partnerSettings: [String: String] = ["1": "a", "vs": "23,2"],
        identifier: String = "id\(Int.random(in: 1...999999))",
        auctionID: String = "auction id\(Int.random(in: 1...999999))",
        adFormat: AdFormat = .interstitial,
        eventTracker: [MetricsEvent.EventType: [ServerEventTracker]] = [:]

    ) -> PartnerAdLoadRequest {
        PartnerAdLoadRequest(
            partnerID: partnerID,
            mediationPlacement: mediationPlacement,
            partnerPlacement: partnerPlacement,
            bannerSize: bannerSize,
            adm: adm,
            keywords: keywords,
            partnerSettings: partnerSettings,
            identifier: identifier,
            auctionID: auctionID,
            internalAdFormat: adFormat,
            eventTrackers: eventTracker
        )
    }
}
