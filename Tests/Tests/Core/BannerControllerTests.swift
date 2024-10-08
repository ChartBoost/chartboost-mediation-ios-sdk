// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class BannerControllerTests: ChartboostMediationTestCase {
    
    lazy var controller: BannerController = {
        let controller = BannerController(
            request: .test(placement: placement, size: adSize),
            adController: mocks.adController,
            visibilityTracker: mocks.visibilityTracker
        )
        controller.delegate = mocks.bannerControllerDelegate
        // clear records to ignore the AdController addObserver() call made on InterstitialAd init
        // This is just for convenience so we don't need to think about this call on every test
        mocks.adController.removeAllRecords()
        return controller
    }()
    let placement = "some placement"
    let loadedAdView = UIView()
    lazy var loadedAd = LoadedAd.test(bidInfo: bidInfo, partnerAd: PartnerBannerAdMock(view: loadedAdView))
    var adSize = BannerSize(
        size: CGSize(width: 23, height: 42),
        type: .fixed
    )

    let loadAdError = ChartboostMediationError(code: .loadFailureNoFill)
    var lastLoadAdCompletion: ((Result<LoadedAd, ChartboostMediationError>) -> Void)?
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
                request: .test(placement: placement, size: adSize),
                adController: mocks.adController,
                visibilityTracker: mocks.visibilityTracker
            )
            mocks.adController.removeAllRecords() // removing reference to banner controller added as an observer
            mocks.adController.delegate = nil
            mocks.application.removeAllRecords()  // removing reference to banner controller added as an observer
            mocks.fullScreenAdShowCoordinator.removeAllRecords()  // removing reference to banner controller added as an observer
        }
        assertAdControllerClearLoadedAndShowingAd()
    }
    
    // MARK: - ClearAd
    
    func testClearAdWhenAdIsLoaded() {
        mocks.adController.setReturnValue(true, for: .clearLoadedAd)

        // Load the ad first and ensure we get the displayAd callback.
        let loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })
        assertAdControllerLoad()
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)

        // Clear the ad and ensure we get the clearAd callback.
        controller.clearAd()

        XCTAssertMethodCalls(
            mocks.bannerControllerDelegate,
            .bannerControllerClearBannerView,
            parameters: [controller, loadedAdView]
        )

        assertVisibleBanner(nil)
        assertAdControllerClearLoadedAndShowingAd()
    }

    func testClearAdWithOngoingSuccessfulLoad() {
        mocks.adController.setReturnValue(false, for: .clearLoadedAd)
        mocks.adController.setReturnValue(ChartboostMediationError(code: .invalidateFailureUnknown), for: .clearShowingAd)

        // The completion block should not be called in this case.
        let loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        controller.loadAd(viewController: viewController, completion: { result in
            loadExpectation.fulfill()
        })
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        controller.clearAd()

        assertVisibleBanner(nil)
        assertAdControllerClearLoadedAndShowingAd()
        
        // finishing the load should call no delegates and not show
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

        assertNoDelegateCalls()
        assertVisibleBanner(nil)
        assertNoAdControllerCalls()
        assertNoScheduledTask()
    }

    func testClearAdWithOngoingFailedLoad() {
        mocks.adController.setReturnValue(false, for: .clearLoadedAd)
        mocks.adController.setReturnValue(ChartboostMediationError(code: .invalidateFailureUnknown), for: .clearShowingAd)

        // The completion block should not be called in this case.
        let loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        controller.loadAd(viewController: viewController, completion: { result in
            loadExpectation.fulfill()
        })
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        controller.clearAd()
        
        assertVisibleBanner(nil)
        assertAdControllerClearLoadedAndShowingAd()
        
        // finishing the load should call no delegates and not schedule a retry
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 1.0)

        assertNoDelegateCalls()
        assertVisibleBanner(nil)
        assertNoAdControllerCalls()
        assertNoScheduledTask()
    }
    
    func testClearAdWithShownBannerNotYetVisible() {
        mocks.adController.setReturnValue(true, for: .clearLoadedAd)
        mocks.adController.setReturnValue(ChartboostMediationError(code: .invalidateFailureUnknown), for: .clearShowingAd)

        let loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

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
        let loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)
        
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
        let ad2 = LoadedAd.test(partnerAd: PartnerBannerAdMock(view: view2), request: .test(loadID: requestID2))
        lastLoadAdCompletion?(.success(ad2))
        
        assertNoDelegateCalls()
        XCTAssertIdentical(try? controller.showingBannerAdLoadResult?.result.get().bannerView, loadedAdView) // first view, not view2
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
        let loadExpectation = expectation(description: "Failed load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNotNil(result.error)
            loadExpectation.fulfill()
        })
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 1.0)

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
        let previousView = try? controller.showingBannerAdLoadResult?.result.get().bannerView

        let loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()

        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

        assertNewBannerLayedOutAndPreviousCleared(
            for: loadedAdView,
            previousView: previousView
        )
        assertVisibilityTrackerStart(for: loadedAdView)
        
        lastVisibilityTrackerCompletion?()
        
        assertNoScheduledTask()
        assertAdControllerMarkedLoadedAdAsShown()
    }

    func testLoadAdWithoutAutoRefreshSuccessfullyWhileAnotherLoadIsOngoing() {
        mocks.bannerControllerConfiguration.setReturnValue(0.0, for: .autoRefreshRate)

        // Only the second passed completion block should be called.
        let loadExpectation1 = expectation(description: "Completion should not be called")
        loadExpectation1.isInverted = true
        controller.loadAd(viewController: viewController, completion: { result in
            loadExpectation1.fulfill()
        })
        
        assertAdControllerLoad()
        assertNoDelegateCalls()

        let loadExpectation2 = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation2.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

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
       let previouslyShownBanner = try? controller.showingBannerAdLoadResult?.result.get().bannerView

       let loadExpectation = expectation(description: "Failed load")
       controller.loadAd(viewController: viewController, completion: { result in
          XCTAssertNotNil(result.error)
           loadExpectation.fulfill()
       })

       assertAdControllerLoad()
       assertNoDelegateCalls()

       lastLoadAdCompletion?(.failure(loadAdError))
       waitForExpectations(timeout: 1.0)

       XCTAssertIdentical(try? controller.showingBannerAdLoadResult?.result.get().bannerView, previouslyShownBanner)
       assertNoAdControllerCalls()
       assertNoScheduledTask()
    }

    func testLoadAdWithoutAutoRefreshFailedOneTimeWhileAnotherLoadIsOngoing() {
        mocks.bannerControllerConfiguration.setReturnValue(0.0, for: .autoRefreshRate)
        
        // Only the second passed completion block should be called.
        let loadExpectation1 = expectation(description: "Completion should not be called")
        loadExpectation1.isInverted = true
        controller.loadAd(viewController: viewController, completion: { result in
            loadExpectation1.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        let loadExpectation2 = expectation(description: "Failed load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNotNil(result.error)
            loadExpectation2.fulfill()
        })
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 1.0)

        assertVisibleBanner(nil)
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
        
        controller.loadAd(viewController: viewController, completion: { _ in })

        let firstRequest = mocks.adController.recordedParameters.first?.first as? InternalAdLoadRequest
        assertAdControllerLoad()    // XCTAssertMethodCalls() call inside removes the mock recorded records

        controller.loadAd(viewController: viewController, completion: { _ in })

        let secondRequest = mocks.adController.recordedParameters.first?.first as? InternalAdLoadRequest
        assertAdControllerLoad()    // XCTAssertMethodCalls() call inside removes the mock recorded records
        
        // check that requestID changed
        XCTAssertNotEqual(firstRequest?.loadID, secondRequest?.loadID)
    }
    
    func testLoadAdWithoutAutoRefreshSuccessfullyWhileVisibilityTrackerIsWaiting() {
        mocks.bannerControllerConfiguration.setReturnValue(0.0, for: .autoRefreshRate)
        mocks.visibilityTracker.isTracking = true

        let loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })
        
        assertNoAdControllerCalls()
        waitForExpectations(timeout: 1.0)
    }
    
    /// Validates that the ad load passes the keywords dictionary on load requests when set by the user.
    func testLoadForwardsKeywordsWhenAvailable() {
        mocks.bannerControllerConfiguration.setReturnValue(0.0, for: .autoRefreshRate)
        
        // Set keywords
        controller.keywords = ["hello": "1234"]
        
        // Load
        controller.loadAd(viewController: viewController, completion: { _ in })
        
        // Check that controller is called with the expected request keywords
        assertAdControllerLoad(keywords: ["hello": "1234"])
    }

    func testLoadAdaptiveBannerSendsCorrectAdFormat() {
        mocks.bannerControllerConfiguration.setReturnValue(0.0, for: .autoRefreshRate)
        adSize = .adaptive(width: 400.0)

        controller.loadAd(viewController: viewController, completion: { _ in })

        assertAdControllerLoad(format: .adaptiveBanner)
    }

    // MARK: - LoadAd with Auto-Refresh

    func testLoadAdWithAutoRefreshSuccessfullyAndNextLoadFinishesBeforeAutoRefresh() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        var loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

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
        let ad2 = LoadedAd.test(partnerAd: PartnerBannerAdMock(view: view2), request: .test(loadID: requestID2))

        // Before calling completion, set another load expectation that should not be called.
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.success(ad2))
        waitForExpectations(timeout: 0.1)
        
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        assertNoAdControllerCalls()
        
        // fire auto-refresh timer should call load again expecting it to return the same ad
        mocks.taskDispatcher.performDelayedWorkItems()
        assertAdControllerLoad()
        
        // finishing load again should show the second loaded view and starts visibility tracking for it
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.success(ad2))
        waitForExpectations(timeout: 0.1)

        assertNewBannerLayedOutAndPreviousCleared(for: view2, previousView: loadedAdView)
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
        var loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

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
        let ad2 = LoadedAd.test(partnerAd: PartnerBannerAdMock(view: view2), request: .test(loadID: requestID2))

        // Before calling completion, set another load expectation that should not be called.
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.success(ad2))
        waitForExpectations(timeout: 0.1)
        
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        assertNoAdControllerCalls()
        
        // load should trigger another adController load, which should finish immediately since we already had a loaded ad, and cancel the refresh task
        loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })
        
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        assertAdControllerLoad()
        assertRefreshCancelled()
        
        // fire auto-refresh timer should show the second loaded view and starts visibility tracking for it
        lastLoadAdCompletion?(.success(ad2))
        waitForExpectations(timeout: 1.0)

        assertNewBannerLayedOutAndPreviousCleared(for: view2, previousView: loadedAdView)
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
        var loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

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
        let ad2 = LoadedAd.test(partnerAd: PartnerBannerAdMock(view: view2), request: .test(loadID: requestID2))

        // Before calling completion, set another load expectation that should not be called.
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.success(ad2))
        waitForExpectations(timeout: 0.1)

        assertNewBannerLayedOutAndPreviousCleared(for: view2, previousView: loadedAdView)
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
        var loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

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
        loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        
        // finishing second load should show immediately
        let view2 = UIView()
        let requestID2 = "some_id_2"
        let ad2 = LoadedAd.test(partnerAd: PartnerBannerAdMock(view: view2), request: .test(loadID: requestID2))
        lastLoadAdCompletion?(.success(ad2))
        waitForExpectations(timeout: 1.0)

        assertNewBannerLayedOutAndPreviousCleared(for: view2, previousView: loadedAdView)
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
        var loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // loading ad again before visibility tracker finished
        loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        
        // finishing second load should show immediately
        let view2 = UIView()
        let requestID2 = "some_id_2"
        let ad2 = LoadedAd.test(partnerAd: PartnerBannerAdMock(view: view2), request: .test(loadID: requestID2))
        lastLoadAdCompletion?(.success(ad2))
        waitForExpectations(timeout: 1.0)

        assertNewBannerLayedOutAndPreviousCleared(for: view2, previousView: loadedAdView)
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
        var loadExpectation = expectation(description: "Failed load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNotNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 1.0)

        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // fire load retry timer should trigger second load
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()

        // Before calling completion, set another load expectation that should not be called.
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 0.1)
        
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
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 0.1)
        
        assertNoDelegateCalls()
        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: true)
        assertNoAdControllerCalls()
        
        // fire load retry timer should trigger fourth load
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers another load retry, still with penalty rate
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 0.1)
        
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
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 0.1)

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
        let ad2 = LoadedAd.test(partnerAd: PartnerBannerAdMock(view: view2), request: .test(loadID: requestID2))

        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.success(ad2))
        waitForExpectations(timeout: 0.1)
        
        assertNoDelegateCalls()
        assertVisibleBanner(loadedAdView)   // first view, not view2
        assertNoAdControllerCalls()
        
        // fire auto-refresh timer should call load again expecting it to return the same ad
        mocks.taskDispatcher.performDelayedWorkItems()
        assertAdControllerLoad()
        
        // finishing load again should show the second loaded view and starts visibility tracking for it
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.success(ad2))
        waitForExpectations(timeout: 0.1)

        assertNewBannerLayedOutAndPreviousCleared(for: view2, previousView: loadedAdView)
        assertVisibilityTrackerStart(for: view2)
        assertNoScheduledTask()
                
        // when view becomes visible we should do a third load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
        
        // TRY 3 TIMES UNTIL HITTING PENALTY RATE AGAIN. MAKING SURE THAT RETRY COUNT WAS RESET
        
        // finishing load with error triggers a load retry
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 0.1)
        
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
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 0.1)
        
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
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 0.1)
        
        assertNoDelegateCalls()
        assertVisibleBanner(view2)
        assertScheduledLoadRetry(withPenaltyRate: true)
        assertNoAdControllerCalls()
    }
        
    func testLoadAdWithAutoRefreshResetsTheLoadRetryCountIfASuccessHappensBeforeHittingThePenaltyLimit() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate) // penaltyLoadRetryCount is 3
        
        // TRY 2 TIMES, NOT HITTING PENALTY RATE
        
        // first load
        var loadExpectation = expectation(description: "Failed load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNotNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 1.0)

        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // fire load retry timer should trigger second load
        mocks.taskDispatcher.performDelayedWorkItems()

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // LOAD WITH SUCCESS
        
        // Now we finish the load with success
        // Before calling completion, set another load expectation that should not be called.
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 0.1)

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
        loadExpectation = expectation(description: "Failed load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNotNil(result.error)
            loadExpectation.fulfill()
        })
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 1.0)

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
        let ad2 = LoadedAd.test(partnerAd: PartnerBannerAdMock(view: view2), request: .test(loadID: requestID2))

        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.success(ad2))
        waitForExpectations(timeout: 0.1)

        assertNewBannerLayedOutAndPreviousCleared(for: view2, previousView: loadedAdView)
        assertVisibilityTrackerStart(for: view2)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()

        // TRY 3 TIMES UNTIL HITTING PENALTY RATE
        
        // first load
        loadExpectation = expectation(description: "Failed load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNotNil(result.error)
            loadExpectation.fulfill()
        })
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 1.0)

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
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 0.1)
        
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
        let loadExpectation1 = expectation(description: "Failed load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNotNil(result.error)
            loadExpectation1.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 1.0)

        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // load again should force an immediate load and cancel the retry, calling the delegate
        let loadExpectation2 = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation2.fulfill()
        })
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        assertRefreshCancelled()
        
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

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
        let loadExpectation1 = expectation(description: "Failed load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNotNil(result.error)
            loadExpectation1.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 1.0)

        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
        
        // load again should force an immediate load and cancel the retry, calling the delegate
        let loadExpectation2 = expectation(description: "Failed load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNotNil(result.error)
            loadExpectation2.fulfill()
        })
        
        assertAdControllerLoad()
        assertNoDelegateCalls()
        assertRefreshCancelled()
        
        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 1.0)

        assertVisibleBanner(nil)
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertNoAdControllerCalls()
    }
    
    func testAutoRefreshLoadsImmediatelyIfPreLoadFailedAndCancelsPreviouslyScheduledLoadRetry() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        var loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()

        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
        
        // failing second load (pre-load) should schedule a load retry
        // Before calling completion, set another load expectation that should not be called.
        loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 0.1)
        
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
        let loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

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

    func testRefreshIsPausedWhenFullScreenAdIsShown() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        let loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()

        // showing/closing full-screen ad should pause/resume the refresh
        controller.didShowFullScreenAd()
        
        assertRefreshPaused()
        
        controller.didCloseFullScreenAd()
        
        assertRefreshResumed()
    }

    func testRefreshIsPausedWhenIsPausedIsSet() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)

        // first load
        let loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()

        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()

        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()

        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()

        controller.isPaused = true
        assertRefreshPaused()

        controller.isPaused = false
        assertRefreshResumed()
    }

    func testRefreshIsPausedWhenPausedByMultipleConditionst() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)

        // first load
        let loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()

        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()

        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()

        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()

        // The first condition should pause the timer.
        controller.isPaused = true
        assertRefreshPaused()

        // Second condition.
        controller.didShowFullScreenAd()
        XCTAssertNoMethodCalls(mocks.taskDispatcher.returnTask)

        controller.didCloseFullScreenAd()
        XCTAssertNoMethodCalls(mocks.taskDispatcher.returnTask)

        // Use a different second condition.
        controller.didShowFullScreenAd()
        XCTAssertNoMethodCalls(mocks.taskDispatcher.returnTask)

        controller.didCloseFullScreenAd()
        XCTAssertNoMethodCalls(mocks.taskDispatcher.returnTask)

        // The last condition should unpause the timer.
        controller.isPaused = false
        assertRefreshResumed()
    }
    
    func testSecondLoadDueToAutoRefreshGeneratesANewRequestID() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)
        
        // first load
        let loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()
        
        // finishing load triggers show and starts visibility tracking
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)
        assertNoScheduledTask()
        
        // when view becomes visible we should do a second load, and schedule the show auto-refresh
        lastVisibilityTrackerCompletion?()
        
        // check that requestID changed
        let params = mocks.adController.recordedParameters.count > 1 ? mocks.adController.recordedParameters[1] : nil
        XCTAssertNotEqual((params?.first as? InternalAdLoadRequest)?.loadID, loadedAd.request.loadID)
        assertAdControllerMarkedLoadedAdAsShownAndLoadedNext()
        assertNoDelegateCalls()
        assertScheduledRefresh()
    }

    // MARK: - Load Retry Pause/Resume
    func testLoadRetryTaskIsPausedWhenIsPausedIsSet() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)

        // first load
        let loadExpectation1 = expectation(description: "Failed load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNotNil(result.error)
            loadExpectation1.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()

        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 1.0)

        assertScheduledLoadRetry(withPenaltyRate: false)

        controller.isPaused = true
        assertLoadRetryPaused()

        controller.isPaused = false
        assertLoadRetryResumed()
    }

    func testLoadRetryTaskIsPausedOnCreationIfCompositeStateIsPaused() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)

        // first load
        let loadExpectation1 = expectation(description: "Failed load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNotNil(result.error)
            loadExpectation1.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()

        // Set paused state to true before the load is complete.
        controller.isPaused = true

        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 1.0)

        // The timer should be immediately paused.
        assertScheduledLoadRetry(withPenaltyRate: false)
        assertLoadRetryPaused()

        controller.isPaused = false
        assertLoadRetryResumed()
    }

    func testLoadRetryTaskIsPausedWhenPausedByMultipleConditions() {
        mocks.bannerControllerConfiguration.setReturnValue(42.0, for: .autoRefreshRate)

        // first load
        let loadExpectation1 = expectation(description: "Failed load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNotNil(result.error)
            loadExpectation1.fulfill()
        })

        assertAdControllerLoad()
        assertNoDelegateCalls()

        // finishing load with error triggers a load retry
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 1.0)

        assertScheduledLoadRetry(withPenaltyRate: false)

        controller.isPaused = true
        assertLoadRetryPaused()

        // No calls since the task was already paused.
        XCTAssertNoMethodCalls(mocks.taskDispatcher.returnTask)

        // No calls since the task is still paused by isPaused.
        XCTAssertNoMethodCalls(mocks.taskDispatcher.returnTask)

        controller.isPaused = false
        assertLoadRetryResumed()
    }

    // MARK: - AdControllerDelegate
    
    /// Validates that the ad forwards the delegate method call.
    func testDidTrackImpression() {
        controller.didTrackImpression()
        
        XCTAssertMethodCalls(mocks.bannerControllerDelegate, .bannerControllerDidRecordImpression, parameters: [controller])
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidClick() {
        controller.didClick()
        
        XCTAssertMethodCalls(mocks.bannerControllerDelegate, .bannerControllerDidClick, parameters: [controller])
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidReward() {
        controller.didReward()
        
        // Nothing happens, since banners do not support rewards
        XCTAssertNoMethodCalls(mocks.bannerControllerDelegate)
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidDismiss() {
        controller.didDismiss(error: nil)
        
        // Nothing happens, since banners do not support dismissing
        XCTAssertNoMethodCalls(mocks.bannerControllerDelegate)
    }
    
    // MARK: - Metrics
    
    /// Validates that a show event is logged when the ad view becomes visible.
    func testShowEventIsLoggedWhenAdViewBecomesVisible() {
        // Load the ad
        controller.loadAd(viewController: viewController, completion: { _ in })
        assertAdControllerLoad()
        lastLoadAdCompletion?(.success(loadedAd))
        assertVisibilityTrackerStart(for: loadedAdView)
        
        // Check that the event was not logged yet
        XCTAssertNoMethodCalls(mocks.metrics)
        
        // Fire the visibility tracker completion
        lastVisibilityTrackerCompletion?()
        
        // Check that the show event was logged with the proper info
        XCTAssertMethodCalls(mocks.metrics, .logShow, parameters: [
            loadedAd,
            XCTMethodIgnoredParameter(), // this should be the load ID, but it can't be `loadedAd.request.identifier` because `loadAd()` creates a different request with a different load ID that we don't have reference to
            nil // no error
        ])
    }
    
    /// Validates that the show event is not logged if the ad does not become visible.
    func testShowEventIsNotLoggedWhenAdViewDoesNotBecomeVisible() {
        // Load the ad
        controller.loadAd(viewController: viewController, completion: { _ in })
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

    func testAdLoadResultSize() {
        loadedAd = .test(bannerSize: .adaptive(width: 300, maxHeight: 100))
        let loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertEqual(result.size, .adaptive(width: 300, maxHeight: 100))
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)
    }

    /// Ensure that if an ad has been loaded, but is waiting to become visible, that we will still
    /// return the loaded ad's size in the load result.
    func testAdLoadResultSizeWhenWaitingToBecomeVisible() {
        loadedAd = .test(
            partnerAd: PartnerBannerAdMock(view: loadedAdView),
            bannerSize: .adaptive(width: 300, maxHeight: 100)
        )

        // Load the ad
        var loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.error)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()

        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)

        assertNewBannerLayedOutAndPreviousCleared(for: loadedAdView)
        assertVisibilityTrackerStart(for: loadedAdView)

        mocks.visibilityTracker.isTracking = true

        // Load the ad a second time. Since the ad is not visible yet, this should pull the size
        // from the showing result.
        loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertEqual(result.size, .adaptive(width: 300, maxHeight: 100))
            loadExpectation.fulfill()
        })
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)
    }

    func testAdLoadResultSizeNilOnError() {
        loadedAd = .test(bannerSize: .adaptive(width: 300, maxHeight: 100))
        let loadExpectation = expectation(description: "Failed load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertNil(result.size)
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        lastLoadAdCompletion?(.failure(loadAdError))
        waitForExpectations(timeout: 1.0)
    }

    func testAdLoadResultWinningBidInfo() {
        loadedAd = .test(bidInfo: ["qwert": "5678"], bannerSize: .adaptive(width: 300, maxHeight: 100))
        let loadExpectation = expectation(description: "Successful load")
        controller.loadAd(viewController: viewController, completion: { result in
            XCTAssertAnyEqual(result.winningBidInfo, ["qwert": "5678"])
            loadExpectation.fulfill()
        })

        assertAdControllerLoad()
        lastLoadAdCompletion?(.success(loadedAd))
        waitForExpectations(timeout: 1.0)
    }
}

