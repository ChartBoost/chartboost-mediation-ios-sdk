// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension InternalAdLoadRequest {
    /// A convenience factory method to obtain an instance with minimum boilerplate code.
    static func test(
        adSize: BannerSize? = nil,
        adFormat: AdFormat = .interstitial,
        keywords: [String: String]? = ["1234": "@4234", "42342 123 kf,welrp9ip": "adfkajsdk", "": "ewe"],
        heliumPlacement: String = "placement",
        partnerSettings: [String: Any] = ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
        loadID: String = "some id\(Int.random(in: 1...9999))"
    ) -> Self {
        InternalAdLoadRequest(
            adSize: adSize,
            adFormat: adFormat,
            keywords: keywords,
            mediationPlacement: heliumPlacement,
            loadID: loadID,
            partnerSettings: partnerSettings
        )
    }
}
