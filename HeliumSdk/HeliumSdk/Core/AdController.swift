// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import UIKit

/// Manages ad loading and showing, keeping track of loading state, loaded and showing ads.
protocol AdController: AnyObject {
    /// The delegate that receives ad life-cycle event callbacks.
    var delegate: AdControllerDelegate? { get set }
    /// Custom string data programmatically specified by the publisher to be passed in rewarded callbacks.
    var customData: String? { get set }
    /// Indicates if an ad is loaded.
    var isReadyToShowAd: Bool { get }
    /// Loads an ad.
    /// - parameter request: Info about the ad to load.
    /// - parameter viewController: A view controller to load the ad with. Applies to banners.
    /// - completion: A closure to be executed at the end of the load operation.
    func loadAd(request: AdLoadRequest, viewController: UIViewController?, completion: @escaping (AdLoadResult) -> Void)
    /// Removes the loaded ad freeing up any associated internal and partner storage.
    func clearLoadedAd()
    /// Removes the showing ad freeing up any associated internal and partner storage.
    /// It is intended to be used for banners only.
    /// - parameter completion: A closure to be executed when the clear operation ends. It includes an optional error.
    func clearShowingAd(completion: @escaping (ChartboostMediationError?) -> Void)
    /// Shows an ad.
    /// Should not be called for banner ads, since publishers manage their layout.
    /// - parameter viewController: The view controller on which to present the ad on.
    /// - completion: A closure to be executed at the end of the show operation.
    func showAd(viewController: UIViewController, completion: @escaping (AdShowResult) -> Void)
    /// Notifies the ad controller that the loaded ad was shown externally.
    /// Applies only to banner ads. Full-screen ads must be shown by the AdController itself by calling `showAd()`.
    func markLoadedAdAsShown()
    /// Ads a new observer to receive ad life-cycle event callbacks.
    func addObserver(observer: AdControllerDelegate)
}

/// Delegate to receive ad life-cycle events from an AdController.
protocol AdControllerDelegate: AnyObject {
    /// An impression was tracked for the ad.
    func didTrackImpression()
    /// The ad was clicked.
    func didClick()
    /// The ad received a reward.
    func didReward()
    /// The ad was dismissed.
    func didDismiss(error: ChartboostMediationError?)
    /// The ad expired.
    func didExpire()
}

/// Configuration settings for AdController.
protocol AdControllerConfiguration {
    /// The time interval to wait for a partner to show a full-screen ad.
    var showTimeout: TimeInterval { get }
}

/// AdController implementation that can hold at most one loaded ad.
/// Trying to load again when an ad is already loaded will return immediately with success.
/// It is possible to load another ad when the previous one is already shown.
/// - note: With the current architecture there is one AdController instance per Helium placement.
/// Currently multiple ads for the same placement can be created and used, but this is discouraged as they will share the same state.
/// This is the reason AdController needs to know about multiple observers and not just a single delegate.
final class SingleAdStorageAdController: AdController, PartnerAdDelegate {
    @Injected(\.adRepository) private var adRepository
    @Injected(\.partnerController) private var partnerController
    @Injected(\.metrics) private var metrics
    @Injected(\.ilrdEventPublisher) private var ilrdEventPublisher
    @Injected(\.fullScreenAdShowObserver) private var fullScreenAdShowObserver
    @Injected(\.initializationStatusProvider) private var initializationStatusProvider
    @Injected(\.impressionTracker) private var impressionTracker
    @Injected(\.adControllerConfiguration) private var configuration
    @OptionalInjected(\.customTaskDispatcher, default: .serialBackgroundQueue(name: "adController")) private var taskDispatcher

