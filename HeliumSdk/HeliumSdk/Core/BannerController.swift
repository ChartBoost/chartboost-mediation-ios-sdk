// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import UIKit

/// Manages a banner ad logic.
/// Takes care of loading ads, rendering them, and auto-refreshing.
protocol BannerControllerProtocol: AnyObject, ViewVisibilityObserver {
    /// The managed banner view where partner banners are placed in.
    var bannerContainer: UIView? { get set }
    /// Keywords to be sent in API load requests.
    var keywords: HeliumKeywords? { get set }
    /// Loads an ad and renders it using the provided view controller.
    func loadAd(with viewController: UIViewController)
    /// Clears the loaded ad, removes the currently presented ad if any, and stops the auto-refresh process.
    func clearAd()
}

/// Configuration for a banner controller.
protocol BannerControllerConfiguration {
    /// The rate at which banner ads should be refreshed.
    /// 0 means auto-refresh is disabled.
    func autoRefreshRate(forPlacement placement: String) -> TimeInterval
    /// The rate at which loads should be retried by default.
    func normalLoadRetryRate(forPlacement placement: String) -> TimeInterval
    /// The rate at which loads should be retried after hitting a number of consecutive load failures
    /// defined by `penaltyLoadRetryCount`.
    var penaltyLoadRetryRate: TimeInterval { get }
    /// The number of consecutive load failures at which the `penaltyLoadRetryRate` should be applied
    /// instead of the default `loadRetryRate`.
    var penaltyLoadRetryCount: UInt { get }
}

final class BannerController: BannerControllerProtocol, AdControllerDelegate, ViewVisibilityObserver, ApplicationActivationObserver, ApplicationInactivationObserver, FullScreenAdShowObserver {
    
    weak var bannerContainer: UIView?
    private weak var delegate: HeliumBannerAdDelegate?
    private let heliumPlacement: String
    private let adSize: CGSize
    private let adController: AdController
    private let visibilityTracker: VisibilityTracker
    @Injected(\.bannerControllerConfiguration) private var configuration
    @Injected(\.taskDispatcher) private var taskDispatcher
    @Injected(\.fullScreenAdShowCoordinator) private var fullScreenAdShowCoordinator
    @Injected(\.application) private var application
    @Injected(\.metrics) private var metrics
    
    /// The view controller passed on load by the publisher.
    private weak var viewController: UIViewController?
    /// A task that triggers a banner refresh when executed.
    private var showRefreshTask: DispatchTask?
    /// A task that triggers an ad load when executed.
    private var loadRetryTask: DispatchTask?
    /// The number of times in a row that loading an ad has failed.
    private var loadRetryCount = 0
    /// Indicates if the banner view should be layed out immediately after the current load operation finishes.
    private var needsToShowOnLoad = false
    /// Indicates if the didLoad delegate method should be called immediately after the current load operation finishes.
    private var needsToCallDelegateOnLoad = false
    /// Indicates if the load retry cycle should be stopped after the current load operation finishes.
    private var needsToStopLoadRetryCycle = false
    /// The last visible state received from the banner container through ViewVisibilityObserver methods.
    private var isBannerContainerVisible = false
    
    // MARK: -
    
    init(
        heliumPlacement: String,
        adSize: CGSize,
        delegate: HeliumBannerAdDelegate?,
        adController: AdController,
        visibilityTracker: VisibilityTracker
    ) {
        self.heliumPlacement = heliumPlacement
        self.adSize = adSize
        self.delegate = delegate
        self.adController = adController
        self.visibilityTracker = visibilityTracker
        
        application.addObserver(self)   // to pause/resume autorefresh when app goes to background/foreground
        fullScreenAdShowCoordinator.addObserver(self)   // to pause/resume autorefresh when full-screen ad is shown/closed
        adController.addObserver(observer: self)    // to receive ad life-cycle events
    }
    
    deinit {
        // to make sure we don't keep partner banner views in memory when not needed
        adController.clearLoadedAd()
        adController.clearShowingAd { _ in }
    }
    
    // MARK: - BannerControllerProtocol
    
    var keywords: HeliumKeywords?
    
