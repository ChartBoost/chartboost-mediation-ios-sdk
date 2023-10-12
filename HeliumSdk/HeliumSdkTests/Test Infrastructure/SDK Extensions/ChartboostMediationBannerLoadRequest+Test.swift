// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import Foundation

extension ChartboostMediationBannerLoadRequest {
    static func test(
        placement: String = "placement",
        size: ChartboostMediationBannerSize = .standard
    ) -> ChartboostMediationBannerLoadRequest {
        ChartboostMediationBannerLoadRequest(
            placement: placement,
            size: size
        )
    }
}
