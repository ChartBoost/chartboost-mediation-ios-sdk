// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class SingleAdStorageAdControllerTests: HeliumTestCase {

    lazy var adController = SingleAdStorageAdController()

    let heliumPlacement = "some helium placement"
    let viewController = UIViewController()
    
    // MARK: - Load Ad
    
    /// Validates the AdController fails early on loadAd() if Helium hasn't been initialized yet.
    func testLoadAdFailsEarlyWhenHeliumIsNotStarted() {
        // Setup: Helium not started
        mocks.initializationStatusProvider.isInitialized = false
        let expectedLoadResult = AdLoadResult(
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
        let firstRequest = HeliumAdLoadRequest.test(loadID: "id1")
        let expectedLoadResult = AdLoadResult(
            result: .success(HeliumAd.test(request: firstRequest)),
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
        var firstLoadCompletion: (AdLoadResult) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adRepository, .loadAd, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { firstLoadCompletion = $0 }])
        
        // Load ad again
        let secondRequest = HeliumAdLoadRequest.test(loadID: "id2")
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
        let firstRequest = HeliumAdLoadRequest.test(loadID: "id1")
        let expectedHeliumAd = HeliumAd.test(request: firstRequest)
        let expectedLoadResult = AdLoadResult(
            result: .success(expectedHeliumAd),
            metrics: nil
        )
        setUpAdControllerWithLoadedAd(expectedHeliumAd)
        
        // Load ad again
        var completed = false
        let secondRequest = HeliumAdLoadRequest.test(loadID: "id2")
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
        let request = HeliumAdLoadRequest.test(loadID: "id1")
        let expectedLoadResult = AdLoadResult(
            result: .success(HeliumAd.test(request: request)),
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
        var firstLoadCompletion: (AdLoadResult) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adRepository, .loadAd, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { firstLoadCompletion = $0 }])

        // Finish AdRepository load
        firstLoadCompletion(expectedLoadResult)
        
        // Check loadAd finished successfully
        XCTAssertTrue(completed)
        XCTAssertTrue(adController.isReadyToShowAd)
    }
    
    /// Validates the AdController finishes with failure on loadAd() if the AdRepository fails in returning an ad.
    func testLoadAdFailsIfAdRepositoryFails() {
        // Setup: start
        mocks.initializationStatusProvider.isInitialized = true
        let expectedLoadResult = AdLoadResult(
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
        var firstLoadCompletion: (AdLoadResult) -> Void = { _ in }
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
        let ad = HeliumAd.test()
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
        let ad = HeliumAd.test()
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
        let ad = HeliumAd.test()
        setUpAdControllerWithLoadedAd(ad)
        setUpAdControllerWithShowingAd(ad)
        let secondAd = HeliumAd.test()
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
        let expectedShowResult = AdShowResult(
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
        let ad = HeliumAd.test()
        setUpAdControllerWithLoadedAd(ad)
        adController.addObserver(observer: mocks.adControllerDelegate)
        let expectedShowResult = AdShowResult(
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
        XCTAssertMethodCalls(mocks.metrics, .logShow, .logHeliumImpression, parameters: [
            ad.partnerAd.request.auctionIdentifier,
            ad.request.loadID,
            XCTMethodSomeParameter<MetricsEvent> {
                XCTAssertNil($0.error)
                XCTAssertEqual($0.partnerIdentifier, ad.partnerAd.request.partnerIdentifier)
            }
        ], [
            ad.partnerAd
        ])
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didTrackImpression)
        XCTAssertMethodCalls(mocks.fullScreenAdShowObserver, .didShowFullScreenAd)
        XCTAssertMethodCalls(mocks.impressionTracker, .trackImpression, parameters: [ad.request.adFormat])
    }
    
    /// Validates the AdController fails on showAd() if the PartnerController fails on showing the ad.
    func testShowAdFailsIfPartnerControllerFails() {
        // Setup: a loaded interstitial ad
        mocks.initializationStatusProvider.isInitialized = false
        let ad = HeliumAd.test()
        setUpAdControllerWithLoadedAd(ad)
        adController.addObserver(observer: mocks.adControllerDelegate)
        let expectedShowResult = AdShowResult(
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
            ad.partnerAd.request.auctionIdentifier,
            ad.request.loadID,
            XCTMethodSomeParameter<MetricsEvent> {
                XCTAssertEqual($0.error?.chartboostMediationCode, .partnerError)
                XCTAssertEqual($0.partnerIdentifier, ad.partnerAd.request.partnerIdentifier)
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
        let ad = HeliumAd.test(ilrd: ilrd)
        setUpAdControllerWithLoadedAd(ad)
        
        // Show ad
        adController.showAd(viewController: viewController) { _ in }
        
        // Finish PartnerController show with success
        var showCompletion: (ChartboostMediationError?) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeShow, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { showCompletion = $0 }])
        showCompletion(nil)
        
        // Check ILRD event is posted
        XCTAssertMethodCalls(mocks.ilrdEventPublisher, .postILRDEvent, parameters: [ad.request.heliumPlacement, ilrd])
    }
    
    /// Validates the AdController fails on showAd() if the PartnerController does not finish showing the ad on a timely manner.
    func testShowAdFailsIfPartnerControllerTimesOut() {
        // Setup: a loaded interstitial ad
        let ad = HeliumAd.test()
        setUpAdControllerWithLoadedAd(ad)
        adController.addObserver(observer: mocks.adControllerDelegate)
        let expectedShowResult = AdShowResult(
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
            ad.partnerAd.request.auctionIdentifier,
            ad.request.loadID,
            XCTMethodSomeParameter<MetricsEvent> {
                XCTAssertEqual($0.error?.chartboostMediationCode, .showFailureTimeout)
                XCTAssertEqual($0.partnerIdentifier, ad.partnerAd.request.partnerIdentifier)
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
        let ad = HeliumAd.test(request: .test(adFormat: .banner))
        setUpAdControllerWithLoadedAd(ad)
        adController.addObserver(observer: mocks.adControllerDelegate)
        
        // Show ad
        adController.markLoadedAdAsShown()
        
        // Check impression is logged and delegate method called
        XCTAssertMethodCalls(mocks.metrics, .logHeliumImpression, parameters: [ad.partnerAd])
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
    
    // MARK: - PartnerAdDelegate
    
    /// Validates that AdController handles a didTrackImpression event properly
    func testDidTrackImpression() {
        // Setup
        adController.addObserver(observer: mocks.adControllerDelegate)
        
        // Call didTrackImpression
        let ad = PartnerAdMock()
        adController.didTrackImpression(ad, details: [:])
        
        // Check impression is logged
        XCTAssertMethodCalls(mocks.metrics, .logPartnerImpression, parameters: [ad])
    }
    
    /// Validates that AdController handles a didClick event properly
    func testDidClick() {
        // Setup
        adController.addObserver(observer: mocks.adControllerDelegate)
        
        // Call didClick
        let ad = PartnerAdMock()
        adController.didClick(ad, details: [:])
        
        // Check delegate method is called
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didClick)
        // Check metrics are logged
        XCTAssertMethodCalls(mocks.metrics, .logClick, parameters: [ad.request.auctionIdentifier, ad.request.loadID])
    }
    
    /// Validates that AdController handles a didReward event properly
    func testDidReward() {
        // Setup
        adController.addObserver(observer: mocks.adControllerDelegate)
        
        // Call didReward
        let ad = PartnerAdMock()
        adController.didReward(ad, details: [:])
        
        // Check delegate method is called
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didReward, parameters: [])
        // Check that reward is tracked
        XCTAssertMethodCalls(mocks.metrics, .logReward, parameters: [ad])
    }
    
    /// Validates that AdController sends a rewarded callback if available on didReward
    func testDidRewardSendsRewardedCallback() {
        // Setup
        adController.addObserver(observer: mocks.adControllerDelegate)
        adController.customData = "some data"
        let rewardedCallback = RewardedCallback.test()
        let heliumAd = HeliumAd.test(rewardedCallback: rewardedCallback)
        setUpAdControllerWithLoadedAd(heliumAd)
        setUpAdControllerWithShowingAd(heliumAd)
        
        // Call didReward
        adController.didReward(heliumAd.partnerAd, details: [:])
        
        // Check delegate method is called
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didReward, parameters: [])
        // Check that reward is tracked passing the callback and the customData
        XCTAssertMethodCalls(mocks.metrics, .logReward, .logRewardedCallback, parameters: [heliumAd.partnerAd], [rewardedCallback, "some data"])
    }
    
    /// Validates that AdController handles a didDismiss event properly when no error
    func testDidDismissWithNoError() {
        // Setup
        adController.addObserver(observer: mocks.adControllerDelegate)
        
        // Call didDismiss
        let ad = PartnerAdMock(request: .test(format: .interstitial))
        adController.didDismiss(ad, details: [:], error: nil)
        
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
        adController.addObserver(observer: mocks.adControllerDelegate)
        
        // Call didDismiss
        let ad = PartnerAdMock(request: .test(format: .banner))
        let error = ChartboostMediationError(code: .partnerError)
        adController.didDismiss(ad, details: [:], error: error)
        
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
        let ad = HeliumAd.test()
        setUpAdControllerWithLoadedAd(ad)
        setUpAdControllerWithShowingAd(ad)
        let ad2 = HeliumAd.test()
        setUpAdControllerWithLoadedAd(ad2)
        
        // Call didDismiss
        adController.didDismiss(ad.partnerAd, details: [:], error: nil)
        mocks.partnerController.removeAllRecords()    // clean up recorded methods to ignore the routeInvalidate() call triggered on dismiss
        
        // Show the second ad
        setUpAdControllerWithShowingAd(ad2)
    }
    
    /// Validates that AdController handles a didExpire event properly.
    func testDidExpire() {
        // Setup
        adController.addObserver(observer: mocks.adControllerDelegate)
        
        // Call didClick
        let ad = PartnerAdMock()
        adController.didExpire(ad, details: [:])
        
        // Check delegate method is called
        XCTAssertMethodCalls(mocks.adControllerDelegate, .didExpire)
        // Check metrics are logged
        XCTAssertMethodCalls(mocks.metrics, .logExpiration, parameters: [ad.request.auctionIdentifier, ad.request.loadID])
    }
    
    // MARK: - Deinit
    
    /// Validates that AdController invalidates a loaded ad when it is deallocated to avoid memory leaks.
    func testLoadedAdIsInvalidatedOnDeinit() {
        // Setup
        mocks.initializationStatusProvider.isInitialized = true
        let loadedAd = HeliumAd.test()
        
        autoreleasepool {
            // Instantiate controller inside an autoreleasepool so it gets deallocated at the end of its scope
            let controller = SingleAdStorageAdController()
            
            // Load ad
            controller.loadAd(request: .test(), viewController: viewController) { _ in }
            
            // Finish AdRepository load
            var loadCompletion: (AdLoadResult) -> Void = { _ in }
            XCTAssertMethodCalls(mocks.adRepository, .loadAd, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { loadCompletion = $0 }])
            loadCompletion(AdLoadResult(result: .success(loadedAd), metrics: nil))
            
            // Remove records so we can easily check for the routeInvalidate call below
            mocks.partnerController.removeAllRecords()
        }
        
        // Check that the ad got invalidated on deinit
        XCTAssertMethodCalls(mocks.partnerController, .routeInvalidate, parameters: [loadedAd.partnerAd, XCTMethodIgnoredParameter()])
    }
}

// MARK: - Helpers

extension SingleAdStorageAdControllerTests {
    
    /// Convenience method to put the AdController in a state where it has loaded an ad successfully.
    func setUpAdControllerWithLoadedAd(_ ad: HeliumAd = .test()) {
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
        var loadCompletion: (AdLoadResult) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adRepository, .loadAd, parameters: [XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { loadCompletion = $0 }])
        
        // Call completion
        loadCompletion(AdLoadResult(result: .success(ad), metrics: nil))
        
        // Check that load finished
        XCTAssertTrue(completed)
        XCTAssertTrue(adController.isReadyToShowAd)
    }
    
    /// Convenience method to put the AdController in a state where it is showing an ad.
    /// We assume that an ad has been previously loaded.
    func setUpAdControllerWithShowingAd(_ ad: HeliumAd = .test()) {
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