    func clearAd() {
        // We clear both the preloaded ad and the currently showing ad.
        adController.clearLoadedAd()
        adController.clearShowingAd { _ in }
        
        taskDispatcher.async(on: .background) {
            self.needsToShowOnLoad = false
            self.needsToCallDelegateOnLoad = false
            self.needsToStopLoadRetryCycle = true
        }
        taskDispatcher.async(on: .main) {
            self.removeShowingBanner()
        }
        visibilityTracker.stopTracking()
        showRefreshTask?.cancel()
        loadRetryTask?.cancel()
    }

    func loadAd(with viewController: UIViewController) {
        showRefreshTask?.cancel()
        loadRetryTask?.cancel()
        let request = makeLoadRequest()
        taskDispatcher.async(on: .background) { [weak self] in
            guard let self = self else { return }
            // finish early if ad is loaded and waiting to become visible
            guard !self.visibilityTracker.isTracking else {
                logger.warning("Load ignored for already loaded banner waiting to become visible")
                self.needsToCallDelegateOnLoad = true   // only to trigger a delegate method call in the line below
                self.callDelegateLoadIfNeeded(with: nil, request: request)
                return
            }
            // load a new ad
            self.viewController = viewController
            self.needsToShowOnLoad = true
            self.needsToCallDelegateOnLoad = true
            self.needsToStopLoadRetryCycle = false
            self.loadAdAndShowIfNeeded(with: request)
        }
    }

    // MARK: -
    
    private func loadAdAndShowIfNeeded(with request: HeliumAdLoadRequest) {
        // Load through ad controller
        // Note that multiple calls will be ignored by the ad controller if a load is already ongoing
        adController.loadAd(request: request, viewController: viewController) { [weak self] result in
            self?.taskDispatcher.async(on: .background) { [self] in
                guard let self = self else { return }
                // Notify delegate of result
                let isFirstLoad = self.needsToCallDelegateOnLoad // indicates if it's the first load result from a publisher loadAd() call, as against a load triggered due to auto-refresh
                self.callDelegateLoadIfNeeded(with: result.result, request: request)
                // Load success: reset load retry count, show ad if needed
                if case .success(let ad) = result.result, let view = ad.partnerAd.inlineView {
                    self.resetLoadRetryCount()
                    // Show the ad if needed. Otherwise the loaded ad remains cached by ad controller and can be accessed later by another call to loadAd()
                    if !self.needsToStopLoadRetryCycle && self.needsToShowOnLoad {
                        self.needsToShowOnLoad = false
                        self.showAd(ad, bannerView: view)
                    }
                // Load failure: schedule a load retry if needed
                } else if self.isAutoRefreshEnabled && !self.needsToStopLoadRetryCycle && (self.isBannerContainerVisible || !isFirstLoad) {
                    // We do not schedule a load retry if: autorefresh is not enabled, or clearAd() was called, or the view is not visible on the first load.
                    // Note that for auto-refresh (non-first) loads the retry task is scheduled but paused immediately if the banner is not visible (see scheduleLoadRetry()).
                    self.scheduleLoadRetry()
                }
            }
        }
    }
    
    private func callDelegateLoadIfNeeded(with loadResult: Result<HeliumAd, ChartboostMediationError>?, request: HeliumAdLoadRequest) {
        guard needsToCallDelegateOnLoad else { return }

        needsToCallDelegateOnLoad = false
        taskDispatcher.async(on: .main) { [self] in // all delegate calls on main thread
            switch loadResult {
            // If success notify didLoadWinningBid and didLoad
            // The controller can have only one ad loaded at a time. If one was already loaded it completes immediately with success.
            case .success(let ad):
                // When loadAd() exits early because another ad was already loaded, it returns the identifier for
                // the already-completed request, not the one for the request that was passed at the same time as this callback.
                // Thus if an ad is already loaded when the user tries to load an ad, we return the identifier for the
                // request that completed the load, since that is the one we share with backend and partner adapters.
                delegate?.heliumBannerAd(placementName: heliumPlacement, requestIdentifier: ad.request.loadID, winningBidInfo: ad.bidInfo, didLoadWithError: nil)
            // nil means a load request happened when an ad was already loaded but waiting to get shown
            case nil:
                delegate?.heliumBannerAd(placementName: heliumPlacement, requestIdentifier: request.loadID, winningBidInfo: nil, didLoadWithError: nil)
            // If failure notify didLoad with an error
            case .failure(let error):
                delegate?.heliumBannerAd(placementName: heliumPlacement, requestIdentifier: request.loadID, winningBidInfo: nil, didLoadWithError: error)
            }
        }
    }
    
