// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class SingleAdStorageAdControllerTests: ChartboostMediationTestCase {

    lazy var adController = SingleAdStorageAdController()

    let heliumPlacement = "some helium placement"
    let viewController = UIViewController()
    
    // MARK: - Load Ad
    
    /// Validates the AdController fails early on loadAd() if Helium hasn't been initialized yet.
    func testLoadAdFailsEarlyWhenHeliumIsNotStarted() {
        // Setup: Helium not started
        mocks.initializationStatusProvider.isInitialized = false
        let expectedLoadResult = InternalAdLoadResult(
            result: .failure(ChartboostMediationError(code: .loadFailureChartboostMediationNotInitialized)),
            metrics: nil
        )
        
        // Load ad
        var completed = false
        adController.loadAd(request: .test(), viewController: viewController) { result in
            // Check result
            XCTAssertAnyEqual(result, expectedLoadResult)
            completed = true
        }
        
        // Check loadAd finished before calling ad repository loadAd()
        XCTAssertTrue(completed)
        XCTAssertNoMethodCalls(mocks.adRepository)
        XCTAssertFalse(adController.isReadyToShowAd)
    }
    
    /// Validates the AdController finishes silently on loadAd() if another load is already ongoing.
    func testLoadAdReturnsSilentlyWhenAlreadyLoading() {
        // Setup: Start an ad load
        mocks.initializationStatusProvider.isInitialized = true
        let firstRequest = InternalAdLoadRequest.test(loadID: "id1")
        let expectedLoadResult = InternalAdLoadResult(
            result: .success(LoadedAd.test(request: firstRequest)),
            metrics: ["hello": 23, "babab": "asdasfd"]
        )
        
        // Load ad
        var completed = false
        adController.loadAd(request: firstRequest, viewController: viewController) { result in
            // Check completion is only called once
            XCTAssertFalse(completed)
            // Check result
            XCTAssertAnyEqual(result, expectedLoadResult)
            completed = true
        }
        
        // Check nothing happened, get hold of the adRepository completion
        XCTAssertFalse(completed)
        XCTAssertFalse(adController.isReadyToShowAd)
        var firstLoadCompletion: (InternalAdLoadResult) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adRepository, .loadAd, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { firstLoadCompletion = $0 }])
        
        // Load ad again
        let secondRequest = InternalAdLoadRequest.test(loadID: "id2")
        adController.loadAd(request: secondRequest, viewController: viewController) { result in
            XCTFail("Should never get called")
        }
        
        // Check nothing happened
        XCTAssertFalse(completed)
        XCTAssertNoMethodCalls(mocks.adRepository)
        
        // Finish first load
        firstLoadCompletion(expectedLoadResult)
        
        // Check loadAd finished
        XCTAssertTrue(completed)
        XCTAssertTrue(adController.isReadyToShowAd)
    }
    
    /// Validates the AdController succeeds early on loadAd() if an ad is already loaded.
    func testLoadAdSucceedsEarlyIfAlreadyLoaded() {
        // Setup: Start and finish an ad load successfully
        mocks.initializationStatusProvider.isInitialized = true
        let firstRequest = InternalAdLoadRequest.test(loadID: "id1")
        let expectedMediationAd = LoadedAd.test(request: firstRequest)
        let expectedLoadResult = InternalAdLoadResult(
            result: .success(expectedMediationAd),
            metrics: nil
        )
        setUpAdControllerWithLoadedAd(expectedMediationAd)
        
        // Load ad again
        var completed = false
        let secondRequest = InternalAdLoadRequest.test(loadID: "id2")
        adController.loadAd(request: secondRequest, viewController: viewController) { result in
            // Check result has same info as in first load
            XCTAssertAnyEqual(result, expectedLoadResult)
            completed = true
        }
        
        // Check second loadAd finished without calling ad repository loadAd()
        XCTAssertTrue(completed)
        XCTAssertNoMethodCalls(mocks.adRepository)
        XCTAssertTrue(adController.isReadyToShowAd)
    }
    
    /// Validates the AdController finishes successfully on loadAd() if the AdRepository succeeds in returning an ad.
    func testLoadAdSucceedsIfAdRepositorySucceeds() {
        // Setup: start
        mocks.initializationStatusProvider.isInitialized = true
        let request = InternalAdLoadRequest.test(loadID: "id1")
        let expectedLoadResult = InternalAdLoadResult(
            result: .success(LoadedAd.test(request: request)),
            metrics: ["hello": 23, "babab": "asdasfd"]
        )
        
        // Load ad
        var completed = false
        adController.loadAd(request: request, viewController: viewController) { result in
            // Check result
            XCTAssertAnyEqual(result, expectedLoadResult)
            completed = true
        }
        
        // Check nothing happened yet, AdRepository is loading
        XCTAssertFalse(completed)
        var firstLoadCompletion: (InternalAdLoadResult) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adRepository, .loadAd, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { firstLoadCompletion = $0 }])

        // Finish AdRepository load
        firstLoadCompletion(expectedLoadResult)
        
        // Check loadAd finished successfully
        XCTAssertTrue(completed)
        XCTAssertTrue(adController.isReadyToShowAd)
    }

    func testLoadAdMultipleTimesReturnsSameResult() {
        // Setup: start
        mocks.initializationStatusProvider.isInitialized = true
        let request = InternalAdLoadRequest.test(loadID: "id1")
        let expectedLoadResult = InternalAdLoadResult(
            result: .success(LoadedAd.test(request: request)),
            metrics: ["hello": 23, "babab": "asdasfd"]
        )

        // Load ad
        let loadExpectation1 = expectation(description: "Successful load")
        adController.loadAd(request: request, viewController: viewController) { result in
            // Check result
            XCTAssertAnyEqual(result, expectedLoadResult)
            loadExpectation1.fulfill()
        }

        var completion: (InternalAdLoadResult) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adRepository, .loadAd, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { completion = $0 }])

        // Finish AdRepository load
        completion(expectedLoadResult)
        waitForExpectations(timeout: 1.0)

        // Load ad the second time, the result should be the same.
        let loadExpectation2 = expectation(description: "Successful load")
        adController.loadAd(request: request, viewController: viewController) { result in
            // Check result
            XCTAssertAnyEqual(result, expectedLoadResult)
            loadExpectation2.fulfill()
        }

        // We don't need to call the completion since it returns immediately when the ad is cached.
        waitForExpectations(timeout: 1.0)
    }
    
    /// Validates the AdController finishes with failure on loadAd() if the AdRepository fails in returning an ad.
    func testLoadAdFailsIfAdRepositoryFails() {
        // Setup: start
        mocks.initializationStatusProvider.isInitialized = true
        let expectedLoadResult = InternalAdLoadResult(
            result: .failure(ChartboostMediationError(code: .loadFailureUnknown)),
            metrics: ["hello": 23, "babab": "asdasfd"]
        )
        
        // Load ad
        var completed = false
        adController.loadAd(request: .test(), viewController: viewController) { result in
            // Check result
            XCTAssertAnyEqual(result, expectedLoadResult)
            completed = true
        }
        
        // Check nothing happened yet, AdRepository is loading
        XCTAssertFalse(completed)
        var firstLoadCompletion: (InternalAdLoadResult) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adRepository, .loadAd, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { firstLoadCompletion = $0 }])

        // Finish AdRepository load
        firstLoadCompletion(expectedLoadResult)
        
        // Check loadAd finished with failure
        XCTAssertTrue(completed)
        XCTAssertFalse(adController.isReadyToShowAd)
    }
    
    // MARK: - Clear Loaded Ad
    
    /// Validates that AdController finishes with failure on clearLoadedAd() if no ad was loaded.
    func testClearLoadedAdFailsIfNoLoadedAd() {
        // Setup: start
        mocks.initializationStatusProvider.isInitialized = true
        
        // Clear loaded ad
        adController.clearLoadedAd()
        
        // Check clearLoadedAd finished with failure
        XCTAssertFalse(adController.isReadyToShowAd)
        XCTAssertNoMethodCalls(mocks.partnerController)
    }
    
    /// Validates that AdController finishes with success on clearLoadedAd() if an ad was loaded.
    func testClearLoadedAdSucceedsIfLoadedAd() {
        // Setup: load ad
        let ad = LoadedAd.test()
        setUpAdControllerWithLoadedAd(ad)
        
        // Clear loaded ad
        adController.clearLoadedAd()
        
        // Check that clearLoadedAd finished with success
        XCTAssertFalse(adController.isReadyToShowAd)
        XCTAssertMethodCalls(mocks.partnerController, .routeInvalidate, parameters: [ad.partnerAd, XCTMethodIgnoredParameter()])
    }
    
    /// Validates that AdController can load a new ad after clearing a previously loaded ad.
    func testLoadAdSucceedsAfterClearLoadedAd() {
        // Setup: load ad
        setUpAdControllerWithLoadedAd()
        
        // Clear loaded ad
        adController.clearLoadedAd()
        XCTAssertMethodCalls(mocks.partnerController, .routeInvalidate, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter()])
        
        // Load another ad
        setUpAdControllerWithLoadedAd()
    }
    
    // MARK: - Clear Showing Ad
    
    /// Validates that AdController finishes with failure on clearShowingAd() if no ad was showing.
    func testClearShowingAdFailsIfNoShowingAd() {
        // Setup: start
        mocks.initializationStatusProvider.isInitialized = true
        
        // Clear loaded ad
        var completed = false
        adController.clearShowingAd { error in
            XCTAssertNil(error)
            completed = true
        }
        
        // Check clearShowingAd finished with failure
        XCTAssertTrue(completed)
        XCTAssertNoMethodCalls(mocks.partnerController)
    }
    
    /// Validates that AdController finishes with success on clearShowingAd() if an ad was showing.
    func testClearShowingAdSucceedsIfPartnerSucceeds() {
        // Setup: load ad
        let ad = LoadedAd.test()
        setUpAdControllerWithLoadedAd(ad)
        setUpAdControllerWithShowingAd(ad)
        
        // Clear showing ad
        var completed = false
        adController.clearShowingAd { error in
            XCTAssertNil(error)
            completed = true
        }
        
        // Make partner controller finish
        var completion: (ChartboostMediationError?) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeInvalidate, parameters: [ad.partnerAd, XCTMethodCaptureParameter { completion = $0 }])
        XCTAssertFalse(completed)
        completion(nil)
        
        // Check that clearShowingAd finished with success
        XCTAssertTrue(completed)
    }
    
    /// Validates that AdController can show a new ad after clearing a previously showing ad.
    func testShowAdSucceedsAfterClearShowingAd() {
        // Setup: load ad and show it
        let ad = LoadedAd.test()
        setUpAdControllerWithLoadedAd(ad)
        setUpAdControllerWithShowingAd(ad)
        let secondAd = LoadedAd.test()
        setUpAdControllerWithLoadedAd(secondAd)
        
        // Clear showing ad
        adController.clearShowingAd { error in
            XCTAssertNil(error)
        }
        mocks.partnerController.removeAllRecords()    // ignoring the routeInvalidate() call so we can focus on what happens when showing the ad below
        
        // Show another ad
        setUpAdControllerWithShowingAd(secondAd)
    }
    
    // MARK: - Show Ad
    
    /// Validates the AdController fails early on showAd() if an ad was not previously loaded.
    func testShowAdFailsEarlyIfNoLoadedAd() {
        // Setup: no loaded ad
        mocks.initializationStatusProvider.isInitialized = false
        let expectedShowResult = InternalAdShowResult(
            error: ChartboostMediationError(code: .showFailureAdNotReady),
            metrics: nil
        )
        
        // Show ad
        var completed = false
        adController.showAd(viewController: viewController) { result in
            XCTAssertAnyEqual(result, expectedShowResult)
            completed = true
        }
        
        // Check showAd finished before calling PartnerController routeShow()
        XCTAssertTrue(completed)
        XCTAssertNoMethodCalls(mocks.partnerController)
        XCTAssertFalse(adController.isReadyToShowAd)
    }
    
    /// Validates the AdController succeeds on showAd() if the PartnerController succeeds on showing the ad.
    func testShowAdSucceedsIfPartnerControllerSucceeds() {
        // Setup: a loaded interstitial ad
        mocks.initializationStatusProvider.isInitialized = false
        let ad = LoadedAd.test()
        setUpAdControllerWithLoadedAd(ad)
        adController.delegate = mocks.adControllerDelegate
        let expectedShowResult = InternalAdShowResult(
            error: nil,
            metrics: ["hello": 23, "babab": "asdasfd"]
        )
        mocks.metrics.setReturnValue(expectedShowResult.metrics, for: .logShow)
        
        // Show ad
        var completed = false
        adController.showAd(viewController: viewController) { result in
            XCTAssertAnyEqual(result, expectedShowResult)
            completed = true
        }
        
        // Check we are waiting for PartnerController to finish
        XCTAssertFalse(completed)
        var showCompletion: (ChartboostMediationError?) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeShow, parameters: [ad.partnerAd, viewController, XCTMethodCaptureParameter { showCompletion = $0 }])
        
        // Finish PartnerController show with success
        showCompletion(nil)
        
        // Check showAd finished successfully
        XCTAssertTrue(completed)
        XCTAssertNoMethodCalls(mocks.partnerController)
        XCTAssertFalse(adController.isReadyToShowAd)
        // Check timeout task was cancelled
        XCTAssertMethodCalls(mocks.taskDispatcher.returnTask, .cancel)
        // Check impression is logged and delegate method called
        XCTAssertMethodCalls(mocks.metrics, .logShow, .logMediationImpression, parameters: [
            ad,
            XCTMethodIgnoredParameter(),    // start date
            nil // error
        ], [
            ad
        ])
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didTrackImpression)
        XCTAssertMethodCalls(mocks.fullScreenAdShowObserver, .didShowFullScreenAd)
        XCTAssertMethodCalls(mocks.impressionTracker, .trackImpression, parameters: [ad.request.adFormat])
    }
    
    /// Validates the AdController fails on showAd() if the PartnerController fails on showing the ad.
    func testShowAdFailsIfPartnerControllerFails() {
        // Setup: a loaded interstitial ad
        mocks.initializationStatusProvider.isInitialized = false
        let ad = LoadedAd.test()
        setUpAdControllerWithLoadedAd(ad)
        adController.delegate = mocks.adControllerDelegate
        let expectedShowResult = InternalAdShowResult(
            error: ChartboostMediationError(code: .partnerError),
            metrics: ["hello": 23, "babab": "asdasfd"]
        )
        mocks.metrics.setReturnValue(expectedShowResult.metrics, for: .logShow)
        
        // Show ad
        var completed = false
        adController.showAd(viewController: viewController) { result in
            XCTAssertAnyEqual(result, expectedShowResult)
            completed = true
        }
        
        // Check we are waiting for PartnerController to finish
        XCTAssertFalse(completed)
        var showCompletion: (ChartboostMediationError?) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeShow, parameters: [ad.partnerAd, viewController, XCTMethodCaptureParameter { showCompletion = $0 }])
        
        // Finish PartnerController show with success
        showCompletion(ChartboostMediationError(code: .partnerError))
        
        // Check showAd finished with failure
        XCTAssertTrue(completed)
        XCTAssertMethodCalls(mocks.partnerController, .routeInvalidate, parameters: [ad.partnerAd, XCTMethodIgnoredParameter()])
        XCTAssertFalse(adController.isReadyToShowAd)
        // Check timeout task was cancelled
        XCTAssertMethodCalls(mocks.taskDispatcher.returnTask, .cancel)
        // Check impression is no logged and delegate method not called
        XCTAssertMethodCalls(mocks.metrics, .logShow, parameters: [
            ad,
            XCTMethodIgnoredParameter(),    // start date
            XCTMethodSomeParameter<ChartboostMediationError> {
                XCTAssertEqual($0.chartboostMediationCode, .partnerError)
            }
        ])
        XCTAssertNoMethodCalls(mocks.adControllerDelegate)
        XCTAssertNoMethodCalls(mocks.fullScreenAdShowObserver)
        XCTAssertNoMethodCalls(mocks.impressionTracker)
    }
    
    /// Validates the AdController can load a new ad after showing the previous one.
    func testLoadAdSucceedsAfterShowingAnAd() {
        setUpAdControllerWithLoadedAd()
        setUpAdControllerWithShowingAd()
        setUpAdControllerWithLoadedAd()
    }
    
    /// Validates the AdController posts an ILRD event on showAd() if successful.
    func testShowAdPostsILRDEvent() {
        // Setup: a loaded interstitial ad
        mocks.initializationStatusProvider.isInitialized = false
        let ilrd = ["?": "sasdf", "2": "3"]
        let ad = LoadedAd.test(ilrd: ilrd)
        setUpAdControllerWithLoadedAd(ad)
        
        // Show ad
        adController.showAd(viewController: viewController) { _ in }
        
        // Finish PartnerController show with success
        var showCompletion: (ChartboostMediationError?) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeShow, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { showCompletion = $0 }])
        showCompletion(nil)
        
        // Check ILRD event is posted
        XCTAssertMethodCalls(mocks.ilrdEventPublisher, .postILRDEvent, parameters: [ad.request.mediationPlacement, ilrd])
    }
    
    /// Validates the AdController fails on showAd() if the PartnerController does not finish showing the ad on a timely manner.
    func testShowAdFailsIfPartnerControllerTimesOut() {
        // Setup: a loaded interstitial ad
        let ad = LoadedAd.test()
        setUpAdControllerWithLoadedAd(ad)
        adController.delegate = mocks.adControllerDelegate
        let expectedShowResult = InternalAdShowResult(
            error: ChartboostMediationError(code: .showFailureTimeout),
            metrics: ["hello": 23, "babab": "asdasfd"]
        )
        mocks.metrics.setReturnValue(expectedShowResult.metrics, for: .logShow)
        
        // Show ad
        var completed = false
        adController.showAd(viewController: viewController) { result in
            XCTAssertAnyEqual(result, expectedShowResult)
            completed = true
        }
        
        // Check we are waiting for PartnerController to finish
        XCTAssertFalse(completed)
        var showCompletion: (ChartboostMediationError?) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeShow, parameters: [ad.partnerAd, viewController, XCTMethodCaptureParameter { showCompletion = $0 }])
        // Check a timeout task was scheduled
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), mocks.adControllerConfiguration.showTimeout, false])    // params: thread, delay, repeats
        
        // Fire the timeout task immediately
        mocks.taskDispatcher.performDelayedWorkItems()
        mocks.taskDispatcher.returnTask.state = .complete
        
        // Check showAd finished with failure
        XCTAssertTrue(completed)
        XCTAssertMethodCalls(mocks.partnerController, .routeInvalidate, parameters: [ad.partnerAd, XCTMethodIgnoredParameter()])
        XCTAssertFalse(adController.isReadyToShowAd)
        // Check impression is not logged and delegate method not called
        XCTAssertMethodCalls(mocks.metrics, .logShow, parameters: [
            ad,
            XCTMethodIgnoredParameter(),    // start date
            XCTMethodSomeParameter<ChartboostMediationError> {
                XCTAssertEqual($0.chartboostMediationCode, .showFailureTimeout)
            }
        ])
        XCTAssertNoMethodCalls(mocks.adControllerDelegate)
        XCTAssertNoMethodCalls(mocks.fullScreenAdShowObserver)
        XCTAssertNoMethodCalls(mocks.impressionTracker)
        
        // Finish PartnerController show with success to check that nothing happens
        completed = false
        showCompletion(ChartboostMediationError(code: .partnerError))
        
        // Check that the late show completion is ignored
        XCTAssertFalse(completed)
        XCTAssertNoMethodCalls(mocks.partnerController)
        XCTAssertNoMethodCalls(mocks.metrics)
        XCTAssertNoMethodCalls(mocks.adControllerDelegate)
        XCTAssertNoMethodCalls(mocks.fullScreenAdShowObserver)
        XCTAssertNoMethodCalls(mocks.impressionTracker)
    }
    
    // MARK: - Mark Loaded Ad as Visible
    
    /// Validates the AdController records an impression on markLoadAdAsShown()
    func testMarkLoadAdAsShown() {
        // Setup: a loaded banner ad
        mocks.initializationStatusProvider.isInitialized = true
        let ad = LoadedAd.test(request: .test(adFormat: .banner))
        setUpAdControllerWithLoadedAd(ad)
        adController.delegate = mocks.adControllerDelegate
        
        // Show ad
        adController.markLoadedAdAsShown()
        
        // Check impression is logged and delegate method called
        XCTAssertMethodCalls(mocks.metrics, .logMediationImpression, parameters: [ad])
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didTrackImpression)
        XCTAssertNoMethodCalls(mocks.fullScreenAdShowObserver)
        XCTAssertMethodCalls(mocks.impressionTracker, .trackImpression, parameters: [ad.request.adFormat])
        XCTAssertFalse(adController.isReadyToShowAd)
    }

    func testMarkLoadAdAsShownAdaptiveBanner() {
        // Setup: a loaded adaptive banner ad
        mocks.initializationStatusProvider.isInitialized = true
        let ad = LoadedAd.test(request: .test(adFormat: .adaptiveBanner))
        setUpAdControllerWithLoadedAd(ad)
        adController.delegate = mocks.adControllerDelegate

        // Show ad
        adController.markLoadedAdAsShown()

        // Check impression is logged and delegate method called
        XCTAssertMethodCalls(mocks.metrics, .logMediationImpression, parameters: [ad])
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didTrackImpression)
        XCTAssertNoMethodCalls(mocks.fullScreenAdShowObserver)
        XCTAssertMethodCalls(mocks.impressionTracker, .trackImpression, parameters: [ad.request.adFormat])
        XCTAssertFalse(adController.isReadyToShowAd)
    }
    
    /// Validates the AdController can load a new ad after showing the previous one.
    func testLoadAdSucceedsAfterMarkingLoadAdAsShown() {
        // Load ad and mark it as shown
        testMarkLoadAdAsShown()
        // Load another ad and check that all goes as expected
        setUpAdControllerWithLoadedAd()
    }

    // MARK: - Force Internal Ad Expiration

    /// Validates the AdController logs an expiration event and makes the proper callbacks when the expiration method is called.
    func testForceInternalAdExpirationWithLoadedAd() {
        // Setup: a loaded banner ad
        mocks.initializationStatusProvider.isInitialized = true
        let ad = LoadedAd.test(request: .test(adFormat: .banner))
        setUpAdControllerWithLoadedAd(ad)
        adController.delegate = mocks.adControllerDelegate

        // Expire ad
        adController.forceInternalExpiration()

        // Check delegate method is called
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didExpire)
        // Check metrics are logged
        XCTAssertMethodCalls(mocks.metrics, .logExpiration, parameters: [ad.partnerAd])
    }

    /// Validates that nothing happens if the expiration method is called with no loaded ad.
    func testForceInternalAdExpirationWithoutLoadedAd() {
        // Expire ad
        adController.forceInternalExpiration()

        // Check no delegate method is called
        XCTAssertNoMethodCalls(mocks.adControllerDelegate)
        // Check no metrics are logged
        XCTAssertNoMethodCalls(mocks.metrics)
    }

    // MARK: - PartnerAdDelegate
    
    /// Validates that AdController handles a didTrackImpression event properly
    func testDidTrackImpression() {
        // Setup
        adController.delegate = mocks.adControllerDelegate
        
        // Call didTrackImpression
        let ad = PartnerFullscreenAdMock()
        adController.didTrackImpression(ad)
        
        // Check impression is logged
        XCTAssertMethodCalls(mocks.metrics, .logPartnerImpression, parameters: [ad])
    }
    
    /// Validates that AdController handles a didClick event properly
    func testDidClick() {
        // Setup
        adController.delegate = mocks.adControllerDelegate
        
        // Call didClick
        let ad = PartnerFullscreenAdMock()
        adController.didClick(ad)
        
        // Check delegate method is called
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didClick)
        // Check metrics are logged
        XCTAssertMethodCalls(mocks.metrics, .logClick, parameters: [ad])
    }
    
    /// Validates that AdController handles a didReward event properly
    func testDidReward() {
        // Setup
        adController.delegate = mocks.adControllerDelegate
        
        // Call didReward
        let ad = PartnerFullscreenAdMock()
        adController.didReward(ad)
        
        // Check delegate method is called
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didReward, parameters: [])
        // Check that reward is tracked
        XCTAssertMethodCalls(mocks.metrics, .logReward, parameters: [ad])
    }
    
    /// Validates that AdController sends a rewarded callback if available on didReward
    func testDidRewardSendsRewardedCallback() {
        // Setup
        adController.delegate = mocks.adControllerDelegate
        adController.customData = "some data"
        let rewardedCallback = RewardedCallback.test()
        let mediationAd = LoadedAd.test(rewardedCallback: rewardedCallback)
        setUpAdControllerWithLoadedAd(mediationAd)
        setUpAdControllerWithShowingAd(mediationAd)

        // Call didReward
        adController.didReward(mediationAd.partnerAd)

        // Check delegate method is called
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didReward, parameters: [])
        // Check that reward is tracked passing the callback and the customData
        XCTAssertMethodCalls(mocks.metrics, .logReward, .logRewardedCallback, parameters: [mediationAd.partnerAd], [rewardedCallback, "some data"])
    }
    
    /// Validates that AdController handles a didDismiss event properly when no error
    func testDidDismissWithNoError() {
        // Setup
        adController.delegate = mocks.adControllerDelegate
        
        // Call didDismiss
        let ad = PartnerFullscreenAdMock(request: .test(adFormat: .interstitial))
        adController.didDismiss(ad, error: nil)
        
        // Check delegate method is called
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didDismiss, parameters: [nil])
        // Check that fullscreen observer is notified since this is a full-screen ad
        XCTAssertMethodCalls(mocks.fullScreenAdShowObserver, .didCloseFullScreenAd)
        // Check partner ad is invalidated
        XCTAssertMethodCalls(mocks.partnerController, .routeInvalidate, parameters: [ad, XCTMethodIgnoredParameter()])
    }
    
    /// Validates that AdController handles a didDismiss event properly with error
    func testDidDismissWithError() {
        // Setup
        adController.delegate = mocks.adControllerDelegate
        
        // Call didDismiss
        let ad = PartnerBannerAdMock(request: .test(adFormat: .banner))
        let error = ChartboostMediationError(code: .partnerError)
        adController.didDismiss(ad, error: error)
        
        // Check delegate method is called
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didDismiss, parameters: [error])
        // Check that fullscreen observer is not notified since this is not a full-screen ad
        XCTAssertNoMethodCalls(mocks.fullScreenAdShowObserver)
        // Check partner ad is invalidated
        XCTAssertMethodCalls(mocks.partnerController, .routeInvalidate, parameters: [ad, XCTMethodIgnoredParameter()])
    }
    
    /// Validates that AdController can show a new ad after the previous one has been dismissed.
    func testShowAdSucceedsAfterDismiss() {
        // Setup
        let ad = LoadedAd.test()
        setUpAdControllerWithLoadedAd(ad)
        setUpAdControllerWithShowingAd(ad)
        let ad2 = LoadedAd.test()
        setUpAdControllerWithLoadedAd(ad2)
        
        // Call didDismiss
        adController.didDismiss(ad.partnerAd, error: nil)
        mocks.partnerController.removeAllRecords()    // clean up recorded methods to ignore the routeInvalidate() call triggered on dismiss
        
        // Show the second ad
        setUpAdControllerWithShowingAd(ad2)
    }
    
    /// Validates that AdController handles a didExpire event properly.
    func testDidExpire() {
        // Setup
        adController.delegate = mocks.adControllerDelegate
        
        // Call didClick
        let ad = PartnerFullscreenAdMock()
        adController.didExpire(ad)
        
        // Check delegate method is called
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didExpire)
        // Check metrics are logged
        XCTAssertMethodCalls(mocks.metrics, .logExpiration, parameters: [ad])
    }
    
    // MARK: - Deinit
    
    /// Validates that AdController invalidates a loaded ad when it is deallocated to avoid memory leaks.
    func testLoadedAdIsInvalidatedOnDeinit() {
        // Setup
        mocks.initializationStatusProvider.isInitialized = true
        let loadedAd = LoadedAd.test()
        
        autoreleasepool {
            // Instantiate controller inside an autoreleasepool so it gets deallocated at the end of its scope
            let controller = SingleAdStorageAdController()
            
            // Load ad
            controller.loadAd(request: .test(), viewController: viewController) { _ in }
            
            // Finish AdRepository load
            var loadCompletion: (InternalAdLoadResult) -> Void = { _ in }
            XCTAssertMethodCalls(mocks.adRepository, .loadAd, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { loadCompletion = $0 }])
            loadCompletion(InternalAdLoadResult(result: .success(loadedAd), metrics: nil))
            
            // Remove records so we can easily check for the routeInvalidate call below
            mocks.partnerController.removeAllRecords()
        }
        
        // Check that the ad got invalidated on deinit
        XCTAssertMethodCalls(mocks.partnerController, .routeInvalidate, parameters: [loadedAd.partnerAd, XCTMethodIgnoredParameter()])
    }

    // MARK: - BannerSize
    func testLoadSucceedsWithValidBannerSize() {
        mocks.initializationStatusProvider.isInitialized = true
        let firstRequest = InternalAdLoadRequest.test(adSize: .adaptive(width: 50, maxHeight: 50), loadID: "id1")
        let expectedLoadResult = InternalAdLoadResult(
            result: .success(LoadedAd.test(request: firstRequest)),
            metrics: ["hello": 23, "babab": "asdasfd"]
        )

        let loadExpectation = expectation(description: "Successful load")
        adController.loadAd(request: firstRequest, viewController: viewController) { result in
            XCTAssertAnyEqual(result, expectedLoadResult)
            loadExpectation.fulfill()
        }

        var completion: (InternalAdLoadResult) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adRepository, .loadAd, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { completion = $0 }])
        completion(expectedLoadResult)
        waitForExpectations(timeout: 1.0)
    }

    func testLoadFailsWithInvalidAdSize() {
        mocks.initializationStatusProvider.isInitialized = true
        let firstRequest = InternalAdLoadRequest.test(adSize: .adaptive(width: 0), loadID: "id1")
        let expectedLoadResult = InternalAdLoadResult(
            result: .failure(.init(code: .loadFailureInvalidBannerSize)),
            metrics: nil
        )

        let loadExpectation = expectation(description: "Failed load")
        adController.loadAd(request: firstRequest, viewController: viewController) { result in
            XCTAssertAnyEqual(result, expectedLoadResult)
            loadExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // No calls should be made to the adRepository in this case.
        XCTAssertNoMethodCalls(mocks.adRepository)
    }
}

