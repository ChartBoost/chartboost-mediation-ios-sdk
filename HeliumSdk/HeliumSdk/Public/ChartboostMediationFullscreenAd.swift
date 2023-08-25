// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import UIKit

/// A Chartboost Mediation fullscreen ad ready to be shown.
@objc
public protocol ChartboostMediationFullscreenAd: AnyObject {
    
    /// The delegate to receive ad callbacks.
    @objc weak var delegate: ChartboostMediationFullscreenAdDelegate? { get set }
    
    /// Optional custom data that will be sent on every rewarded callback.
    ///
    /// Limited to 1000 characters. It will be ignored if the limit is exceeded.
    @objc var customData: String? { get set }
    
    /// The request that resulted in this ad getting loaded.
    @objc var request: ChartboostMediationAdLoadRequest { get }
    
    /// Information about the bid that won the auction.
    @objc var winningBidInfo: [String: Any] { get }
    
    /// Shows the ad on the specified view controller.
    ///
    /// When done the completion is executed with a result object containing a `nil` error if the show was successful
    /// or a non-`nil` error if the ad failed to show.
    /// - parameter viewController: View controller used to present the ad.
    /// - parameter completion: A closure executed when the show operation is done.
    @objc func show(with viewController: UIViewController, completion: @escaping (ChartboostMediationAdShowResult) -> Void)
    
    /// Invalidates the ad so it gets discarded by Chartboost Mediation's internal cache.
    ///
    /// Calling this is unnecessary when the ad is shown. Use it only if you want to discard a particular ad and get a
    /// new one when loading again with the same placement.
    @objc func invalidate()
}
