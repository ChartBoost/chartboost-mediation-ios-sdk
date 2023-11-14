// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// The result of a banner load operation.
@objc
public class ChartboostMediationBannerLoadResult: ChartboostMediationAdLoadResult {
    // This is provided as a compatibility for HeliumBannerView.
    //
    // HeliumBannerView wraps ChartboostMediationBannerView, and passes through its legacy load call
    // to the new load call. In the load completion, HeliumBannerView calls its delegates
    // heliumBannerAd(placementName:requestIdentifier:winningBidInfo:didLoadWithError:) method.
    // However, at this point, ChartboostMediationBannerView.winningBidInfo has not been updated to
    // the new value. The workaround is to provide winningBidInfo in this object, so that
    // HeliumBannerView can pass this back to its delegate. We can remove this when we remove
    // HeliumBannerView.
    //
    // On the ChartboostMediationBannerView, this is provided as a property on the view itself,
    // and the delegate is notified of changes in `willAppear`.
    let winningBidInfo: [String: Any]?

    init(
        error: ChartboostMediationError?,
        loadID: String,
        metrics: [String : Any]?,
        winningBidInfo: [String: Any]?
    ) {
        self.winningBidInfo = winningBidInfo
        super.init(error: error, loadID: loadID, metrics: metrics)
    }
}
