// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import UIKit

/// The delegate for banner controllers. All delegate calls will be made on the main thread.
protocol BannerControllerDelegate: AnyObject {
    /// Called when `bannerView` is ready for display, and should be added to the containing view.
    func bannerController(
        _ bannerController: BannerControllerProtocol,
        displayBannerView bannerView: UIView
    )

    /// Called when the `bannerView` should be removed from display.
    func bannerController(
        _ bannerController: BannerControllerProtocol,
        clearBannerView bannerView: UIView
    )

    /// Called when an impression is recorded.
    func bannerControllerDidRecordImpression(_ bannerController: BannerControllerProtocol)

    /// Called when the banner is clicked.
    func bannerControllerDidClick(_ bannerController: BannerControllerProtocol)
}

/// Manages a banner ad logic.
/// Takes care of loading ads, rendering them, and auto-refreshing.
protocol BannerControllerProtocol: AnyObject, ViewVisibilityObserver {
    /// The delegate for the banner controller.
    var delegate: BannerControllerDelegate? { get set }

    /// Keywords to be sent in API load requests.
    var keywords: [String: String]? { get set }

    /// Set to `true` to pause auto-refresh logic.
    var isPaused: Bool { get set }

    // MARK: Readonly
    /// The request that the controller was created with.
    var request: ChartboostMediationBannerLoadRequest { get }

    /// The `AdLoadResult` of the currently showing ad, or `nil` if an ad is not being shown.
    var showingBannerLoadResult: AdLoadResult? { get }

    /// Loads an ad and renders it using the provided view controller.
    func loadAd(
        viewController: UIViewController,
        completion: @escaping (ChartboostMediationBannerLoadResult) -> Void
    )
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
    /// The time in seconds after an `impression` event that the `bannerSize` event should fire.
    var bannerSizeEventDelay: TimeInterval { get }
}