// MARK: - Helpers

extension BannerControllerTests {
    
    func assertAdControllerLoad(
        format: AdFormat = .banner,
        loadID: String = "",
        keywords: [String: String]? = nil,
        partnerSettings: [String: Any] = [:]
    ) {
        let expectedRequest = InternalAdLoadRequest(
            adSize: adSize,
            adFormat: format,
            keywords: keywords,
            mediationPlacement: placement,
            loadID: loadID,
            partnerSettings: partnerSettings
        )
        XCTAssertMethodCalls(mocks.adController, .loadAd, parameters: [
            XCTMethodSomeParameter<InternalAdLoadRequest> {
                XCTAssertEqual($0.adSize, expectedRequest.adSize)
                XCTAssertEqual($0.adFormat, expectedRequest.adFormat)
                XCTAssertEqual($0.mediationPlacement, expectedRequest.mediationPlacement)
                XCTAssertEqual($0.keywords, expectedRequest.keywords)
                XCTAssertFalse($0.loadID.isEmpty)
                XCTAssertAnyEqual($0.partnerSettings, expectedRequest.partnerSettings)
            },
            viewController,
            XCTMethodCaptureParameter { (completion: @escaping (InternalAdLoadResult) -> Void) in
                self.lastLoadAdCompletion = { result in completion(InternalAdLoadResult(result: result, metrics: nil)) }
            }
        ])
    }
    
