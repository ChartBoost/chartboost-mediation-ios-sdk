// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import UIKit

/// Manages mediated partner networks.
protocol PartnerController: ConsentSettingsDelegate {
    
    /// A closure that cancels an ongoing operation.
    typealias CancelAction = () -> Void
    
    /// Information about the successfully initialized partners.
    var initializedAdapterInfo: [PartnerIdentifier: PartnerAdapterInfo] { get }
    /// Initializes all the available partner adapters.
    /// - warning: This method should be called only once.
    /// - parameter configurations: Configuration data for each adapter to set up.
    /// - parameter adapterClasses: Name of all the potentially available partner adapter classes.
    /// - parameter partnerIdentifiersToSkip: Optional set of partner adapter identifiers to skip initializing.
    /// - parameter completion: Report the metrics events back to the caller.
    func setUpAdapters(configurations: [PartnerIdentifier: PartnerConfiguration], adapterClasses: Set<String>, skipping partnerIdentifiersToSkip: Set<PartnerIdentifier>, completion: @escaping ([MetricsEvent]) -> Void)
    /// Forwards a load request to a partner.
    /// - parameter request: Information about the ad load request.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter delegate: The delegate object that will receive ad life-cycle events.
    /// - parameter completion: A closure to be executed when the load operation ends, including the result with the loaded ad.
    /// - returns: A closure that cancels the load operation if executed, making sure the passed `completion` closure never fires.
    func routeLoad(request: PartnerAdLoadRequest, viewController: UIViewController?, delegate: PartnerAdDelegate, completion: @escaping (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void) -> CancelAction
    /// Forwards a show request to a partner.
    /// - parameter ad: A previously loaded ad to show.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: A closure to be executed when the show operation ends. It includes an optional error.
    func routeShow(_ ad: PartnerAd, viewController: UIViewController, completion: @escaping (ChartboostMediationError?) -> Void)
    /// Invalidates a loaded ad, freeing up its memory and resetting the partner to a state where it can load a new ad.
    /// - parameter ad: A previously loaded ad to invalidate.
    /// - parameter completion: A closure to be executed when the show operation ends. It includes an optional error.
    func routeInvalidate(_ ad: PartnerAd, completion: @escaping (ChartboostMediationError?) -> Void)
    /// Fetches bidding tokens needed for a partner to participate in an auction.
    /// - parameter request: Information about the prebid request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func routeFetchBidderInformation(request: PreBidRequest, completion: @escaping (BidderTokens) -> Void)
}

/// General info about a partner adapter.
struct PartnerAdapterInfo: Equatable {
    /// The version of the partner SDK.
    let partnerVersion: String
    /// The version of the adapter.
    let adapterVersion: String
    /// The partner's unique identifier.
    let partnerIdentifier: String
    /// The human-friendly partner name.
    let partnerDisplayName: String
}
