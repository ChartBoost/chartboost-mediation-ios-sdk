// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A result returned by Chartboost Mediation at the end of a fullscreen ad load operation.
@objc(CBMFullscreenAdLoadResult)
public class FullscreenAdLoadResult: AdLoadResult {
    /// The loaded ad if the load was successful, `nil` otherwise.
    @objc public let ad: FullscreenAd?

    init(ad: FullscreenAd?, error: ChartboostMediationError?, loadID: String, metrics: [String: Any]?, winningBidInfo: [String: Any]?) {
        self.ad = ad
        super.init(error: error, loadID: loadID, metrics: metrics, winningBidInfo: winningBidInfo)
    }
}
