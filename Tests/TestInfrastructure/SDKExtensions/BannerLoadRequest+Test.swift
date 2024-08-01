// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import Foundation

extension BannerAdLoadRequest {
    static func test(
        placement: String = "placement",
        size: BannerSize = .standard,
        partnerSettings: [String: Any] = ["BannerLoadRequest+Test key": "BannerLoadRequest+Test value"]
    ) -> BannerAdLoadRequest {
        .init(
            placement: placement,
            size: size
        )
    }
}
