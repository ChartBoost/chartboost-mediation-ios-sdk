// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class TestBannerContainer: UIView {
    override var intrinsicContentSize: CGSize { .init(width: 42, height: 500) }
}

class BannerControllerTests: HeliumTestCase {
    
    lazy var controller: BannerController = {
        let controller = BannerController(
            heliumPlacement: placement,
            adSize: adSize,
            delegate: mocks.bannerDelegate,
            adController: mocks.adController,
            visibilityTracker: mocks.visibilityTracker
        )
        controller.bannerContainer = bannerContainer
        controller.viewVisibilityDidChange(on: bannerContainer, to: true)
        // clear records to ignore the AdController addObserver() call made on InterstitialAd init
        // This is just for convenience so we don't need to think about this call on every test
        mocks.adController.removeAllRecords()
        return controller
    }()
    let placement = "some placement"
    let loadedAdView = UIView()
    lazy var loadedAd = HeliumAd.test(bidInfo: bidInfo, partnerAd: PartnerAdMock(inlineView: loadedAdView))
    let adSize = CGSize(width: 23, height: 42)
    
    let bannerContainer = TestBannerContainer()
    let loadAdError = ChartboostMediationError(code: .loadFailureNoFill)
    var lastLoadAdCompletion: ((Result<HeliumAd, ChartboostMediationError>) -> Void)?
    var lastVisibilityTrackerCompletion: (() -> Void)?
    let viewController = UIViewController()
    let bidInfo = ["ello": "h1234", "fasdp-": ")_O.o-2.dxq2"]
    
    override func setUp() {
        super.setUp()
        // By default disable autorefresh in config
        mocks.bannerControllerConfiguration.setReturnValue(0.0, for: .autoRefreshRate)
    }
    
    // MARK: - Init and Deinit
    
    func testControllerObservesApplicationStateChanges() {
        _ = controller  // access the lazy property just to force its init
        
        XCTAssertMethodCalls(mocks.application, .addObserver, parameters: [controller])
    }
    
    func testControllerObservesFullScreenAdShowChanges() {
        _ = controller  // access the lazy property just to force its init
        
        XCTAssertMethodCalls(mocks.fullScreenAdShowCoordinator, .addObserver, parameters: [controller])
    }
    
    func testAdIsRemovedOnControllerDeinit() {
        autoreleasepool {
            _ = BannerController(
                heliumPlacement: placement,
                adSize: adSize,
                delegate: mocks.bannerDelegate,
                adController: mocks.adController,
                visibilityTracker: mocks.visibilityTracker
            )
            mocks.adController.removeAllRecords() // removing reference to banner controller added as an observer
            mocks.application.removeAllRecords()  // removing reference to banner controller added as an observer
            mocks.fullScreenAdShowCoordinator.removeAllRecords()  // removing reference to banner controller added as an observer
        }
        assertAdControllerClearLoadedAndShowingAd()
    }
    
    // MARK: - ClearAd
    
    func testClearAd() {
        mocks.adController.setReturnValue(true, for: .clearLoadedAd)
        bannerContainer.addSubview(UIView())    // faking a previous banner view already shown
        
        controller.clearAd()
        
        assertVisibleBanner(nil)
        assertAdControllerClearLoadedAndShowingAd()
    }
    
    func testClearAdWithOngoingSuccessfulLoad() {
        mocks.adController.setReturnValue(false, for: .clearLoadedAd)
        mocks.adController.setReturnValue(ChartboostMediationError(code: .invalidateFailureUnknown), for: .clearShowingAd)
        
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        controller.clearAd()
        
        assertVisibleBanner(nil)
        assertAdControllerClearLoadedAndShowingAd()
        
        // finishing the load should call no delegates and not show
        lastLoadAdCompletion?(.success(loadedAd))

        assertNoDelegateCalls()
        assertVisibleBanner(nil)
        assertNoAdControllerCalls()
        assertNoScheduledTask()
    }
    
    func testClearAdWithOngoingFailedLoad() {
        mocks.adController.setReturnValue(false, for: .clearLoadedAd)
        mocks.adController.setReturnValue(ChartboostMediationError(code: .invalidateFailureUnknown), for: .clearShowingAd)
        
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        controller.clearAd()
        
        assertVisibleBanner(nil)
        assertAdControllerClearLoadedAndShowingAd()
        
        // finishing the load should call no delegates and not schedule a retry
        lastLoadAdCompletion?(.failure(loadAdError))

        assertNoDelegateCalls()
        assertVisibleBanner(nil)
        assertNoAdControllerCalls()
        assertNoScheduledTask()
    }
    
