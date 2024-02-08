// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import Foundation

extension ChartboostMediationBannerLoadResult {
    static func testSuccess(
        loadID: String = "1234",
        metrics: [String: Any]? = nil,
        size: ChartboostMediationBannerSize = .adaptive(width: 320, maxHeight: 50),
        winningBidInfo: [String: Any]? = nil
    ) -> ChartboostMediationBannerLoadResult {
        ChartboostMediationBannerLoadResult(
            error: nil,
            loadID: loadID,
            metrics: metrics,
            size: size,
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
            size: nil,
            winningBidInfo: nil
        )
    }
}
