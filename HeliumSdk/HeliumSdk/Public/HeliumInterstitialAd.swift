// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import UIKit

/// Chartboost Mediation interstitial ad.
@objc
public protocol HeliumInterstitialAd {
    /// Optional keywords that can be associated with the advertisement placement.
    var keywords: HeliumKeywords? { get set }

    /// Asynchronously loads an ad.
    /// 
    /// When complete, the delegate method
    /// ``CHBHeliumInterstitialAdDelegate/heliumInterstitialAd(withPlacementName:requestIdentifier:winningBidInfo:didLoadWithError:)``
    /// will be invoked.
    @objc(loadAd)
    func load()

    /// Clears the loaded ad.
    func clearLoadedAd()

    /// Asynchronously shows the ad with the specified view controller.
    ///
    /// When complete, the delegate method ``CHBHeliumInterstitialAdDelegate/heliumInterstitialAd(withPlacementName:didShowWithError:)``
    /// will be invoked.
    /// - parameter viewController: View controller used to present the ad.
    @objc(showAdWithViewController:)
    func show(with viewController: UIViewController)

    /// Indicates that the ad is ready to show.
    func readyToShow() -> Bool
}

/// Callbacks for ``HeliumInterstitialAd``.
@objc
public protocol CHBHeliumInterstitialAdDelegate: NSObjectProtocol {
    /// Ad finished loading with an optional error.
    /// - parameter placementName: Placement associated with the load completion.
    /// - parameter requestIdentifier: A unique identifier for the load request. It can be ignored in most SDK integrations.
    /// - parameter winningBidInfo: Bid information JSON.
    /// - parameter error: Optional error associated with the ad load.
    func heliumInterstitialAd(
        withPlacementName placementName: String,
        requestIdentifier: String,
        winningBidInfo: [String: Any]?,
        didLoadWithError error: ChartboostMediationError?
    )

    /// Ad finished showing with an optional error.
    /// - parameter placementName: Placement associated with the show completion.
    /// - parameter error: Optional error associated with the ad show.
    func heliumInterstitialAd(withPlacementName placementName: String, didShowWithError error: ChartboostMediationError?)

    /// Ad finished closing with an optional error.
    /// - parameter placementName: Placement associated with the close completion.
    /// - parameter error: Optional error associated with the ad close.
    func heliumInterstitialAd(withPlacementName placementName: String, didCloseWithError error: ChartboostMediationError?)

    /// Ad click event with an optional error.
    /// - parameter placementName: Placement associated with the click event.
    /// - parameter error: Optional error associated with the click event.
    @objc optional func heliumInterstitialAd(withPlacementName placementName: String, didClickWithError error: ChartboostMediationError?)

    /// Ad impression recorded by Chartboost Mediation as result of an ad being shown.
    /// - parameter placementName: Placement associated with the impression event.
    @objc optional func heliumInterstitialAdDidRecordImpression(withPlacementName placementName: String)
}