    private func showAd(_ ad: HeliumAd, bannerView: UIView) {
        taskDispatcher.async(on: .main) { [self] in
            guard let bannerContainer = bannerContainer else {
                return
            }
            // Clean up previously showing ad
            visibilityTracker.stopTracking()
            removeShowingBanner()
            adController.clearShowingAd { [weak self] _ in
                // Show new ad, after the previous ad has been cleared so partners that have trouble displaying multiple ads for the same placement (Vungle) can do so sequentially.
                self?.taskDispatcher.async(on: .main) {
                    self?.layOutBanner(bannerView, in: bannerContainer)
                }
            }
            // Wait until it is visible
            logger.info("Waiting for banner ad with placement \(heliumPlacement) to become visible")
            let start = Date()
            visibilityTracker.startTracking(bannerView) { [weak self] in
                self?.taskDispatcher.async(on: .background) { [self] in
                    guard let self = self else { return }
                    logger.debug("Banner ad with placement \(self.heliumPlacement) became visible")
                    // Log metrics
                    _ = self.metrics.logShow(ad: ad, start: start, error: nil)
                    // Mark it as shown so ad controller records impression and allows to load a new ad
                    self.adController.markLoadedAdAsShown()
                    // Schedule auto-refresh
                    if self.isAutoRefreshEnabled {
                        logger.debug("Preloading banner ad with placement \(self.heliumPlacement)")
                        self.loadAdAndShowIfNeeded(with: self.makeLoadRequest())   // we pre-load the next ad immediately so there's higher chances it is ready by the time we need to refresh the banner
                        self.scheduleShowRefresh()
                    }
                }
            }
        }
    }
    
    private func layOutBanner(_ bannerView: UIView, in bannerContainer: UIView) {
        logger.debug("Adding ad with placement \(heliumPlacement) to banner container")
        bannerView.frame = CGRect(origin: .zero, size: adSize)
        bannerContainer.addSubview(bannerView)
    }
    
    private func removeShowingBanner() {
        logger.debug("Removing ad with placement \(heliumPlacement) from banner container")
        bannerContainer?.subviews.first?.removeFromSuperview()
    }
    
    private func scheduleShowRefresh() {
        showRefreshTask?.cancel()
        let refreshRate = configuration.autoRefreshRate(forPlacement: heliumPlacement)
        logger.info("Auto-refresh scheduled in \(refreshRate)s for banner ad with placement \(heliumPlacement)")
        showRefreshTask = taskDispatcher.async(on: .background, delay: refreshRate) { [weak self] in
            guard let self = self else { return }
            logger.debug("Auto-refresh fired for banner ad with placement \(self.heliumPlacement)")
            
            self.loadRetryTask?.cancel()    // cancel scheduled load retry since we will trigger a new load right now
            // Set the flag so we show immediately on load
            self.needsToShowOnLoad = true
            // Load ad:
            // if a previous load had already finished successfully this immediately shows the loaded ad
            // if a previous load had already finished with failure then this triggers a new load
            // if a load was already ongoing this will do nothing, since AdController ignores duplicate load requests for the same placement
            self.loadAdAndShowIfNeeded(with: self.makeLoadRequest())
        }
    }
    
