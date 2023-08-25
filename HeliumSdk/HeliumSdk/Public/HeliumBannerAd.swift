// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import UIKit

/// Helium banner ad.
@objc
public protocol HeliumBannerAd {
    
    /// Optional keywords that can be associated with the advertisement placement.
    ///
    /// - Note: Changing the keywords for an already-loaded banner will not take effect until the
    /// next auto-refresh load.
    var keywords: HeliumKeywords? { get set }
        
    /// Asynchronously loads an ad.
    ///
    /// When complete, the delegate method ``HeliumBannerAdDelegate/heliumBannerAd(placementName:requestIdentifier:winningBidInfo:didLoadWithError:)`` will
    /// be invoked.
    /// When the banner view is visible in the app's view hierarchy it will automatically present the loaded ad.
    /// Calling this method will start the banner auto-refresh process.
    /// Only one ``HeliumBannerAdDelegate/heliumBannerAd(placementName:requestIdentifier:winningBidInfo:didLoadWithError:)`` call will be made per `load(with:)`
    /// call, even if more ads are loaded as result of the banner auto-refresh process.
    /// - parameter viewController: View controller used to present the ad.
    @objc(loadAdWithViewController:)
    func load(with viewController: UIViewController)
    
    /// Clears the loaded ad, removes the currently presented ad if any, and stops the auto-refresh process.
    @objc(clearAd)
    func clear()
}

/// Helium banner size to request.
@objc
public enum CHBHBannerSize: Int {
    
    /// Standard 320x50 size.
    @objc(CHBHBannerSize_Standard)
    case standard = 0
    
    /// Medium Rectangle 300x250 size.
    @objc(CHBHBannerSize_Medium)
    case medium = 1
    
    /// Leaderboard 728x90 size.
    @objc(CHBHBannerSize_Leaderboard)
    case leaderboard = 2
    
    /// CGSize that corresponds to the banner size constant.
    internal var cgSize: CGSize {
        switch self {
        case .standard: return CGSize(width: 320, height: 50)
        case .medium: return CGSize(width: 300, height: 250)
        case .leaderboard: return CGSize(width: 728, height: 90)
        }
    }
}

/// Callbacks for ``HeliumBannerAd``.
@objc(CHBHeliumBannerAdDelegate)
public protocol HeliumBannerAdDelegate: AnyObject {
    /// Ad finished loading with an optional error.
    /// - Parameter placementName: Placement associated with the load completion.
    /// - Parameter requestIdentifier: A unique identifier for the load request. It can be ignored in most SDK integrations.
    /// - Parameter winningBidInfo: Bid information JSON.
    /// - Parameter error: Optional error associated with the ad load.
    func heliumBannerAd(placementName: String, requestIdentifier: String, winningBidInfo: [String: Any]?, didLoadWithError error: ChartboostMediationError?)
    
    // MARK: - Optional
    
    /// Ad click event with an optional error.
    /// - Parameter placementName: Placement associated with the click event.
    /// - Parameter error: Optional error associated with the click event.
    @objc optional func heliumBannerAd(placementName: String, didClickWithError error: ChartboostMediationError?)
    
    /// Ad impression recorded by Helium as result of an ad being shown.
    /// - Parameter placementName: Placement associated with the impression event.
    @objc optional func heliumBannerAdDidRecordImpression(placementName: String)
}
