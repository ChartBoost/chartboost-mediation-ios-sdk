// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A result returned by Chartboost Mediation at the end of a fullscreen ad load operation.
@objc
public class ChartboostMediationFullscreenAdLoadResult: ChartboostMediationAdLoadResult {
    
    /// The loaded ad if the load was successful, `nil` otherwise.
    @objc public let ad: ChartboostMediationFullscreenAd?
    
    init(ad: ChartboostMediationFullscreenAd?, error: ChartboostMediationError?, loadID: String, metrics: [String : Any]?) {
        self.ad = ad
        super.init(error: error, loadID: loadID, metrics: metrics)
    }
}
