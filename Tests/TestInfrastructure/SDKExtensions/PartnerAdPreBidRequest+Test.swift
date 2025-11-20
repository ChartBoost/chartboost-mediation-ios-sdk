// Copyright 2025-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension PartnerAdPreBidRequest {
    /// A convenience factory method to obtain an instance with minimum boilerplate code.
    static func test(
        mediationPlacement: String = "some chartboost placement",
        format: PartnerAdFormat = PartnerAdFormats.interstitial,
        partnerPlacement: String = "some partner placement",
        bannerSize: BannerSize? = BannerSize(size: CGSize(width: 20.5, height: 353), type: .fixed),
        partnerSettings: [String: String] = ["1": "a", "vs": "23,2"],
        keywords: [String: String] = ["key1": "value1"],
        loadID: String = "id\(Int.random(in: 1...999999))",
        internalAdFormat: AdFormat = .interstitial
    ) -> PartnerAdPreBidRequest {
        PartnerAdPreBidRequest(
            mediationPlacement: mediationPlacement,
            format: format,
            bannerSize: bannerSize,
            partnerSettings: partnerSettings,
            keywords: keywords,
            loadID: loadID,
            internalAdFormat: internalAdFormat
        )
    }
}