    func assertAdControllerMarkedLoadedAdAsShown() {
        XCTAssertMethodCalls(mocks.adController, .markLoadedAdAsShown)
    }
    
    func assertAdControllerMarkedLoadedAdAsShownAndLoadedNext() {
        XCTAssertMethodCalls(mocks.adController, .markLoadedAdAsShown, .loadAd, parameters:
            [],
            [XCTMethodIgnoredParameter(), viewController, XCTMethodCaptureParameter { (completion: @escaping (InternalAdLoadResult) -> Void) in
                self.lastLoadAdCompletion = { result in completion(InternalAdLoadResult(result: result, metrics: nil)) }
            }]
        )
    }
    
    func assertAdControllerClearLoadedAndShowingAd() {
        var clearCompletion: (ChartboostMediationError?) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adController, .clearLoadedAd, .clearShowingAd, parameters: [], [XCTMethodCaptureParameter { clearCompletion = $0 }])
        clearCompletion(nil)
    }
    
    func assertNoDelegateCalls() {
        XCTAssertNoMethodCalls(mocks.bannerControllerDelegate)
    }
    
    func assertNoAdControllerCalls() {
        XCTAssertNoMethodCalls(mocks.adController)
    }

    func assertNewBannerLayedOutAndPreviousCleared(for view: UIView, previousView: UIView? = nil) {
        var clearCompletion: (ChartboostMediationError?) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adController, .clearShowingAd, parameters: [XCTMethodCaptureParameter { clearCompletion = $0 }])
        clearCompletion(nil)

        if let previousView {
           XCTAssertMethodCalls(mocks.bannerControllerDelegate, .bannerControllerClearBannerView, .bannerControllerDisplayBannerView, parameters: [controller, previousView], [controller, view])
        } else {
           XCTAssertMethodCalls(mocks.bannerControllerDelegate, .bannerControllerDisplayBannerView, parameters: [controller, view])
        }
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
        XCTAssertIdentical(view, try? controller.showingBannerAdLoadResult?.result.get().bannerView)
    }
}
