// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A ``ChartboostMediationFullscreenAd`` delegate that receives ad callbacks.
@objc
public protocol ChartboostMediationFullscreenAdDelegate: AnyObject {
    
    /// Called when Chartboost Mediation records an impression as result of the ad being shown.
    /// - parameter ad: The ad that triggered this event.
    @objc optional func didRecordImpression(ad: ChartboostMediationFullscreenAd)
    
    /// Called when the ad is clicked by the user.
    /// - parameter ad: The ad that triggered this event.
    @objc optional func didClick(ad: ChartboostMediationFullscreenAd)
    
    /// Called when the ad finished playing, allowing the user to earn a reward.
    /// 
    /// Will not get called for interstitial ad formats.
    /// - parameter ad: The ad that triggered this event.
    @objc optional func didReward(ad: ChartboostMediationFullscreenAd)
    
    /// Called when the ad is closed and no longer visible.
    /// - parameter ad: The ad that triggered this event.
    /// - parameter error: The error that caused the closing of the ad, or `nil` if the closing of the ad was expected.
    @objc optional func didClose(ad: ChartboostMediationFullscreenAd, error: ChartboostMediationError?)
    
    /// Called when the ad expired.
    /// - parameter ad: The ad that triggered this event.
    @objc optional func didExpire(ad: ChartboostMediationFullscreenAd)
}
