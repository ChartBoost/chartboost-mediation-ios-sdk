// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Concrete class that implements the public HeliumRewardedAd protocol.
/// These are the ad instances that publishers use to ask Helium to load and show ads.
/// Publishers are responsible for keeping them alive.
final class RewardedAd: HeliumRewardedAd, AdControllerDelegate {
    private let controller: AdController
    private weak var delegate: CHBHeliumRewardedAdDelegate?
    private let heliumPlacement: String
    @Injected(\.taskDispatcher) private var taskDispatcher

    init(heliumPlacement: String, delegate: CHBHeliumRewardedAdDelegate?, controller: AdController) {
        self.heliumPlacement = heliumPlacement
        self.delegate = delegate
        self.controller = controller

        controller.addObserver(observer: self)
    }

    // MARK: - HeliumRewardedAd

    /// Optional keywords that can be associated with the advertisement placement.
    var keywords: HeliumKeywords?

    /// Optional custom data that will be sent on every rewarded callback.
    var customData: String? {
        get { controller.customData }
        set { controller.customData = newValue }
    }

    func load() {
        // Load through ad controller
        let request = makeLoadRequest()
        controller.loadAd(request: request, viewController: nil) { [weak self] result in
            guard let self else { return }
            self.taskDispatcher.async(on: .main) {  // all delegate calls on main thread
                switch result.result {
                // If success notify didLoadWinningBid and didLoad
                // The controller can have only one ad loaded at a time. If one was already loaded it completes immediately with success.
                case .success(let ad):
                    // When loadAd() exits early because another ad was already loaded, it returns the identifier for
                    // the already-completed request, not the one for the request that was passed at the same time as this callback.
                    // Thus if an ad is already loaded when the user tries to load an ad, we return the identifier for the
                    // request that completed the load, since that is the one we share with backend and partner adapters.
                    self.delegate?.heliumRewardedAd(
                        withPlacementName: self.heliumPlacement,
                        requestIdentifier: ad.request.loadID,
                        winningBidInfo: ad.bidInfo,
                        didLoadWithError: nil
                    )
                // If failure notify didLoad with an error
                case .failure(let error):
                    self.delegate?.heliumRewardedAd(
                        withPlacementName: self.heliumPlacement,
                        requestIdentifier: request.loadID,
                        winningBidInfo: nil,
                        didLoadWithError: error
                    )
                }
            }
        }
    }

    func clearLoadedAd() {
        // Clear ad through controller who is the one that stores instances of `LoadedAd`.
        controller.clearLoadedAd()
    }

    func show(with viewController: UIViewController) {
        // Show through ad controller
        controller.showAd(viewController: viewController) { [weak self] result in
            guard let self else { return }
            self.taskDispatcher.async(on: .main) {  // all delegate calls on main thread
                // Notify didShow with an error in case of failure or nil in case of success
                self.delegate?.heliumRewardedAd(
                    withPlacementName: self.heliumPlacement,
                    didShowWithError: result.error
                )
            }
        }
    }

    func readyToShow() -> Bool {
        // Ad controller knows since it is the one that stores instances of `LoadedAd`.
        controller.isReadyToShowAd
    }
}

// MARK: - Helpers

extension RewardedAd {
    /// Creates a new load request for the ad controller.
    private func makeLoadRequest() -> AdLoadRequest {
        AdLoadRequest(
            adSize: nil,    // nil means full-screen
            adFormat: .rewarded,
            keywords: keywords?.dictionary,
            heliumPlacement: heliumPlacement,
            loadID: UUID().uuidString
        )
    }
}

// MARK: - AdControllerDelegate

// Events received from AdController which are forwarded to publishers through delegate method calls.
// All delegate calls are made on the main thread to avoid issues with publishers integrations.
extension RewardedAd {
    func didTrackImpression() {
        taskDispatcher.async(on: .main) { [self] in
            delegate?.heliumRewardedAdDidRecordImpression?(
                withPlacementName: heliumPlacement
            )
        }
    }

    func didClick() {
        taskDispatcher.async(on: .main) { [self] in
            delegate?.heliumRewardedAd?(
                withPlacementName: heliumPlacement,
                didClickWithError: nil
            )
        }
    }

    func didReward() {
        taskDispatcher.async(on: .main) { [self] in
            delegate?.heliumRewardedAdDidGetReward(
                withPlacementName: heliumPlacement
            )
        }
    }

    func didDismiss(error: ChartboostMediationError?) {
        taskDispatcher.async(on: .main) { [self] in
            delegate?.heliumRewardedAd(
                withPlacementName: heliumPlacement,
                didCloseWithError: error
            )
        }
    }

    func didExpire() {
        logger.trace("Expiration ignored by rewarded ad")
    }
}
