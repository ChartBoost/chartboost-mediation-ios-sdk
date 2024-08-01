// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A protocol to which ads created by ``PartnerAdapter`` types conform to.
/// Partner ads are in charge of communicating with a single partner SDK ad instance and reporting back ad life-cycle
/// events corresponding to that ad to the Chartboost Mediation SDK.
/// They also keep track of information related to a single load request.
public protocol PartnerAd: AnyObject, PartnerErrorFactory {
    /// The partner adapter that created this ad.
    var adapter: PartnerAdapter { get }

    /// The ad load request associated to the ad.
    /// It should be the one provided on ``PartnerAdapter/makeBannerAd(request:delegate:)`` 
    /// or ``PartnerAdapter/makeFullscreenAd(request:delegate:)``.
    var request: PartnerAdLoadRequest { get }

    /// The partner ad delegate to send ad life-cycle events to.
    /// It should be the one provided on ``PartnerAdapter/makeBannerAd(request:delegate:)``
    /// or ``PartnerAdapter/makeFullscreenAd(request:delegate:)``.
    var delegate: PartnerAdDelegate? { get }

    /// Extra ad information provided by the partner.
    var details: PartnerDetails { get }

    /// Loads an ad.
    /// Chartboost Mediation SDK will always call this method from the main thread for banner ads.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(
        with viewController: UIViewController?,
        completion: @escaping (Error?) -> Void
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
    func didTrackImpression(_ ad: PartnerAd)
    /// The partner ad was clicked.
    func didClick(_ ad: PartnerAd)
    /// The partner ad received a reward.
    func didReward(_ ad: PartnerAd)
    /// The partner ad was dismissed.
    func didDismiss(_ ad: PartnerAd, error: Error?)
    /// The partner ad expired.
    func didExpire(_ ad: PartnerAd)
}

extension PartnerAd {
    /// Default implementation of `invalidate()` that does nothing.
    public func invalidate() throws {
        // Do nothing
        log(.invalidateSucceeded)
    }
}
