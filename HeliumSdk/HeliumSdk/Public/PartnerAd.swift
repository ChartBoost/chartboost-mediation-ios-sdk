// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A protocol to which ads created by ``PartnerAdapter`` types conform to.
/// Partner ads are in charge of communicating with a single partner SDK ad instance and reporting back ad life-cycle
/// events corresponding to that ad to the Chartboost Mediation SDK.
/// They also keep track of information related to a single load request.
public protocol PartnerAd: AnyObject {
    
    /// The partner adapter that created this ad.
    var adapter: PartnerAdapter { get }
    
    /// The ad load request associated to the ad.
    /// It should be the one provided on ``PartnerAdapter/makeAd(request:delegate:)``.
    var request: PartnerAdLoadRequest { get }

    /// The partner ad delegate to send ad life-cycle events to.
    /// It should be the one provided on ``PartnerAdapter/makeAd(request:delegate:)``.
    var delegate: PartnerAdDelegate? { get }
    
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be `nil` for full-screen ads.
    var inlineView: UIView? { get }
    
    /// Loads an ad.
    /// Chartboost Mediation SDK will always call this method from the main thread for banner ads.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(
        with viewController: UIViewController?,
        completion: @escaping (Result<PartnerEventDetails, Error>) -> Void
    )
    
    /// Shows a loaded ad.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(
        with viewController: UIViewController,
        completion: @escaping (Result<PartnerEventDetails, Error>) -> Void
    )
    
    /// Invalidates a loaded ad.
    /// Chartboost Mediation SDK calls this method right before disposing of an ad.
    ///
    /// A default implementation is provided that does nothing.
    /// Only implement if there is some special cleanup required by the partner SDK before disposing of the ad instance.
    func invalidate() throws
}

/// Protocol that defines how a partner ad communicates life-cycle events back to the Chartboost Mediation SDK.
public protocol PartnerAdDelegate: AnyObject {
    /// The partner ad tracked an impression.
    func didTrackImpression(_ ad: PartnerAd, details: PartnerEventDetails)
    /// The partner ad was clicked.
    func didClick(_ ad: PartnerAd, details: PartnerEventDetails)
    /// The partner ad received a reward.
    func didReward(_ ad: PartnerAd, details: PartnerEventDetails)
    /// The partner ad was dismissed.
    func didDismiss(_ ad: PartnerAd, details: PartnerEventDetails, error: Error?)
    /// The partner ad expired.
    func didExpire(_ ad: PartnerAd, details: PartnerEventDetails)
}

/// `PartnerAd` extension that provides a default implementation of `invalidate()` that does nothing.
public extension PartnerAd {
    
    func invalidate() throws {
        // Do nothing
        log(.invalidateSucceeded)
    }
}