    /// Indicates if a load operation is already ongoing.
    private var isLoading = false
    /// A timeout task that fires if a partner takes too long to show an ad.
    private var showTimeoutTask: DispatchTask?
    /// The fully-loaded ad ready to be shown, if any.
    private var loadedAd: (ad: LoadedAd, metrics: RawMetrics?)?
    /// The currently showing ad, if any. Becomes nil when the ad is dismissed.
    private var showingAd: LoadedAd?
    // TODO: Remove when InterstitialAd and RewardedAd are removed on 5.0
    /// List of added observers. We use WeakReferenceSet to avoid holding strong references to the observers, which would lead to strong
    /// reference cycles.
    private var observers = WeakReferences<AdControllerDelegate>()
    /// A strong reference to the delegate (which should be a FullscreenAd instance).
    /// We keep this reference while the ad is showing to make sure it is kept alive even if the publisher discards it
    /// (e.g. by loading a new ad and assigning the previous reference to the new instance, before the old ad is dismissed),
    /// so we can still send delegate callbacks to the user.
    private var retainedDelegate: AdControllerDelegate? // swiftlint:disable:this weak_delegate

    deinit {
        // Invalidate loaded ad to free its allocated memory.
        // Note that as of now, for banner and fullscreen ads (not so for interstitial nor rewarded), loaded ads that have not been
        // shown are discarded and we don't reuse them for new ad instances with the same placement.
        if let (ad, _) = loadedAd {
            partnerController.routeInvalidate(ad.partnerAd) { _ in }
        }
    }

    // MARK: - AdController

    // Currently applies to FullscreenAd only. Legacy interstitial and rewarded ads add themselves as observers, because they can share the
    // same controller.
    weak var delegate: AdControllerDelegate? {
        // TODO: Remove when observers are removed on 5.0
        didSet {
            if let delegate {
                addObserver(observer: delegate)
            }
        }
    }

    var customData: String?

    var isReadyToShowAd: Bool {
        taskDispatcher.sync(on: .background) { [self] in
            return loadedAd != nil
        }
    }

