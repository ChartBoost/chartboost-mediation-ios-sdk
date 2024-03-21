// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension AdLoadRequest {
    /// A convenience factory method to obtain an instance with minimum boilerplate code.
    static func test(
        adSize: ChartboostMediationBannerSize? = .init(
            size: .init(width: 50, height: 50),
            type: .fixed
        ),
        adFormat: AdFormat = .interstitial,
        keywords: [String: String]? = ["1234": "@4234", "42342 123 kf,welrp9ip": "adfkajsdk", "": "ewe"],
        heliumPlacement: String = "placement",
        loadID: String = "some id\(Int.random(in: 1...9999))"
    ) -> Self {
        AdLoadRequest(
            adSize: adSize,
            adFormat: adFormat,
            keywords: keywords,
            mediationPlacement: heliumPlacement,
            loadID: loadID
        )
    }
}
