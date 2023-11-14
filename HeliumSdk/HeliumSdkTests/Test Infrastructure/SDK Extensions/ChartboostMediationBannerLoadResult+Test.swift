// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import Foundation

extension ChartboostMediationBannerLoadResult {
    static func testSuccess(
        loadID: String = "1234",
        metrics: [String: Any]? = nil,
        winningBidInfo: [String: Any]? = nil
    ) -> ChartboostMediationBannerLoadResult {
        ChartboostMediationBannerLoadResult(
            error: nil,
            loadID: loadID,
            metrics: metrics,
            winningBidInfo: winningBidInfo
        )
    }

    static func testFailure(
        loadID: String = "1234",
        metrics: [String: Any]? = nil
    ) -> ChartboostMediationBannerLoadResult {
        ChartboostMediationBannerLoadResult(
            error: .init(code: .internal),
            loadID: loadID,
            metrics: metrics,
            winningBidInfo: nil
        )
    }
}