    func loadAd(request: AdLoadRequest, viewController: UIViewController?, completion: @escaping (AdLoadResult) -> Void) {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Load started for \(request.adFormat) ad with placement \(request.heliumPlacement) and load ID \(request.loadID)")

            // If Helium not started fail early
            guard initializationStatusProvider.isInitialized else {
                logger.error("Load failed due to SDK not being initialized")
                completion(
                    AdLoadResult(
                        result: .failure(ChartboostMediationError(code: .loadFailureChartboostMediationNotInitialized)),
                        metrics: nil
                    )
                )
                return
            }
            // If already loading finish silently
            guard !isLoading else {
                logger.warning("Ad load requested while a current load is already in progress.")
                // We do not call the completion. We want to stay silent and wait for the original request to finish,
                // and only then call the proper callbacks.
                return
            }
            // If already loaded finish successfully
            if let (ad, metrics) = loadedAd {
                logger.info("Ad already loaded with placement \(request.heliumPlacement)")
                completion(AdLoadResult(result: .success(ad), metrics: metrics))
                return
            }
            // When loading a banner, validate the size.
            if let size = request.adSize {
                guard size.isValid else {
                    logger.error("Invalid banner size specified: \(size.size)")
                    completion(
                        AdLoadResult(
                            result: .failure(ChartboostMediationError(code: .loadFailureInvalidBannerSize)),
                            metrics: nil
                        )
                    )
                    return
                }
            }
            // Otherwise load ad
            isLoading = true
            adRepository.loadAd(request: request, viewController: viewController, delegate: self) { [weak self] result in
                guard let self else { return }
                self.taskDispatcher.async(on: .background) {
                    // If success save the ad. Notify completion.
                    self.isLoading = false
                    switch result.result {
                    case .success(let ad):
                        logger.info("Load succeeded for \(request.adFormat) ad with placement \(request.heliumPlacement) and load ID \(request.loadID)")
                        self.loadedAd = (ad, result.metrics)
                    case .failure(let error):
                        logger.error("Load failed for \(request.adFormat) ad with placement \(request.heliumPlacement) and load ID \(request.loadID) and error: \(error)")
                    }
                    completion(result)
                }
            }
        }
    }

    func clearLoadedAd() {
        taskDispatcher.async(on: .background) { [self] in
            // If no loaded ad fail early
            guard let (ad, _) = loadedAd else {
                return
            }
            logger.debug("Invalidating \(ad.request.adFormat) ad with placement \(ad.request.heliumPlacement)")
            // Remove loaded ad
            loadedAd = nil
            // Tell partner to remove the ad on their side
            partnerController.routeInvalidate(ad.partnerAd) { _ in }    // we don't really care about the result
            // Finish successfully. Even if the partner failed to clean up its side, the AdController can in fact load a new ad now.
        }
    }

    func clearShowingAd(completion: @escaping (ChartboostMediationError?) -> Void) {
        taskDispatcher.async(on: .background) { [self] in
            // If no showing ad fail early
            guard let ad = showingAd else {
                completion(nil)
                return
            }
            logger.debug("Invalidating showing \(ad.request.adFormat) ad with placement \(ad.request.heliumPlacement)")
            // Remove showing ad
            showingAd = nil
            // Tell partner to remove the ad on their side
            partnerController.routeInvalidate(ad.partnerAd, completion: completion)
        }
    }

    func showAd(viewController: UIViewController, completion: @escaping (AdShowResult) -> Void) {
        // We strongly capture the delegate in this closure so it doesn't get deallocated before it gets assigned to the
        // `retainedDelegate` property.
        taskDispatcher.async(on: .background) { [self, delegate] in
            // If not loaded ad fail early
            guard let (ad, _) = loadedAd else {
                logger.error("Show failed due to ad not loaded")
                completion(
                    AdShowResult(error: ChartboostMediationError(code: .showFailureAdNotReady), metrics: nil)
                )
                return
            }
            assert(!ad.request.adFormat.isBanner, "Calling this for banner ads is a programmer error")

            logger.debug("Show started for \(ad.request.adFormat) ad with placement \(ad.request.heliumPlacement) and load ID \(ad.request.loadID)")

            // Remove loadedAd since it's now used. This prevents multiple user calls to show() to trigger multiple requests to the
            // partnerController for the same ad.
            loadedAd = nil

            let start = Date()

            // Schedule a timeout task in case the partner takes too long or never shows the ad so we can move on and show a new one
            showTimeoutTask = taskDispatcher.async(on: .background, delay: configuration.showTimeout) { [weak self] in
                guard let self else { return }
                // Log error
                let error = ChartboostMediationError(code: .showFailureTimeout)
                let rawMetrics = self.metrics.logShow(ad: ad, start: start, error: error)
                // Invalidate partner ad
                self.partnerController.routeInvalidate(ad.partnerAd) { _ in }
                // Stop retaining the delegate
                self.retainedDelegate = nil
                // Finish
                logger.error("Show failed for \(ad.request.adFormat) ad with placement \(ad.request.heliumPlacement) and load ID \(ad.request.loadID) and error: \(error)")
                completion(AdShowResult(error: error, metrics: rawMetrics))
            }

            // Retain the delegate so it's alive until the ad gets dismissed.
            // Note this affects only fullscreen ads and not banners, since we don't call showAd() on banners and they do not need
            // to be retained while showing, they already are by their superview.
            retainedDelegate = delegate

            // Show ad through partner controller
            partnerController.routeShow(ad.partnerAd, viewController: viewController) { [weak self] error in
                guard let self else { return }
                self.taskDispatcher.async(on: .background) {
                    // If timeout task was already fired then fail early, since the completion was already called.
                    guard self.showTimeoutTask?.state != .complete else {
                        return
                    }
                    // Cancel the timeout task
                    self.showTimeoutTask?.cancel()

                    // Log metrics
                    let rawMetrics = self.metrics.logShow(ad: ad, start: start, error: error)

                    if let error {
                        // Invalidate partner ad
                        self.partnerController.routeInvalidate(ad.partnerAd) { _ in }
                        // Stop retaining the delegate
                        self.retainedDelegate = nil
                        // Finish
                        logger.error("Show failed for \(ad.request.adFormat) ad with placement \(ad.request.heliumPlacement) and load ID \(ad.request.loadID) and error: \(error)")
                        completion(AdShowResult(error: error, metrics: rawMetrics))
                    } else {
                        // Record a Helium impression
                        self.recordAdImpression(for: ad)
                        // Notify full-screen ad show observer and finish
                        self.fullScreenAdShowObserver.didShowFullScreenAd()
                        logger.info("Show succeeded for \(ad.request.adFormat) ad with placement \(ad.request.heliumPlacement) and load ID \(ad.request.loadID)")
                        completion(AdShowResult(error: nil, metrics: rawMetrics))
                    }
                }
            }
        }
    }

    func markLoadedAdAsShown() {
        taskDispatcher.async(on: .background) { [self] in
            // If not loaded ad fail early
            guard let (ad, _) = loadedAd else {
                logger.warning("No loaded ad found to mark as shown")
                return
            }
            assert(ad.request.adFormat.isBanner, "Calling this for non-banner ads is a programmer error")

            // Remove loadedAd since it's now used.
            loadedAd = nil

            // Record impression
            recordAdImpression(for: ad)
        }
    }

    private func recordAdImpression(for ad: LoadedAd) {
        // Mark the ad as showing
        showingAd = ad

        // Increase the impression count for this format
        impressionTracker.trackImpression(for: ad.request.adFormat)

        // Log a helium impression
        metrics.logHeliumImpression(for: ad.partnerAd)

        // Fire ILRD notification for the winning bid, if available.
        if let ilrd = ad.ilrd {
            ilrdEventPublisher.postILRDEvent(forPlacement: ad.request.heliumPlacement, ilrdJSON: ilrd)
        }

        // Call impression delegate method
        observers.forEach {
            $0.didTrackImpression()
        }
    }

    func addObserver(observer: AdControllerDelegate) {
        taskDispatcher.async(on: .background) { [self] in
            observers.add(observer)
        }
    }
}