    func testClearAdWithShownBannerNotYetVisible() {
        mocks.adController.setReturnValue(true, for: .clearLoadedAd)
        mocks.adController.setReturnValue(ChartboostMediationError(code: .invalidateFailureUnknown), for: .clearShowingAd)
        
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(requestID: loadedAd.request.loadID, error: nil)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // calling clearAd before visibilityTracker fired completion
        controller.clearAd()
        
        assertVisibleBanner(nil)
        assertAdControllerClearLoadedAndShowingAd()
        assertVisibilityTrackerStop()
    }
    
    func testClearAdWithScheduledRefresh() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(requestID: loadedAd.request.loadID, error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
        
        // finishing second load should do nothing since auto-refresh timer hasn't fired yet
        let view2 = UIView()
        let requestID2 = "some_id_2"
        let ad2 = HeliumAd.test(partnerAd: PartnerAdMock(inlineView: view2), request: .test(loadID: requestID2))
        lastLoadAdCompletion?(.success(ad2))
        
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        assertNoAdControllerCalls()
        
        // clearAd should cancel the auto-refresh
        controller.clearAd()
        
        assertVisibleBanner(nil)
        assertAdControllerClearLoadedAndShowingAd()
        assertVisibilityTrackerStop()
        assertRefreshCancelled()
    }
    
    func testClearAdWithScheduledRetry() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertDelegateCall(error: loadAdError)
        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // clearAd should cancel the scheduled retry
        controller.clearAd()
        