final class BannerController: BannerControllerProtocol,
                                AdControllerDelegate,
                                ViewVisibilityObserver,
                                ApplicationActivationObserver,
                                ApplicationInactivationObserver,
                                FullScreenAdShowObserver
{
    weak var delegate: BannerControllerDelegate?
    let request: ChartboostMediationBannerLoadRequest
    private(set) var showingBannerLoadResult: AdLoadResult?
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
    private var loadCompletion: ((ChartboostMediationBannerLoadResult) -> Void)?
    /// A task that triggers an ad load when executed.
    private var loadRetryTask: DispatchTask?
    /// The number of times in a row that loading an ad has failed.
    private var loadRetryCount = 0
    /// Indicates if the banner view should be layed out immediately after the current load operation finishes.
    private var needsToShowOnLoad = false
    /// Indicates if the load retry cycle should be stopped after the current load operation finishes.
    private var needsToStopLoadRetryCycle = false

    // MARK: Paused States
    // There are a number of different reasons we might want to pause our tasks (e.g. the banner
    // view is not visible, the app is backgrounded, etc). We need to calculate composite paused
    // values for our tasks from all of these different reasons, so that when multiple reasons are
    // stacked, we don't unpause until all reasons have been resolved.

    /// The last visible state received from the banner container through ViewVisibilityObserver methods.
    private var isBannerContainerVisible = false {
        didSet {
            updatePausedStates()
        }
    }

    /// `true` if the application is active.
    private var isApplicationActive = true {
        didSet {
            updatePausedStates()
        }
    }

    /// `true` if a fullscreen ad is being displayed on top of this banner.
    private var isFullscreenAdVisible = false {
        didSet {
            updatePausedStates()
        }
    }

    /// Composite state that's set to `true` if `loadRetryTask` should be paused.
    private var isLoadRetryTaskPaused = false {
        didSet {
            guard isLoadRetryTaskPaused != oldValue,
                  let task = loadRetryTask else { return }

            if isLoadRetryTaskPaused {
                task.pause()
                logger.debug("Load retry task paused for banner ad with placement \(request.placement)")
            } else {
                task.resume()
                logger.debug("Load retry task resumed for banner ad with placement \(request.placement)")
            }
        }
    }

    /// Composite state that's set to `true` if `showRefreshTask` should be paused. We track this separately from
    /// `isLoadRetryTaskPaused`, because we want the `showRefreshTask` to track the amount of time the banner is visible,
    /// where as for the `loadRetryTask`, we do not care if the banner is visible or not.
    private var isShowRefreshTaskPaused = false {
        didSet {
            guard isShowRefreshTaskPaused != oldValue,
                  let task = showRefreshTask else { return }

            if isShowRefreshTaskPaused {
                task.pause()
                logger.debug("Auto-refresh paused for banner ad with placement \(request.placement)")
            } else {
                task.resume()
                logger.debug("Auto-refresh resumed for banner ad with placement \(request.placement)")
            }
        }
    }

    // MARK: -

    init(
        request: ChartboostMediationBannerLoadRequest,
        adController: AdController,
        visibilityTracker: VisibilityTracker
    ) {
        self.request = request
        self.adController = adController
        self.visibilityTracker = visibilityTracker

        application.addObserver(self)   // to pause/resume autorefresh when app goes to background/foreground
        fullScreenAdShowCoordinator.addObserver(self)   // to pause/resume autorefresh when full-screen ad is shown/closed
        adController.addObserver(observer: self)    // to receive ad life-cycle events

        // Calculate the initial composite paused states.
        updatePausedStates()
    }

    deinit {
        // to make sure we don't keep partner banner views in memory when not needed
        adController.clearLoadedAd()
        adController.clearShowingAd { _ in }
    }

    // MARK: - BannerControllerProtocol

    var keywords: [String: String]?

    var isPaused = false {
        didSet {
            updatePausedStates()
        }
    }

    func clearAd() {
        // We clear both the preloaded ad and the currently showing ad.
        adController.clearLoadedAd()
        adController.clearShowingAd { _ in }

        taskDispatcher.async(on: .background) {
            self.needsToShowOnLoad = false
            self.needsToStopLoadRetryCycle = true
            // If the pub calls `clearAd` before a load is complete, we don't want call completion,
            // so we will clear the completion block here.
            self.loadCompletion = nil
        }
        taskDispatcher.async(on: .main) {
            self.removeShowingBanner()
        }
        visibilityTracker.stopTracking()
        showRefreshTask?.cancel()
        loadRetryTask?.cancel()
    }

    func loadAd(
        viewController: UIViewController,
        completion: @escaping (ChartboostMediationBannerLoadResult) -> Void
    ) {
        showRefreshTask?.cancel()
        loadRetryTask?.cancel()

        let serverRequest = makeLoadRequest()

        taskDispatcher.async(on: .background) { [weak self] in
            guard let self else { return }
            // Set the load completion first, it will be called in `callLoadCompletionIfNeeded`.
            self.loadCompletion = completion
            // finish early if ad is loaded and waiting to become visible
            guard !self.visibilityTracker.isTracking else {
                logger.warning("Load ignored for already loaded banner waiting to become visible")
                self.callLoadCompletionIfNeeded(with: nil, request: serverRequest)
                return
            }
            // load a new ad
            self.viewController = viewController
            self.needsToShowOnLoad = true
            self.needsToStopLoadRetryCycle = false
            self.loadAdAndShowIfNeeded(with: serverRequest)
        }
    }

    // MARK: -

    private func loadAdAndShowIfNeeded(with request: AdLoadRequest) {
        // Load through ad controller
        // Note that multiple calls will be ignored by the ad controller if a load is already ongoing
        adController.loadAd(request: request, viewController: viewController) { [weak self] result in
            self?.taskDispatcher.async(on: .background) {
                guard let self else { return }
                // Call completion with result
                // indicates if it's the first load result from a publisher loadAd() call, as against a load triggered due to auto-refresh
                let isFirstLoad = self.loadCompletion != nil
                self.callLoadCompletionIfNeeded(with: result, request: request)
                // Load success: reset load retry count, show ad if needed
                if case .success(let ad) = result.result, let view = ad.partnerAd.inlineView {
                    self.resetLoadRetryCount()
                    // Show the ad if needed. Otherwise the loaded ad remains cached by ad controller and can be accessed later by another
                    // call to loadAd()
                    if !self.needsToStopLoadRetryCycle && self.needsToShowOnLoad {
                        self.needsToShowOnLoad = false
                        self.showAd(ad, bannerView: view, result: result)
                    }
                // Load failure: schedule a load retry if needed
                } else if self.isAutoRefreshEnabled && !self.needsToStopLoadRetryCycle && (self.isBannerContainerVisible || !isFirstLoad) {
                    // We do not schedule a load retry if: autorefresh is not enabled, or clearAd() was called, or the view is not visible
                    // on the first load.
                    // Note that for auto-refresh (non-first) loads the retry task is scheduled but paused immediately if the banner
                    // is not visible (see scheduleLoadRetry()).
                    self.scheduleLoadRetry()
                }
            }
        }
    }

    private func callLoadCompletionIfNeeded(
        with adLoadResult: AdLoadResult?,
        request: AdLoadRequest
    ) {
        guard let completion = loadCompletion else { return }

        let metrics = adLoadResult?.metrics
        let result: ChartboostMediationBannerLoadResult

        switch adLoadResult?.result {
        // If success notify didLoadWinningBid and didLoad
        // The controller can have only one ad loaded at a time. If one was already loaded it completes immediately with success.
        case .success(let ad):
            // When loadAd() exits early because another ad was already loaded, it returns the identifier for
            // the already-completed request, not the one for the request that was passed at the same time as this callback.
            // Thus if an ad is already loaded when the user tries to load an ad, we return the identifier for the
            // request that completed the load, since that is the one we share with backend and partner adapters.
            result = ChartboostMediationBannerLoadResult(
                error: nil,
                loadID: ad.request.loadID,
                metrics: metrics,
                size: ad.adSize,
                winningBidInfo: ad.bidInfo
            )
        // nil means a load request happened when an ad was already loaded but waiting to get shown
        case nil:
            result = ChartboostMediationBannerLoadResult(
                error: nil,
                loadID: request.loadID,
                metrics: metrics,
                // In the case that the banner is loaded but not visible, the banner result is
                // contained in `showingBannerLoadResult`.
                size: try? showingBannerLoadResult?.result.get().adSize,
                winningBidInfo: nil
            )
        // If failure notify didLoad with an error
        case .failure(let loadError):
            result = ChartboostMediationBannerLoadResult(
                error: loadError,
                loadID: request.loadID,
                metrics: metrics,
                size: nil,
                winningBidInfo: nil
            )
        }

        taskDispatcher.async(on: .main) { // all callbacks on main thread
            completion(result)
        }

        // Immediately set the saved load completion to nil. I'm not sure if there's a race
        // condition where setting this after the completion has been called could be an issue, but
        // it seems safer to set it immediately after the callback task has been dispatched.
        self.loadCompletion = nil
    }

    private func showAd(_ ad: LoadedAd, bannerView: UIView, result: AdLoadResult) {
        taskDispatcher.async(on: .main) { [self] in
            // Clean up previously showing ad
            visibilityTracker.stopTracking()
            removeShowingBanner()

            adController.clearShowingAd { [weak self] _ in
                // Show new ad, after the previous ad has been cleared so partners that have trouble displaying multiple ads for the same
                // placement (Vungle) can do so sequentially.
                self?.taskDispatcher.async(on: .main) {
                    self?.showingBannerLoadResult = result
                    self?.layOutBanner(bannerView)
                }
            }
            // Wait until it is visible
            logger.info("Waiting for banner ad with placement \(ad.request.heliumPlacement) to become visible")
            let start = Date()
            visibilityTracker.startTracking(bannerView) { [weak self] in
                self?.taskDispatcher.async(on: .background) {
                    guard let self else { return }
                    logger.debug("Banner ad with placement \(ad.request.heliumPlacement) became visible")
                    // Log metrics
                    _ = self.metrics.logShow(ad: ad, start: start, error: nil)
                    // Mark it as shown so ad controller records impression and allows to load a new ad
                    self.adController.markLoadedAdAsShown()
                    // Schedule auto-refresh
                    if self.isAutoRefreshEnabled {
                        logger.debug("Preloading banner ad with placement \(ad.request.heliumPlacement)")
                        // we pre-load the next ad immediately so there's higher chances it is ready by the time we need to refresh
                        // the banner
                        self.loadAdAndShowIfNeeded(with: self.makeLoadRequest())
                        self.scheduleShowRefresh()
                    }
                }
            }
        }
    }

    private func layOutBanner(_ bannerView: UIView) {
        logger.debug("Adding ad with placement \(request.placement) to banner container")

        delegate?.bannerController(self, displayBannerView: bannerView)
    }

    private func removeShowingBanner() {
        guard case .success(let ad) = showingBannerLoadResult?.result,
              let bannerView = ad.partnerAd.inlineView else {
            return
        }

        logger.debug("Removing ad with placement \(request.placement) from banner container")
        delegate?.bannerController(self, clearBannerView: bannerView)
        self.showingBannerLoadResult = nil
    }

    private func scheduleShowRefresh() {
        showRefreshTask?.cancel()
        let refreshRate = configuration.autoRefreshRate(forPlacement: request.placement)
        logger.info("Auto-refresh scheduled in \(refreshRate)s for banner ad with placement \(request.placement)")
        showRefreshTask = taskDispatcher.async(on: .background, delay: refreshRate) { [weak self] in
            guard let self else { return }
            logger.debug("Auto-refresh fired for banner ad with placement \(self.request.placement)")

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
        logger.debug("Load retry #\(loadRetryCount) scheduled in \(loadRetryDelay)s for banner ad with placement \(request.placement)")
        loadRetryTask = taskDispatcher.async(on: .background, delay: loadRetryDelay) { [weak self] in
            guard let self else { return }
            logger.debug("Load retry #\(self.loadRetryCount) fired for banner ad with placement \(self.request.placement)")
            self.loadAdAndShowIfNeeded(with: self.makeLoadRequest())
        }
        // If the banner is not visible we still schedule the task but we pause it immediately, to
        // align with the current pause state. This way whenever the banner becomes visible again
        // the task will be resumed and the auto-refresh cycle will continue.
        // Note this does not apply to first loads (see loadAd()), since in those cases we want to stop the auto-refresh cycle completely.
        if isLoadRetryTaskPaused {
            loadRetryTask?.pause()
        }
    }

    private func resetLoadRetryCount() {
        loadRetryCount = 0
    }

    private var loadRetryDelay: TimeInterval {
        loadRetryCount < configuration.penaltyLoadRetryCount
            ? configuration.normalLoadRetryRate(forPlacement: request.placement)
            : configuration.penaltyLoadRetryRate
    }

    private var isAutoRefreshEnabled: Bool {
        configuration.autoRefreshRate(forPlacement: request.placement) > 0
    }

    /// Creates a new load request for the ad controller.
    private func makeLoadRequest() -> AdLoadRequest {
        AdLoadRequest(
            adSize: request.size,
            adFormat: (request.size.type == .adaptive ? .adaptiveBanner : .banner),
            keywords: keywords,
            heliumPlacement: request.placement,
            loadID: UUID().uuidString
        )
    }

    private func updatePausedStates() {
        isLoadRetryTaskPaused = (isPaused || !isBannerContainerVisible)
        isShowRefreshTaskPaused = (
            isPaused ||
            !isBannerContainerVisible ||
            !isApplicationActive ||
            isFullscreenAdVisible
        )
    }

    // MARK: - ViewVisibilityObserver

    func viewVisibilityDidChange(to visible: Bool) {
        // If view becomes hidden we stop the refresh and load retry processes, since we don't
        // want ad load requests to happen constantly for an unused banner.
        isBannerContainerVisible = visible
    }

    // MARK: - ApplicationStateObserver

    func applicationDidBecomeActive() {
        isApplicationActive = true
    }

    func applicationWillBecomeInactive() {
        isApplicationActive = false
    }

    // MARK: FullScreenAdShowObserver

    func didShowFullScreenAd() {
        isFullscreenAdVisible = true
    }

    func didCloseFullScreenAd() {
        isFullscreenAdVisible = false
    }

    // MARK: - AdControllerDelegate

    // Events received from AdController which are forwarded to publishers through delegate method calls.
    // All delegate calls are made on the main thread to avoid issues with publishers integrations.

    func didTrackImpression() {
        taskDispatcher.async(on: .main) { [self] in
            delegate?.bannerControllerDidRecordImpression(self)
        }
    }

    func didClick() {
        taskDispatcher.async(on: .main) { [self] in
            delegate?.bannerControllerDidClick(self)
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