// MARK: PartnerAdDelegate

extension SingleAdStorageAdController {
    func didTrackImpression(_ ad: PartnerAd, details: PartnerEventDetails) {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Tracked impression for \(ad.request.format) ad with placement \(ad.request.chartboostPlacement)")
            // Log a partner impression
            metrics.logPartnerImpression(for: ad)
        }
    }

    func didClick(_ ad: PartnerAd, details: PartnerEventDetails) {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Clicked \(ad.request.format) ad with placement \(ad.request.chartboostPlacement)")
            // Log metrics
            metrics.logClick(auctionID: ad.request.auctionIdentifier, loadID: ad.request.loadID)
            // Forward event to ad delegates
            observers.forEach {
                $0.didClick()
            }
        }
    }

    func didReward(_ ad: PartnerAd, details: PartnerEventDetails) {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Rewarded \(ad.request.format) ad with placement \(ad.request.chartboostPlacement)")
            // Forward event to ad delegates
            observers.forEach {
                $0.didReward()
            }
            // Log a reward
            metrics.logReward(for: ad)
            // Log a client-to-server rewarded callback
            if let rewardedCallback = showingAd?.rewardedCallback {
                metrics.logRewardedCallback(rewardedCallback, customData: customData)
            }
        }
    }

    func didDismiss(_ ad: PartnerAd, details: PartnerEventDetails, error: Error?) {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Closed \(ad.request.format) ad with placement \(ad.request.chartboostPlacement)")
            // Remove showing ad
            showingAd = nil
            // Notify full-screen ad show observer
            if !ad.request.format.isBanner {
                fullScreenAdShowObserver.didCloseFullScreenAd()
            }
            // Tell the partner to remove the ad on their side
            partnerController.routeInvalidate(ad) { _ in }   // we don't really care about the result
            // Forward event to ad delegates
            observers.forEach {
                let cmError = error.map { $0 as? ChartboostMediationError ?? .init(code: .partnerError, error: error) }
                $0.didDismiss(error: cmError)
            }
            // Stop retaining the delegate
            retainedDelegate = nil
        }
    }

    func didExpire(_ ad: PartnerAd, details: PartnerEventDetails) {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Expired \(ad.request.format) ad with placement \(ad.request.chartboostPlacement)")
            // Log metrics
            metrics.logExpiration(auctionID: ad.request.auctionIdentifier, loadID: ad.request.loadID)
            // Forward event to ad delegates
            observers.forEach {
                $0.didExpire()
            }
        }
    }
}