// MARK: - Helpers

extension SingleAdStorageAdControllerTests {
    
    /// Convenience method to put the AdController in a state where it has loaded an ad successfully.
    func setUpAdControllerWithLoadedAd(_ ad: LoadedAd = .test()) {
        // Set up
        mocks.initializationStatusProvider.isInitialized = true
        // Load ad
        var completed = false
        adController.loadAd(request: ad.request, viewController: viewController) { result in
            if case .failure = result.result {
                XCTFail("Received unexpected failure result")
            }
            completed = true
        }
        
        // Get AdRepository completion
        var loadCompletion: (InternalAdLoadResult) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adRepository, .loadAd, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { loadCompletion = $0 }])
        
        // Call completion
        loadCompletion(InternalAdLoadResult(result: .success(ad), metrics: nil))
        
        // Check that load finished
        XCTAssertTrue(completed)
        XCTAssertTrue(adController.isReadyToShowAd)
    }
    
    /// Convenience method to put the AdController in a state where it is showing an ad.
    /// We assume that an ad has been previously loaded.
    func setUpAdControllerWithShowingAd(_ ad: LoadedAd = .test()) {
        XCTAssertTrue(adController.isReadyToShowAd, "Before calling this method make sure to load an ad")
        // Show ad
        var completed = false
        adController.showAd(viewController: viewController) { result in
            XCTAssertNil(result.error)
            completed = true
        }
        
        // Get PartnerController completion
        var showCompletion: (ChartboostMediationError?) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeShow, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { showCompletion = $0 }])
        
        // Call completion
        showCompletion(nil)
        
        // Check that load finished
        XCTAssertTrue(completed)
        // Clean up
        mocks.metrics.removeAllRecords()
        mocks.ilrdEventPublisher.removeAllRecords()
        mocks.adControllerDelegate.removeAllRecords()
    }
}