    private func scheduleLoadRetry() {
        loadRetryTask?.cancel()
        loadRetryCount += 1
        logger.debug("Load retry #\(loadRetryCount) scheduled in \(loadRetryDelay)s for banner ad with placement \(heliumPlacement)")
        loadRetryTask = taskDispatcher.async(on: .background, delay: loadRetryDelay) { [weak self] in
            guard let self = self else { return }
            logger.debug("Load retry #\(self.loadRetryCount) fired for banner ad with placement \(self.heliumPlacement)")
            self.loadAdAndShowIfNeeded(with: self.makeLoadRequest())
        }
        // If the banner is not visible we still schedule the task but we pause it immediately. This way whenever the banner becomes visible again
        // the task will be resumed and the auto-refresh cycle will continue.
        // Note this does not apply to first loads (see loadAd()), since in those cases we want to stop the auto-refresh cycle completely.
        if !isBannerContainerVisible {
            loadRetryTask?.pause()
        }
    }
    
    private func resetLoadRetryCount() {
        loadRetryCount = 0
    }
    
    private var loadRetryDelay: TimeInterval {
        loadRetryCount < configuration.penaltyLoadRetryCount
            ? configuration.normalLoadRetryRate(forPlacement: heliumPlacement)
            : configuration.penaltyLoadRetryRate
    }
    
    private var isAutoRefreshEnabled: Bool {
        configuration.autoRefreshRate(forPlacement: heliumPlacement) > 0
    }
    
    /// Creates a new load request for the ad controller.
    private func makeLoadRequest() -> HeliumAdLoadRequest {
        HeliumAdLoadRequest(
            adSize: adSize,
            adFormat: .banner,
            keywords: keywords?.dictionary,
            heliumPlacement: heliumPlacement,
            loadID: UUID().uuidString
        )
    }
    
    // MARK: - ViewVisibilityObserver
    
    func viewVisibilityDidChange(on view: UIView, to visible: Bool) {
        isBannerContainerVisible = visible
        if visible {
            // If view becomes hidden we stop the refresh and load retry processes, since we don't want ad load requests to happen constantly for an unused banner.
            showRefreshTask?.resume()
            loadRetryTask?.resume()
            
            if showRefreshTask != nil {
                logger.debug("Auto-refresh resumed for banner ad with placement \(heliumPlacement)")
            }
        } else {
            showRefreshTask?.pause()
            loadRetryTask?.pause()
            
            if showRefreshTask != nil {
                logger.debug("Auto-refresh paused for banner ad with placement \(heliumPlacement)")
            }
        }
    }
    
    // MARK: - ApplicationStateObserver
    
    func applicationDidBecomeActive() {
        showRefreshTask?.resume()
        if showRefreshTask != nil {
            logger.debug("Auto-refresh resumed for banner ad with placement \(heliumPlacement)")
        }
    }
    
    func applicationWillBecomeInactive() {
        showRefreshTask?.pause()
        if showRefreshTask != nil {
            logger.debug("Auto-refresh paused for banner ad with placement \(heliumPlacement)")
        }
    }
    
    // MARK: FullScreenAdShowObserver
    
    func didShowFullScreenAd() {
        showRefreshTask?.pause()
        if showRefreshTask != nil {
            logger.debug("Auto-refresh paused for banner ad with placement \(heliumPlacement)")
        }
    }
    
    func didCloseFullScreenAd() {
        showRefreshTask?.resume()
        if showRefreshTask != nil {
            logger.debug("Auto-refresh resumed for banner ad with placement \(heliumPlacement)")
        }
    }
    
    // MARK: - AdControllerDelegate

    // Events received from AdController which are forwarded to publishers through delegate method calls.
    // All delegate calls are made on the main thread to avoid issues with publishers integrations.
    
    func didTrackImpression() {
        taskDispatcher.async(on: .main) { [self] in
            delegate?.heliumBannerAdDidRecordImpression?(placementName: heliumPlacement)
        }
    }
    
    func didClick() {
        taskDispatcher.async(on: .main) { [self] in
            delegate?.heliumBannerAd?(placementName: heliumPlacement, didClickWithError: nil)
        }
    }
    
    func didReward() {
        logger.trace("Reward ignored by banner ad")
    }
    
    func didDismiss(error: ChartboostMediationError?) {
        logger.trace("Dismiss ignored by banner ad")
    }
    
    func didExpire() {
        logger.trace("Expiration ignored by banner ad")
    }
}
