// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import UIKit

/// A Chartboost Mediation fullscreen ad ready to be shown.
///
/// In order to load a fullscreen ad use the ``FullscreenAd/load(with:completion:)`` static method.
@objc(CBMFullscreenAd)
@objcMembers
public final class FullscreenAd: NSObject {
    /// The delegate to receive ad callbacks.
    public weak var delegate: FullscreenAdDelegate?

    /// Optional custom data that will be sent on every rewarded callback.
    ///
    /// Limited to 1000 characters. It will be ignored if the limit is exceeded.
    public var customData: String? {
        get { controller.customData }
        set { controller.customData = newValue }
    }

    /// A unique identifier for the load request.
    public let loadID: String

    /// The request that resulted in this ad getting loaded.
    public let request: FullscreenAdLoadRequest

    /// Information about the bid that won the auction.
    public let winningBidInfo: [String: Any]

    /// The controller that knows how to perform ad actions.
    /// Note that, once created, the FullscreenAd instance has the only strong reference to the controller instance,
    /// thus the controller gets deallocated the moment the Fullscreen ad is.
    private let controller: AdController

    @Injected(\.adLoader) private static var adLoader

    @Injected(\.taskDispatcher) private var taskDispatcher

    init(
        request: FullscreenAdLoadRequest,
        winningBidInfo: [String: Any],
        controller: AdController,
        loadID: String
    ) {
        self.request = request
        self.winningBidInfo = winningBidInfo
        self.controller = controller
        self.loadID = loadID
        super.init()
        controller.delegate = self
    }

    /// Loads a Chartboost Mediation fullscreen ad using the information provided in the request.
    ///
    /// Chartboost Mediation may return the same ad from a previous successful load if it was never shown nor invalidated
    /// before it got discarded.
    /// - Parameter request: A request containing the information used to load the ad.
    /// - Parameter completion: A closure executed when the load operation is done.
    public static func load(
        with request: FullscreenAdLoadRequest,
        completion: @escaping (FullscreenAdLoadResult) -> Void
    ) {
        adLoader.loadFullscreenAd(with: request, completion: completion)
    }

    /// Shows the ad on the specified view controller.
    ///
    /// When done the completion is executed with a result object containing a `nil` error if the show was successful
    /// or a non-`nil` error if the ad failed to show.
    /// - parameter viewController: View controller used to present the ad.
    /// - parameter completion: A closure executed when the show operation is done.
    public func show(with viewController: UIViewController, completion: @escaping (AdShowResult) -> Void) {
        // Show through ad controller
        controller.showAd(viewController: viewController) { [weak self] result in
            guard let self else { return }
            self.taskDispatcher.async(on: .main) {  // all delegate calls on main thread
                // Call completion with an error in case of failure or nil in case of success
                completion(AdShowResult(error: result.error, metrics: result.metrics))
            }
        }
    }

    /// Invalidates the ad so it gets discarded by Chartboost Mediation's internal cache.
    ///
    /// Calling this is unnecessary when the ad is shown. Use it only if you want to discard a particular ad and get a
    /// new one when loading again with the same placement.
    public func invalidate() {
        // Clear ad through controller who is the one that stores instances of `LoadedAd`.
        controller.clearLoadedAd()
    }

    /// Forces the ad to expire due to some internal logic outside of the partner SDK that loaded the ad.
    /// Note that if a partner SDK sends an expiration callback it will be piped to the ``AdControllerDelegate/didExpire()``
    /// method.
    func forceInternalExpiration() {
        controller.forceInternalExpiration()
    }
}

// MARK: - AdControllerDelegate

// Events received from AdController which are forwarded to publishers through delegate method calls.
// All delegate calls are made on the main thread to avoid issues with publishers integrations.
extension FullscreenAd: AdControllerDelegate {
    func didTrackImpression() {
        taskDispatcher.async(on: .main) { [self] in
            delegate?.didRecordImpression?(ad: self)
        }
    }

    func didClick() {
        taskDispatcher.async(on: .main) { [self] in
            delegate?.didClick?(ad: self)
        }
    }

    func didReward() {
        taskDispatcher.async(on: .main) { [self] in
            delegate?.didReward?(ad: self)
        }
    }

    func didDismiss(error: ChartboostMediationError?) {
        taskDispatcher.async(on: .main) { [self] in
            delegate?.didClose?(ad: self, error: error)
        }
    }

    func didExpire() {
        taskDispatcher.async(on: .main) { [self] in
            delegate?.didExpire?(ad: self)
        }
    }
}
