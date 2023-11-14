// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A ``ChartboostMediationBannerView`` delegate that receives ad callbacks.
@objc
public protocol ChartboostMediationBannerViewDelegate: AnyObject {
    /// Called when a banner ad is about to appear in ``ChartboostMediationBannerView``.
    /// - parameter bannerView: The banner that triggered this event.
    ///
    /// This method is called when the following properties have been updated, but before the banner is displayed on screen:
    /// * ``ChartboostMediationBannerView/loadMetrics``
    /// * ``ChartboostMediationBannerView/size``
    /// * ``ChartboostMediationBannerView/winningBidInfo``
    @objc optional func willAppear(bannerView: ChartboostMediationBannerView)

    /// Called when the ad is clicked by the user.
    /// - parameter bannerView: The banner that triggered this event.
    @objc optional func didClick(bannerView: ChartboostMediationBannerView)

    /// Called when Chartboost Mediation records an impression as result of the ad being shown.
    /// - parameter bannerView: The banner that triggered this event.
    @objc optional func didRecordImpression(bannerView: ChartboostMediationBannerView)
}
