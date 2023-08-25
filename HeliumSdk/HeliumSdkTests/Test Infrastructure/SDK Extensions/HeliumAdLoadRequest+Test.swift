// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension HeliumAdLoadRequest {
    /// A convenience factory method to obtain an instance with minimum boilerplate code.
    static func test(
        adSize: CGSize? = CGSize(width: 24.4, height: 50.12),
        adFormat: AdFormat = .interstitial,
        keywords: [String: String]? = ["1234": "@4234", "42342 123 kf,welrp9ip": "adfkajsdk", "": "ewe"],
        heliumPlacement: String = "placement",
        loadID: String = "some id\(Int.random(in: 1...9999))"
    ) -> Self {
        HeliumAdLoadRequest(
            adSize: adSize,
            adFormat: adFormat,
            keywords: keywords,
            heliumPlacement: heliumPlacement,
            loadID: loadID
        )
    }
}
