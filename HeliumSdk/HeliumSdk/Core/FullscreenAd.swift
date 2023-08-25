// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Concrete class that implements the public ChartboostMediationFullscreenAd protocol.
/// These are the ad instances that publishers use to ask Chartboost Mediation to show ads.
/// Publishers are responsible for keeping them alive.
final class FullscreenAd: ChartboostMediationFullscreenAd, AdControllerDelegate {
    
    /// The delegate to receive ad callbacks.
    weak var delegate: ChartboostMediationFullscreenAdDelegate?
    
    /// Optional custom data that will be sent on every rewarded callback.
    /// Limited to 1000 characters. It will be ignored if the limit is exceeded.
    var customData: String? {
        get { controller.customData }
        set { controller.customData = newValue }
    }
    
    /// The request that resulted in this ad getting loaded.
    let request: ChartboostMediationAdLoadRequest
    
    /// Information about the bid that won the auction.
    let winningBidInfo: [String: Any]
    
    /// The controller that knows how to perform ad actions.
    /// Note that, once created, the FullscreenAd instance has the only strong reference to the controller instance,
    /// thus the controller gets deallocated the moment the Fullscreen ad is.
    private let controller: AdController
    
    @Injected(\.taskDispatcher) private var taskDispatcher
    
    init(request: ChartboostMediationAdLoadRequest, winningBidInfo: [String: Any], controller: AdController) {
        self.request = request
        self.winningBidInfo = winningBidInfo
        self.controller = controller
        
        controller.delegate = self
    }
    
    func show(with viewController: UIViewController, completion: @escaping (ChartboostMediationAdShowResult) -> Void) {
        // Show through ad controller
        controller.showAd(viewController: viewController) { [weak self] result in
            guard let self = self else { return }
            self.taskDispatcher.async(on: .main) {  // all delegate calls on main thread
                // Call completion with an error in case of failure or nil in case of success
                completion(ChartboostMediationAdShowResult(error: result.error, metrics: result.metrics))
            }
        }
    }
    
    func invalidate() {
        // Clear ad through controller who is the one that stores HeliumAds.
        controller.clearLoadedAd()
    }
}

// MARK: - AdControllerDelegate

// Events received from AdController which are forwarded to publishers through delegate method calls.
// All delegate calls are made on the main thread to avoid issues with publishers integrations.
extension FullscreenAd {
    
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