        assertVisibleBanner(nil)
        assertAdControllerClearLoadedAndShowingAd()
        assertVisibilityTrackerStop()
        assertRefreshCancelled()
    }
    
    // MARK: - LoadAd without Auto-Refresh
    
    func testLoadAdWithoutAutoRefreshSuccessfullyOneTime() {
        mocks.bannerControllerConfiguration.setReturnValue(0.0, for: .autoRefreshRate)
        
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(requestID: loadedAd.request.loadID, error: nil)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        
        lastVisibilityTrackerCompletion?()
        
        assertNoScheduledTask()
        assertAdControllerMarkedLoadedAdAsShown()
    }
    
    func testLoadAdWithoutAutoRefreshSuccessfullyWhileAnotherLoadIsOngoing() {
        mocks.bannerControllerConfiguration.setReturnValue(0.0, for: .autoRefreshRate)
        
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(requestID: loadedAd.request.loadID, error: nil)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        
        lastVisibilityTrackerCompletion?()
        
        assertNoScheduledTask()
        assertAdControllerMarkedLoadedAdAsShown()
    }
    
    func testLoadAdSuccessfullySeveralTimes() {
        testLoadAdWithoutAutoRefreshSuccessfullyOneTime()
        testLoadAdWithoutAutoRefreshSuccessfullyOneTime()
        testLoadAdWithoutAutoRefreshSuccessfullyOneTime()
    }
    
    func testLoadAdWithoutAutoRefreshFailedOneTime() {
        mocks.bannerControllerConfiguration.setReturnValue(0.0, for: .autoRefreshRate)
        let previouslyShownBanner = bannerContainer.subviews.first
        
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertDelegateCall(error: loadAdError)
        assertVisibleBanner(previouslyShownBanner)
        assertNoAdControllerCalls()
        assertNoScheduledTask()
    }
    
    func testLoadAdWithoutAutoRefreshFailedOneTimeWhileAnotherLoadIsOngoing() {
        mocks.bannerControllerConfiguration.setReturnValue(0.0, for: .autoRefreshRate)
        let previouslyShownBanner = bannerContainer.subviews.first
        
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertDelegateCall(error: loadAdError)
        assertVisibleBanner(previouslyShownBanner)
        assertNoAdControllerCalls()
        assertNoScheduledTask()
    }
    
    func testLoadAdFailedSeveralTimes() {
        testLoadAdWithoutAutoRefreshFailedOneTime()
        testLoadAdWithoutAutoRefreshFailedOneTime()
        testLoadAdWithoutAutoRefreshFailedOneTime()
    }
    
    func testLoadAdSuccessfullyAfterAFailure() {
        testLoadAdWithoutAutoRefreshFailedOneTime()
        testLoadAdWithoutAutoRefreshSuccessfullyOneTime()
    }
    
    func testLoadAdFailedAfterASuccess() {
        testLoadAdWithoutAutoRefreshSuccessfullyOneTime()
        testLoadAdWithoutAutoRefreshFailedOneTime()
    }
    
    func testSeveralLoads() {
        testLoadAdWithoutAutoRefreshFailedOneTime()
        testLoadAdWithoutAutoRefreshSuccessfullyOneTime()
        testLoadAdWithoutAutoRefreshSuccessfullyOneTime()
        testLoadAdWithoutAutoRefreshFailedOneTime()
        testLoadAdWithoutAutoRefreshSuccessfullyOneTime()
        testLoadAdWithoutAutoRefreshFailedOneTime()
        testLoadAdWithoutAutoRefreshFailedOneTime()
        testLoadAdWithoutAutoRefreshFailedOneTime()
        testLoadAdWithoutAutoRefreshSuccessfullyOneTime()
    }
    
    func testSecondLoadGeneratesANewRequestID() {
        mocks.bannerControllerConfiguration.setReturnValue(0.0, for: .autoRefreshRate)
        
        controller.loadAd(with: viewController)

        let firstRequest = mocks.adController.recordedParameters.first?.first as? HeliumAdLoadRequest
        assertAdControllerLoad()    // XCTAssertMethodCalls() call inside removes the mock recorded records

        controller.loadAd(with: viewController)

        let secondRequest = mocks.adController.recordedParameters.first?.first as? HeliumAdLoadRequest
        assertAdControllerLoad()    // XCTAssertMethodCalls() call inside removes the mock recorded records
        
        // check that requestID changed
        XCTAssertNotEqual(firstRequest?.loadID, secondRequest?.loadID)
    }
    
    func testLoadAdWithoutAutoRefreshSuccessfullyWhileVisibilityTrackerIsWaiting() {
        mocks.bannerControllerConfiguration.setReturnValue(0.0, for: .autoRefreshRate)
        mocks.visibilityTracker.isTracking = true

        controller.loadAd(with: viewController)
        
        assertNoAdControllerCalls()
        assertDelegateCall(error: nil, didLoadWinningBidCall: false)
    }
    
    /// Validates that the ad load passes the keywords dictionary on load requests when set by the user.
    func testLoadForwardsKeywordsWhenAvailable() {
        mocks.bannerControllerConfiguration.setReturnValue(0.0, for: .autoRefreshRate)
        
        // Set keywords
        controller.keywords = HeliumKeywords(["hello": "1234"])
        
        // Load
        controller.loadAd(with: viewController)
        
        // Check that controller is called with the expected request keywords
        assertAdControllerLoad(keywords: ["hello": "1234"])
    }
    
    // MARK: - LoadAd with Auto-Refresh

    func testLoadAdWithAutoRefreshSuccessfullyAndNextLoadFinishesBeforeAutoRefresh() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
        
        // finishing second load should do nothing since auto-refresh timer hasn't fired yet
        let view2 = UIView()
        let requestID2 = "some_id_2"
        let ad2 = HeliumAd.test(partnerAd: PartnerAdMock(inlineView: view2), request: .test(loadID: requestID2))
        lastLoadAdCompletion?(.success(ad2))
        
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        assertNoAdControllerCalls()
        
        // fire auto-refresh timer should call load again expecting it to return the same ad
        mocks.taskDispatcher.performDelayedWorkItems()
        assertAdControllerLoad()
        
        // finishing load again should show the second loaded view and starts visibility tracking for it
        lastLoadAdCompletion?(.success(ad2))
                
        assertNoDelegateCalls()
        assertNewBannerLayedOutAndPreviousCleared(for: view2)
        assertVisibilityTrackerStart(for: view2)
        assertNoScheduledTask()
                
        // when view becomes visible we should do a third load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
    }
    
    func testLoadAdAgainSuccessfullyWhenAutoRefreshWasAlreadyScheduledAndBeforeNextLoadFinishes() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(requestID: loadedAd.request.loadID, error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
        
        // finishing second load should do nothing since auto-refresh timer hasn't fired yet
        let view2 = UIView()
        let requestID2 = "some_id_2"
        let ad2 = HeliumAd.test(partnerAd: PartnerAdMock(inlineView: view2), request: .test(loadID: requestID2))
        lastLoadAdCompletion?(.success(ad2))
        
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        assertNoAdControllerCalls()
        
        // load should trigger another adController load, which should finish immediately since we already had a loaded ad, and cancel the refresh task
        controller.loadAd(with: viewController)
        
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        assertAdControllerLoad()
        assertRefreshCancelled()
        
        // fire auto-refresh timer should show the second loaded view and starts visibility tracking for it
        lastLoadAdCompletion?(.success(ad2))
                
        assertDelegateCall(requestID: requestID2, error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: view2)
        assertVisibilityTrackerStart(for: view2)
        assertNoScheduledTask()
                
        // when view becomes visible we should do a third load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
    }
    
    func testLoadAdWithAutoRefreshSuccessfullyAndNextLoadFinishesAfterAutoRefresh() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(requestID: loadedAd.request.loadID, error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
        
        // fire auto-refresh timer should load again (just in case) and trigger a show immediately when the load finishes
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        
        // finishing second load should show immediately
        let view2 = UIView()
        let requestID2 = "some_id_2"
        let ad2 = HeliumAd.test(partnerAd: PartnerAdMock(inlineView: view2), request: .test(loadID: requestID2))
        lastLoadAdCompletion?(.success(ad2))
        
        assertNoDelegateCalls()
        assertNewBannerLayedOutAndPreviousCleared(for: view2)
        assertVisibilityTrackerStart(for: view2)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a third load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
    }
    
    func testLoadAdAgainSuccessfullyWhenAutoRefreshWasAlreadyScheduledAndAfterNextLoadFinishes() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(requestID: loadedAd.request.loadID, error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
        
        // fire auto-refresh timer should load again (just in case) and trigger a show immediately when the load finishes
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        
        // loading again should just make another call to adController and wait until the ongoing load finishes, with only difference that we get another delegate call
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        
        // finishing second load should show immediately
        let view2 = UIView()
        let requestID2 = "some_id_2"
        let ad2 = HeliumAd.test(partnerAd: PartnerAdMock(inlineView: view2), request: .test(loadID: requestID2))
        lastLoadAdCompletion?(.success(ad2))
        
        assertDelegateCall(requestID: requestID2, error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: view2)
        assertVisibilityTrackerStart(for: view2)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a third load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
    }
    
    func testLoadAdAgainSuccessfullyWhenShownBannerWasNotYetVisible() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(requestID: loadedAd.request.loadID, error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // loading ad again before visibility tracker finished
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        
        // finishing second load should show immediately
        let view2 = UIView()
        let requestID2 = "some_id_2"
        let ad2 = HeliumAd.test(partnerAd: PartnerAdMock(inlineView: view2), request: .test(loadID: requestID2))
        lastLoadAdCompletion?(.success(ad2))
        
        assertDelegateCall(requestID: requestID2, error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: view2)
        assertVisibilityTrackerStart(for: view2)    // here we check that stopTracking was called, which should prevent the previous tracker completion from getting fired
        assertNoScheduledTask()
        
        // when view becomes visible we should do a third load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
    }

    func testLoadAdWithAutoRefreshHittingThePenaltyLoadRetryCount() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate) // penaltyLoadRetryCount is 3
        
        // TRY 3 TIMES UNTIL HITTING PENALTY RATE
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertDelegateCall(error: loadAdError)
        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // fire load retry timer should trigger second load
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers another load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertNoDelegateCalls()
        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // fire load retry timer should trigger third load
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // RETRY 2 TIMES WITH PENALTY RATE
        
        // finishing load with error triggers another load retry, this time with penalty rate
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertNoDelegateCalls()
        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: true)
        assertNoAdControllerCalls()
        
        // fire load retry timer should trigger fourth load
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers another load retry, still with penalty rate
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertNoDelegateCalls()
        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: true)
        assertNoAdControllerCalls()
        
        // fire load retry timer should trigger fourth load
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // LOAD WITH SUCCESS

        // Now we finish the load with success
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertNoDelegateCalls()
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
        
        // finishing second load should do nothing since auto-refresh timer hasn't fired yet
        let view2 = UIView()
        let requestID2 = "some_id_2"
        let ad2 = HeliumAd.test(partnerAd: PartnerAdMock(inlineView: view2), request: .test(loadID: requestID2))
        lastLoadAdCompletion?(.success(ad2))
        
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        assertNoAdControllerCalls()
        
        // fire auto-refresh timer should call load again expecting it to return the same ad
        mocks.taskDispatcher.performDelayedWorkItems()
        assertAdControllerLoad()
        
        // finishing load again should show the second loaded view and starts visibility tracking for it
        lastLoadAdCompletion?(.success(ad2))
                
        assertNoDelegateCalls()
        assertNewBannerLayedOutAndPreviousCleared(for: view2)
        assertVisibilityTrackerStart(for: view2)
        assertNoScheduledTask()
                
        // when view becomes visible we should do a third load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
        
        // TRY 3 TIMES UNTIL HITTING PENALTY RATE AGAIN. MAKING SURE THAT RETRY COUNT WAS RESET
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertNoDelegateCalls()
        assertVisibleBanner(view2)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // fire show refresh task, which should do nothing but calling adController load again
        let showRefreshTask = mocks.taskDispatcher.delayedWorkItems.removeFirst()
        showRefreshTask()
        
        assertNoDelegateCalls()
        assertAdControllerLoad()
        assertVisibleBanner(view2)
        
        // fire load retry timer should trigger second load
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers another load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertNoDelegateCalls()
        assertVisibleBanner(view2)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // fire load retry timer should trigger third load
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // RETRY WITH PENALTY RATE. MAKING SURE THAT THE PENALTY COUNT IS SAME AS IN THE FIRST PASS
        
        // finishing load with error triggers another load retry, this time with penalty rate
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertNoDelegateCalls()
        assertVisibleBanner(view2)
        assertScheduledLoadRetry(withPenaltyRate: true)
        assertNoAdControllerCalls()
    }
        
    func testLoadAdWithAutoRefreshResetsTheLoadRetryCountIfASuccessHappensBeforeHittingThePenaltyLimit() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate) // penaltyLoadRetryCount is 3
        
        // TRY 2 TIMES, NOT HITTING PENALTY RATE
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertDelegateCall(error: loadAdError)
        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // fire load retry timer should trigger second load
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // LOAD WITH SUCCESS
        
        // Now we finish the load with success
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertNoDelegateCalls()
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()

        // TRY 2 TIMES, NOT HITTING PENALTY RATE
        
        // first load
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertDelegateCall(error: loadAdError)
        assertVisibleBanner(loadedAdView)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // fire show refresh task, which should do nothing but calling adController load again
        let showRefreshTask = mocks.taskDispatcher.delayedWorkItems.removeFirst()
        showRefreshTask()
        
        assertNoDelegateCalls()
        assertAdControllerLoad()
        assertVisibleBanner(loadedAdView)
        
        // fire load retry timer should trigger second load
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // LOAD WITH SUCCESS
        
        // Now we finish the load with success
        let view2 = UIView()
        let requestID2 = "some_id_2"
        let ad2 = HeliumAd.test(partnerAd: PartnerAdMock(inlineView: view2), request: .test(loadID: requestID2))
        lastLoadAdCompletion?(.success(ad2))
        
        assertNoDelegateCalls()
        assertNewBannerLayedOutAndPreviousCleared(for: view2)
        assertVisibilityTrackerStart(for: view2)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()

        // TRY 3 TIMES UNTIL HITTING PENALTY RATE
        
        // first load
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertDelegateCall(error: loadAdError)
        assertVisibleBanner(view2)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // fire show refresh task, which should do nothing but calling adController load again
        let showRefreshTask2 = mocks.taskDispatcher.delayedWorkItems.removeFirst()
        showRefreshTask2()
        
        assertNoDelegateCalls()
        assertAdControllerLoad()
        assertVisibleBanner(view2)
        
        // fire load retry timer should trigger second load
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers another load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertNoDelegateCalls()
        assertVisibleBanner(view2)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // fire load retry timer should trigger third load
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()
    }
    
    func testLoadAdAgainSuccessfullyWhenLoadRetryWasScheduled() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate) // penaltyLoadRetryCount is 3
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertDelegateCall(error: loadAdError)
        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // load again should force an immediate load and cancel the retry, calling the delegate
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        assertRefreshCancelled()
        
        lastLoadAdCompletion?(.success(loadedAd))

        assertDelegateCall(requestID: loadedAd.request.loadID, error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()

    }
    
    func testLoadAdFailedAgainWhenLoadRetryWasScheduled() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate) // penaltyLoadRetryCount is 3
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertDelegateCall(error: loadAdError)
        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // load again should force an immediate load and cancel the retry, calling the delegate
        controller.loadAd(with: viewController)
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        assertRefreshCancelled()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertDelegateCall(error: loadAdError)
        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
    }
    
    func testAutoRefreshLoadsImmediatelyIfPreLoadFailedAndCancelsPreviouslyScheduledLoadRetry() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        mocks.visibilityTracker.lastCompletion?()

        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
        
        // failing second load (pre-load) should schedule a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view still visible
        assertNoAdControllerCalls()
        assertScheduledLoadRetry(withPenaltyRate: false)
        
        // fire auto-refresh
        mocks.taskDispatcher.delayedWorkItems.first?()
        
        assertLoadRetryCancelled()
        assertAdControllerLoad()    // a new load should start immediately
    }
    
    // MARK: - Scheduled Refresh Pause/Resume
    
    func testRefreshIsPausedWhenAppGoesToBackground() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(requestID: loadedAd.request.loadID, error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()

        // going to background/foreground should pause/resume the refresh
        controller.applicationWillBecomeInactive()
        
        assertRefreshPaused()
        
        controller.applicationDidBecomeActive()
        
        assertRefreshResumed()
    }
    
    func testRefreshIsPausedWhenViewChangesVisibility() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(requestID: loadedAd.request.loadID, error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()

        // changing view visibility should pause/resume the refresh
        controller.viewVisibilityDidChange(on: bannerContainer, to: false)
        
        assertRefreshPaused()
        
        controller.viewVisibilityDidChange(on: bannerContainer, to: true)
        
        assertRefreshResumed()
    }
    
    func testRefreshIsPausedWhenFullScreenAdIsShown() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(requestID: loadedAd.request.loadID, error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        mocks.visibilityTracker.lastCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()

        // showing/closing full-screen ad should pause/resume the refresh
        controller.didShowFullScreenAd()
        
        assertRefreshPaused()
        
        controller.didCloseFullScreenAd()
        
        assertRefreshResumed()
    }
    
    func testSecondLoadDueToAutoRefreshGeneratesANewRequestID() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(requestID: loadedAd.request.loadID, error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        // check that requestID changed
        let params = mocks.adController.recordedParameters.count > 1 ? mocks.adController.recordedParameters[1] : nil
        XCTAssertNotEqual((params?.first as? HeliumAdLoadRequest)?.loadID, loadedAd.request.loadID)
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
    }
    
    // MARK: - Load Failure When Container Is Not Visible
    
    /// Validates that if the banner container is not visible when a first load finishes with failure then no load retry is scheduled and the auto-refresh cycle dies.
    func testAFirstFailedLoadForANonVisibleContainerStopsTheAutoRefreshCycle() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        controller.viewVisibilityDidChange(on: bannerContainer, to: false)
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error should not trigger a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertDelegateCall(error: loadAdError)
        assertVisibleBanner(nil)
        assertNoScheduledTask()
        assertNoAdControllerCalls()
        
        // make container visible just to make sure nothing happens
        controller.viewVisibilityDidChange(on: bannerContainer, to: true)
        
        assertNoScheduledTask()
        assertNoDelegateCalls()
        assertNoAdControllerCalls()
        assertVisibleBanner(nil)
    }
    
    /// Validates that if the banner container is not visible when an auto-refrehs load finishes with failure then a load retry is scheduled but paused until the container becomes visible again.
    func testLoadRetryIsScheduledAndPausedIfContainerIsNotVisibleWhenLoadFinishes() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        controller.loadAd(with: viewController)

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        
        assertDelegateCall(requestID: loadedAd.request.loadID, error: nil, didLoadWinningBidCall: false)
        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        mocks.visibilityTracker.lastCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()

        // fire auto-refresh
        mocks.taskDispatcher.delayedWorkItems.first?()
        mocks.taskDispatcher.returnTask = DispatchTaskMock()  // refresh the mock dispatch task so we get a clean one next time it is scheduled
        
        assertAdControllerLoad()    // a new load should start immediately
        
        // finishing load with error should trigger a load retry and pause it since the container is not visible
        controller.viewVisibilityDidChange(on: bannerContainer, to: false)
        lastLoadAdCompletion?(.failure(loadAdError))
        
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)
        assertNoAdControllerCalls()
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertLoadRetryPaused()
        
        // make container visible should resume the load retry task
        controller.viewVisibilityDidChange(on: bannerContainer, to: true)

        assertLoadRetryResumed()
    }
    
    // MARK: - AdControllerDelegate
    
    /// Validates that the ad forwards the delegate method call.
    func testDidTrackImpression() {
        controller.didTrackImpression()
        
        XCTAssertMethodCalls(mocks.bannerDelegate, .didRecordImpression, parameters: [placement])
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidClick() {
        controller.didClick()
        
        XCTAssertMethodCalls(mocks.bannerDelegate, .didClick, parameters: [placement, nil])
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidReward() {
        controller.didReward()
        
        // Nothing happens, since banners do not support rewards
        XCTAssertNoMethodCalls(mocks.bannerDelegate)
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidDismiss() {
        controller.didDismiss(error: nil)
        
        // Nothing happens, since banners do not support dismissing
        XCTAssertNoMethodCalls(mocks.bannerDelegate)
    }
    
    // MARK: - Metrics
    
    /// Validates that a show event is logged when the ad view becomes visible.
    func testShowEventIsLoggedWhenAdViewBecomesVisible() {
        // Load the ad
        controller.loadAd(with: viewController)
        assertAdControllerLoad()
        lastLoadAdCompletion?(.success(loadedAd))
        assertVisibilityTrackerStart(for: loadedAdView)
        
        // Check that the event was not logged yet
        XCTAssertNoMethodCalls(mocks.metrics)
        
        // Fire the visibility tracker completion
        lastVisibilityTrackerCompletion?()
        
        // Check that the show event was logged with the proper info
        XCTAssertMethodCalls(mocks.metrics, .logShow, parameters: [
            loadedAd.partnerAd.request.auctionIdentifier,
            XCTMethodIgnoredParameter(), // this should be the load ID, but it can't be `loadedAd.request.identifier` because `loadAd()` creates a different request with a different load ID that we don't have reference to
            XCTMethodSomeParameter<MetricsEvent> {
                XCTAssertEqual($0.partnerIdentifier, self.loadedAd.partnerAd.request.partnerIdentifier)
            }
        ])
    }
    
    /// Validates that the show event is not logged if the ad does not become visible.
    func testShowEventIsNotLoggedWhenAdViewDoesNotBecomeVisible() {
        // Load the ad
        controller.loadAd(with: viewController)
        assertAdControllerLoad()
        lastLoadAdCompletion?(.success(loadedAd))
        assertVisibilityTrackerStart(for: loadedAdView)
        
        // Check that the event was not logged
        XCTAssertNoMethodCalls(mocks.metrics)
        
        // Dispose of the ad
        controller.clearAd()
        
        // Check that the event was not logged
        XCTAssertNoMethodCalls(mocks.metrics)
    }
}

// MARK: - Helpers

extension BannerControllerTests {
    
    func expectedLoadRequest(loadID: String = "", keywords: [String: String]?) -> HeliumAdLoadRequest {
        HeliumAdLoadRequest(
            adSize: adSize,
            adFormat: .banner,
            keywords: keywords,
            heliumPlacement: placement,
            loadID: loadID
        )
    }
    
    func assertAdControllerLoad(keywords: [String: String]? = nil) {
        let expectedRequest = expectedLoadRequest(keywords: keywords)
        XCTAssertMethodCalls(mocks.adController, .loadAd, parameters: [
            XCTMethodSomeParameter<HeliumAdLoadRequest> {
                XCTAssertEqual($0.adSize, expectedRequest.adSize)
                XCTAssertEqual($0.adFormat, expectedRequest.adFormat)
                XCTAssertEqual($0.heliumPlacement, expectedRequest.heliumPlacement)
                XCTAssertEqual($0.keywords, expectedRequest.keywords)
                XCTAssertFalse($0.loadID.isEmpty)
            },
            viewController,
            XCTMethodCaptureParameter { (completion: @escaping (AdLoadResult) -> Void) in
                self.lastLoadAdCompletion = { result in completion(AdLoadResult(result: result, metrics: nil)) }
            }
        ])
    }
    
    func assertAdControllerMarkedLoadedAdAsShown() {
        XCTAssertMethodCalls(mocks.adController, .markLoadedAdAsShown)
    }
    
    func assertAdControllerMarkedLoadedAdAsShownAndLoadedNext() {
        XCTAssertMethodCalls(mocks.adController, .markLoadedAdAsShown, .loadAd, parameters:
            [],
            [XCTMethodIgnoredParameter(), viewController, XCTMethodCaptureParameter { (completion: @escaping (AdLoadResult) -> Void) in
                self.lastLoadAdCompletion = { result in completion(AdLoadResult(result: result, metrics: nil)) }
            }]
        )
    }
    
    func assertAdControllerClearLoadedAndShowingAd() {
        XCTAssertMethodCalls(mocks.adController, .clearLoadedAd, .clearShowingAd)
    }
    
    /// nil requestID means to accept any value as valid. In some cases (didLoad failures) the requestID is generated internally and returned,
    /// without passing through any other component, thus any value is valid.
    func assertDelegateCall(requestID: String? = nil, error: ChartboostMediationError?, didLoadWinningBidCall: Bool = true) {
        if let error = error {
            XCTAssertMethodCalls(mocks.bannerDelegate, .didLoad, parameters: [placement, requestID ?? XCTMethodIgnoredParameter(), nil, XCTMethodSomeParameter<ChartboostMediationError> {
                XCTAssertEqual($0.code, error.code)
            }])
        } else if didLoadWinningBidCall {
            XCTAssertMethodCalls(mocks.bannerDelegate, .didLoad, parameters: [placement, requestID ?? XCTMethodIgnoredParameter(), bidInfo, nil])
        } else {
            XCTAssertMethodCalls(mocks.bannerDelegate, .didLoad, parameters: [placement, requestID ?? XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), nil])
        }
    }
    
    func assertNoDelegateCalls() {
        XCTAssertNoMethodCalls(mocks.bannerDelegate)
    }
    
    func assertNoAdControllerCalls() {
        XCTAssertNoMethodCalls(mocks.adController)
    }
    
    func assertNewBannerLayedOutAndPreviousCleared(for view: UIView) {
        XCTAssertEqual(view.frame, CGRect(origin: .zero, size: adSize))
        XCTAssertEqual(bannerContainer.subviews, [view])
        XCTAssertMethodCalls(mocks.adController, .clearShowingAd)
    }
    
    func assertVisibilityTrackerStart(for view: UIView) {
        XCTAssertMethodCalls(mocks.visibilityTracker, .stopTracking, .startTracking, parameters: [], [view, XCTMethodCaptureParameter { self.lastVisibilityTrackerCompletion = $0 }])
    }
    
    func assertVisibilityTrackerStop() {
        XCTAssertMethodCalls(mocks.visibilityTracker, .stopTracking)
    }
    
    func assertNoScheduledTask() {
        XCTAssertNoMethodCalls(mocks.taskDispatcher)
    }
    
    func assertScheduledRefresh() {
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), mocks.bannerControllerConfiguration.returnValue(for: .autoRefreshRate), false])
    }
    
    func assertRefreshCancelled() {
        XCTAssertMethodCalls(mocks.taskDispatcher.returnTask, .cancel)
    }
    
    func assertRefreshPaused() {
        XCTAssertMethodCalls(mocks.taskDispatcher.returnTask, .pause)
    }
    
    func assertRefreshResumed() {
        XCTAssertMethodCalls(mocks.taskDispatcher.returnTask, .resume)
    }
    
    func assertScheduledLoadRetry(withPenaltyRate: Bool) {
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [
            XCTMethodIgnoredParameter(),
            withPenaltyRate ? mocks.bannerControllerConfiguration.penaltyLoadRetryRate : mocks.bannerControllerConfiguration.returnValue(for: .normalLoadRetryRate), false
        ])
    }
    
    func assertLoadRetryCancelled() {
        XCTAssertEqual(mocks.taskDispatcher.returnTask.recordedMethods, [.cancel])
        mocks.taskDispatcher.returnTask.removeAllRecords()
    }
    
    func assertLoadRetryPaused() {
        XCTAssertMethodCalls(mocks.taskDispatcher.returnTask, .pause)
    }
    
    func assertLoadRetryResumed() {
        XCTAssertMethodCalls(mocks.taskDispatcher.returnTask, .resume)
    }
    
    /// If `view` is nil we check that there are no visible banners
    func assertVisibleBanner(_ view: UIView?) {
        XCTAssertEqual(bannerContainer.subviews, view.map { [$0] } ?? [])
    }
}
