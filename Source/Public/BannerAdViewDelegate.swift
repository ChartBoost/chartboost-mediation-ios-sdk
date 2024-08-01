// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A ``BannerAdView`` delegate that receives ad callbacks.
@objc(CBMBannerAdViewDelegate)
public protocol BannerAdViewDelegate: AnyObject {
    /// Called when a banner ad is about to appear in ``BannerAdView``.
    /// - parameter bannerView: The banner that triggered this event.
    ///
    /// This method is called when the following properties have been updated, but before the banner is displayed on screen:
    /// * ``BannerAdView/loadMetrics``
    /// * ``BannerAdView/size``
    /// * ``BannerAdView/winningBidInfo``
    @objc optional func willAppear(bannerView: BannerAdView)

    /// Called when the ad is clicked by the user.
    /// - parameter bannerView: The banner that triggered this event.
    @objc optional func didClick(bannerView: BannerAdView)

    /// Called when Chartboost Mediation records an impression as result of the ad being shown.
    /// - parameter bannerView: The banner that triggered this event.
    @objc optional func didRecordImpression(bannerView: BannerAdView)
}
