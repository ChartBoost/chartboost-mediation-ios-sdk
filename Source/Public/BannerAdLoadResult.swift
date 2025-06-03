// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// The result of a banner load operation.
@objc(CBMBannerAdLoadResult)
public class BannerAdLoadResult: AdLoadResult {
    /// The size of the loaded ad, or `nil` in the case of load error.
    @objc public let size: BannerSize?

    init(
        error: ChartboostMediationError?,
        loadID: String,
        metrics: [String: Any]?,
        size: BannerSize?,
        winningBidInfo: [String: Any]?
    ) {
        self.size = size
        super.init(error: error, loadID: loadID, metrics: metrics, winningBidInfo: winningBidInfo)
    }
}
