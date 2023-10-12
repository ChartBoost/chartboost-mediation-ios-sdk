// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class PartnerAdapterControllerTests: HeliumTestCase {

    lazy var partnerController = PartnerAdapterController()

    let loadID = "some load ID"

    let adapter1 = PartnerAdapterMock()
    let adapter2 = PartnerAdapterMock()
    let adapter3 = PartnerAdapterMock()
    
    let adapterStorage1 = MutablePartnerAdapterStorage()
    let adapterStorage2 = MutablePartnerAdapterStorage()
    let adapterStorage3 = MutablePartnerAdapterStorage()
    
    let partnerConfig1 = PartnerConfiguration(credentials: ["142": "a42", "242": "b42"])
    let partnerConfig2 = PartnerConfiguration(credentials: ["1_3": "a", "2_3": "b..s"])
    let partnerConfig3 = PartnerConfiguration(credentials: ["1": "a", "2": "b"])
    
    let viewController = UIViewController()
    let delegate = PartnerAdDelegateMock()
    
    override func setUp() {
        super.setUp()
        
        mocks.adapterFactory.setReturnValue([(adapter1, adapterStorage1), (adapter2, adapterStorage2), (adapter3, adapterStorage3)], for: .adaptersFromClassNames)
    }
    
    // MARK: - SetUpAdapters
    
    /// Validates that on setup configurations that do not correspond to any adapter get ignored and available adapters for which there is no configuration also get ignored.
    func testSetUpAdaptersWithMissingAndUnknownConfigurations() {
        let configurations = [
            "uknown adapter ID": partnerConfig3,
            adapter1.partnerIdentifier: partnerConfig1,
            adapter2.partnerIdentifier: partnerConfig2
        ]
        let classNames = Set(["C1", "C2", "C3"])
        
        // Set up to check that adapters get properly set up
        partnerController.setUpAdapters(configurations: configurations, adapterClasses: classNames, skipping: [], completion: { _ in })
        
        // adapter3 was not in the configurations map so it doesn't get initialized
        XCTAssertNoMethodCalls(adapter3)
        // adapter1 gets initialized with the proper configuration
        var adapter1SetUpCompletion: (Error?) -> Void = { _ in }
        XCTAssertMethodCalls(adapter1, .setUp, parameters: [partnerConfig1, XCTMethodCaptureParameter { adapter1SetUpCompletion = $0 }])
        // adapter2 gets initialized with the proper configuration
        var adapter2SetUpCompletion: (Error?) -> Void = { _ in }
        XCTAssertMethodCalls(adapter2, .setUp, parameters: [partnerConfig2, XCTMethodCaptureParameter { adapter2SetUpCompletion = $0 }])
        
        // At this point adapters are not initialized yet
        XCTAssertEqual(partnerController.initializedAdapterInfo, [:])
        
        // Complete adapter2 set up
        adapter2SetUpCompletion(nil)
        
        // Now only adapter2 should be initialized
        XCTAssertEqual(partnerController.initializedAdapterInfo, [adapter2.partnerIdentifier: adapter2.info])
        
        // Complete adapter1 set up
        adapter1SetUpCompletion(nil)
        
        // Now both adapters should be initialized
        XCTAssertEqual(partnerController.initializedAdapterInfo, [adapter2.partnerIdentifier: adapter2.info, adapter1.partnerIdentifier: adapter1.info])
    }
    
    /// Validates that adapters that report a failed initialization are not considered initialized by the PartnerController.
    func testSetUpAdaptersWithFailures() {
        let configurations = [
            adapter1.partnerIdentifier: partnerConfig1,
            adapter2.partnerIdentifier: partnerConfig2,
            adapter3.partnerIdentifier: partnerConfig3
        ]
        let classNames = Set(["C1", "C2", "C3"])
        
        // Set up to check that adapters get properly set up
        partnerController.setUpAdapters(configurations: configurations, adapterClasses: classNames, skipping: [], completion: { _ in })
        
        // get set up completion handlers for 3 adapters
        var adapter1SetUpCompletion: (Error?) -> Void = { _ in }
        var adapter2SetUpCompletion: (Error?) -> Void = { _ in }
        var adapter3SetUpCompletion: (Error?) -> Void = { _ in }
        XCTAssertMethodCalls(adapter1, .setUp, parameters: [partnerConfig1, XCTMethodCaptureParameter { adapter1SetUpCompletion = $0 }])
        XCTAssertMethodCalls(adapter2, .setUp, parameters: [partnerConfig2, XCTMethodCaptureParameter { adapter2SetUpCompletion = $0 }])
        XCTAssertMethodCalls(adapter3, .setUp, parameters: [partnerConfig3, XCTMethodCaptureParameter { adapter3SetUpCompletion = $0 }])
        
        // At this point adapters are not initialized yet
        XCTAssertEqual(partnerController.initializedAdapterInfo, [:])
        
        // Complete adapter2 set up with an error
        adapter2SetUpCompletion(NSError.test())
        // adapter2 should not be initialized
        XCTAssertEqual(partnerController.initializedAdapterInfo, [:])
        
        // Complete adapter3 set up successfully
        adapter3SetUpCompletion(nil)
        // adapter3 should be initialized
        XCTAssertEqual(partnerController.initializedAdapterInfo, [adapter3.partnerIdentifier: adapter3.info])
        
        // Complete adapter1 set up with an error
        adapter1SetUpCompletion(NSError.test())
        // Only adapter3 remains initialized
        XCTAssertEqual(partnerController.initializedAdapterInfo, [adapter3.partnerIdentifier: adapter3.info])
    }
    
    /// Validates that privacy consent values are set on adapters after initialization if they were called before.
    func testSetUpAdaptersAfterSettingConsentValues() {
        let configurations = [
            adapter1.partnerIdentifier: partnerConfig1,
            adapter2.partnerIdentifier: partnerConfig2,
            adapter3.partnerIdentifier: partnerConfig3
        ]
        let classNames = Set(["C1", "C2", "C3"])
        
        // Set GDPR applies before initialization
        mocks.consentSettings.gdprConsent = .unknown
        mocks.consentSettings.isSubjectToGDPR = true
        partnerController.didChangeGDPR()
        
        // Set up to check that adapters get properly set up
        partnerController.setUpAdapters(configurations: configurations, adapterClasses: classNames, skipping: [], completion: { _ in })
        
        // get set up completion handlers for 3 adapters
        var adapter1SetUpCompletion: (Error?) -> Void = { _ in }
        var adapter2SetUpCompletion: (Error?) -> Void = { _ in }
        var adapter3SetUpCompletion: (Error?) -> Void = { _ in }
        XCTAssertMethodCalls(adapter1, .setUp, parameters: [partnerConfig1, XCTMethodCaptureParameter { adapter1SetUpCompletion = $0 }])
        XCTAssertMethodCalls(adapter2, .setUp, parameters: [partnerConfig2, XCTMethodCaptureParameter { adapter2SetUpCompletion = $0 }])
        XCTAssertMethodCalls(adapter3, .setUp, parameters: [partnerConfig3, XCTMethodCaptureParameter { adapter3SetUpCompletion = $0 }])
        
        // Complete adapter1 setup should set GDPRApplies only on it
        adapter1SetUpCompletion(nil)
        
        XCTAssertMethodCalls(adapter1, .setGDPR, parameters: [true, GDPRConsentStatus.unknown])
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertNoMethodCalls(adapter3)
        
        // Set COPPA and GDPR status during initialization applies immediately to adapter1
        mocks.consentSettings.isSubjectToCOPPA = false
        mocks.consentSettings.gdprConsent = .granted
        partnerController.didChangeCOPPA()
        partnerController.didChangeGDPR()
        
        XCTAssertMethodCalls(adapter1, .setCOPPA, .setGDPR, parameters: [false], [true, GDPRConsentStatus.granted])
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertNoMethodCalls(adapter3)

        // Complete adapter3 setup should set GDPR and COPPA on it
        adapter3SetUpCompletion(nil)
        
        XCTAssertNoMethodCalls(adapter1)
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertMethodCalls(adapter3, .setGDPR, .setCOPPA, parameters: [true, GDPRConsentStatus.granted], [false])
        
        // Set CCPA during initialization applies immediately to adapter1 and adapter3
        mocks.consentSettings.ccpaConsent = true
        mocks.consentSettings.ccpaPrivacyString = "1234"
        partnerController.didChangeCCPA()
        
        XCTAssertMethodCalls(adapter1, .setCCPA, parameters: [true, "1234"])
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertMethodCalls(adapter3, .setCCPA, parameters: [true, "1234"])

        // Complete adapter2 setup should set all previous consents
        adapter2SetUpCompletion(nil)
        
        XCTAssertNoMethodCalls(adapter1)
        XCTAssertMethodCalls(adapter2, .setGDPR, .setCCPA, .setCOPPA, parameters: [true, GDPRConsentStatus.granted], [true, "1234"], [false])
        XCTAssertNoMethodCalls(adapter3)
    }
    
    // MARK: - RouteLoad
    
    /// Validates that routeLoad fails early if the requested partner is not available.
    func testRouteLoadFailsImmediatelyIfAdapterIsUnavailable() {
        // initialize adapters
        setUp3Adapters()
        // load ad
        var completed = false
        let request = PartnerAdLoadRequest.test(partnerIdentifier: "unknown partner ID")
        _ = partnerController.routeLoad(request: request, viewController: viewController, delegate: delegate) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.chartboostMediationCode, .loadFailurePartnerNotInitialized)
            } else {
                XCTFail("Unexpected successful result")
            }
            completed = true
        }
        
        // Completion callback should have been called, and no method calls made to the adapters
        XCTAssertTrue(completed)
        XCTAssertNoMethodCalls(adapter1)
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertNoMethodCalls(adapter3)
    }
    
    /// Validates that routeLoad finishes successfully if the partner adapter responds with a successul load result.
    func testRouteLoadSucceedsIfPartnerLoadSucceeds() {
        // initialize adapters
        setUp3Adapters()
        let ad = adapter2.returnValue(for: .makeAd) as PartnerAdMock
        let request = PartnerAdLoadRequest.test(partnerIdentifier: adapter2.partnerIdentifier)
        
        // load ad
        var completed = false
        _ = partnerController.routeLoad(request: request, viewController: viewController, delegate: delegate) { result in
            if case .success((let returnedAd, _)) = result {
                XCTAssertIdentical(returnedAd, ad)
            } else {
                XCTFail("Unexpected failure result")
            }
            completed = true
        }

        // check partner ad is created
        XCTAssertMethodCalls(adapter2, .makeAd, parameters: [request, delegate])
        // check partner call is made
        var partnerLoadCompletion: (Result<PartnerEventDetails, Error>) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .load, parameters: [viewController, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        XCTAssertFalse(completed)
        
        // call partner completion
        partnerLoadCompletion(.success([:]))
        
        // check that partner controller is done
        XCTAssertTrue(completed)
        // check adapter storage is updated
        XCTAssertAnyEqual(adapterStorage2.ads, [ad])
        // check other partners are unaffected
        XCTAssertNoMethodCalls(adapter1)
        XCTAssertNoMethodCalls(adapter3)
    }
    
    /// Validates that routeLoad finishes with failure if the partner adapter responds with a failed load result.
    func testRouteLoadFailsIfPartnerLoadFails() {
        // initialize adapters
        setUp3Adapters()
        let adapterError = ChartboostMediationError(code: .partnerError)
        // load ad
        var completed = false
        let request = PartnerAdLoadRequest.test(partnerIdentifier: adapter2.partnerIdentifier)
        _ = partnerController.routeLoad(request: request, viewController: viewController, delegate: delegate) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error as NSError, adapterError)
            } else {
                XCTFail("Unexpected error sent")
            }
            completed = true
        }

        // check partner ad is created
        XCTAssertMethodCalls(adapter2, .makeAd, parameters: [request, delegate])
        let ad = adapter2.returnValue(for: .makeAd) as PartnerAdMock
        // check partner call is made
        var partnerLoadCompletion: (Result<PartnerEventDetails, Error>) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .load, parameters: [viewController, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        XCTAssertFalse(completed)
        
        // call partner completion
        partnerLoadCompletion(.failure(adapterError))
        
        // check that partner controller is done
        XCTAssertTrue(completed)
        // check adapter storage is updated
        XCTAssertAnyEqual(adapterStorage2.ads, [PartnerAd]())
        // check other partners are unaffected
        XCTAssertNoMethodCalls(adapter1)
        XCTAssertNoMethodCalls(adapter3)
    }
    
    /// Validates that routeLoad finishes with an ChartboostMediationError error failure if the partner adapter responds with a non-ChartboostMediationError error.
    func testRouteLoadFailsWithChartboostMediationErrorIfPartnerLoadFailsWithNonChartboostMediationError() {
        // initialize adapters
        setUp3Adapters()
        let adapterError = NSError.test()
        // load ad
        var completed = false
        let request = PartnerAdLoadRequest.test(partnerIdentifier: adapter2.partnerIdentifier)
        _ = partnerController.routeLoad(request: request, viewController: viewController, delegate: delegate) { result in
            if case .failure(let error) = result {
                let expectedError = ChartboostMediationError(code: .loadFailureUnknown, error: adapterError)
                XCTAssertEqual(error.chartboostMediationCode, expectedError.chartboostMediationCode)
                XCTAssertEqual(error.userInfo[NSUnderlyingErrorKey] as? NSError, adapterError)
            } else {
                XCTFail("Unexpected error sent")
            }
            completed = true
        }

        // check partner ad is created
        XCTAssertMethodCalls(adapter2, .makeAd, parameters: [request, delegate])
        let ad = adapter2.returnValue(for: .makeAd) as PartnerAdMock
        // check partner call is made
        var partnerLoadCompletion: (Result<PartnerEventDetails, Error>) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .load, parameters: [viewController, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        XCTAssertFalse(completed)
        
        // call partner completion passing a NSError instead of an ChartboostMediationError
        partnerLoadCompletion(.failure(adapterError))
        
        // check that partner controller is done
        XCTAssertTrue(completed)
        // check adapter storage is updated
        XCTAssertAnyEqual(adapterStorage2.ads, [PartnerAd]())
        // check other partners are unaffected
        XCTAssertNoMethodCalls(adapter1)
        XCTAssertNoMethodCalls(adapter3)
    }
    
    /// Validates that routeLoad finishes with failure if the partner adapter throws an error when `makeAd()` is called.
    func testRouteLoadFailsIfPartnerMakeAdFails() {
        // initialize adapters
        setUp3Adapters()
        let adapterError = ChartboostMediationError(code: .partnerError)
        adapter2.setReturnValue(adapterError, for: .makeAd)
        
        // load ad
        var completed = false
        let request = PartnerAdLoadRequest.test(partnerIdentifier: adapter2.partnerIdentifier)
        _ = partnerController.routeLoad(request: request, viewController: viewController, delegate: delegate) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error as NSError, adapterError)
            } else {
                XCTFail("Unexpected error sent")
            }
            completed = true
        }
        
        // check that partner controller is done
        XCTAssertTrue(completed)
        XCTAssertMethodCalls(adapter2, .makeAd, parameters: [request, delegate])
        // check adapter storage is updated
        XCTAssertAnyEqual(adapterStorage2.ads, [PartnerAd]())
        // check other partners are unaffected
        XCTAssertNoMethodCalls(adapter1)
        XCTAssertNoMethodCalls(adapter3)
    }
    
    /// Validates that routeLoad invalidates the loading ad when the cancel action is executed, and it does not call the corresponding load completion closure.
    func testRouteLoadInvalidatesAdAndIgnoresResultOnCancel() {
        // initialize adapters
        setUp3Adapters()
        let ad = adapter2.returnValue(for: .makeAd) as PartnerAdMock
        let request = PartnerAdLoadRequest.test(partnerIdentifier: adapter2.partnerIdentifier)
        
        // load ad
        var completed = false
        let cancelAction = partnerController.routeLoad(request: request, viewController: viewController, delegate: delegate) { result in
            XCTFail("Unexpected call")
            completed = true
        }
        
        // check partner ad is created
        XCTAssertMethodCalls(adapter2, .makeAd, parameters: [request, delegate])
        // check partner call is made
        var partnerLoadCompletion: (Result<PartnerEventDetails, Error>) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .load, parameters: [viewController, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        XCTAssertFalse(completed)
        
        // cancel the load operation
        cancelAction()
        
        // check that completion is not called and ad is invalidated
        XCTAssertFalse(completed)
        XCTAssertMethodCalls(ad, .invalidate)
        
        // call partner completion to make sure it is ignored
        partnerLoadCompletion(.success([:]))
        
        // check that completion was ignored
        XCTAssertFalse(completed)
        // check adapter storage is updated
        XCTAssertAnyEqual(adapterStorage2.ads, [PartnerAd]())
        // check other partners are unaffected
        XCTAssertNoMethodCalls(adapter1)
        XCTAssertNoMethodCalls(adapter3)
    }
    
    // MARK: - RouteShow
    
    /// Validates that routeShow finishes successfully if the partner adapter responds with a successful show result.
    func testRouteShowSucceedsIfPartnerShowSucceeds() {
        // initialize adapters and load ad
        setUp3Adapters()
        let ad = PartnerAdMock()
        
        // show
        var completed = false
        partnerController.routeShow(ad, viewController: viewController) { error in
            if error != nil {
                XCTFail("Unexpected failure result")
            }
            completed = true
        }

        // check that partner show was called
        var partnerCompletion: (Result<PartnerEventDetails, Error>) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .show, parameters: [viewController, XCTMethodCaptureParameter { partnerCompletion = $0 }])
        XCTAssertFalse(completed)
        
        // perform partner completion
        partnerCompletion(.success([:]))
        
        // Completion callback should have been called, and no method calls made to the adapters
        XCTAssertTrue(completed)
        XCTAssertNoMethodCalls(adapter1)
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertNoMethodCalls(adapter3)
    }
    
    /// Validates that routeShow finishes with failure if the partner adapter responds with a failed show result.
    func testRouteShowFailsIfPartnerShowFails() {
        // initialize adapters and load ad
        setUp3Adapters()
        let ad = PartnerAdMock()
        
        // show
        let partnerError = ChartboostMediationError(code: .partnerError)
        var completed = false
        partnerController.routeShow(ad, viewController: viewController) { error in
            if let error = error {
                XCTAssertEqual(error as NSError, partnerError)
            } else {
                XCTFail("Unexpected successful result")
            }
            completed = true
        }

        // check that partner show was called
        var partnerCompletion: (Result<PartnerEventDetails, Error>) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .show, parameters: [viewController, XCTMethodCaptureParameter { partnerCompletion = $0 }])
        XCTAssertFalse(completed)
        
        // perform partner completion
        partnerCompletion(.failure(partnerError))
        
        // Completion callback should have been called, and no method calls made to the adapters
        XCTAssertTrue(completed)
        XCTAssertNoMethodCalls(adapter1)
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertNoMethodCalls(adapter3)
    }
    
    /// Validates that routeShow finishes with an ChartboostMediationError error failure if the partner adapter responds with a non-ChartboostMediationError error.
    func testRouteShowFailsWithChartboostMediationErrorIfPartnerShowFailsWithNonChartboostMediationError() {
        // initialize adapters and load ad
        setUp3Adapters()
        let ad = PartnerAdMock()
        
        // show
        let partnerError = NSError.test()
        var completed = false
        partnerController.routeShow(ad, viewController: viewController) { error in
            if let error = error {
                let expectedError = ChartboostMediationError(code: .showFailureUnknown, error: partnerError)
                XCTAssertEqual(error.chartboostMediationCode, expectedError.chartboostMediationCode)
                XCTAssertEqual(error.userInfo[NSUnderlyingErrorKey] as? NSError, partnerError)
            } else {
                XCTFail("Unexpected successful result")
            }
            completed = true
        }

        // check that partner show was called
        var partnerCompletion: (Result<PartnerEventDetails, Error>) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .show, parameters: [viewController, XCTMethodCaptureParameter { partnerCompletion = $0 }])
        XCTAssertFalse(completed)
        
        // call partner completion passing a NSError instead of an ChartboostMediationError
        partnerCompletion(.failure(partnerError))
        
        // Completion callback should have been called, and no method calls made to the adapters
        XCTAssertTrue(completed)
        XCTAssertNoMethodCalls(adapter1)
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertNoMethodCalls(adapter3)
    }
    
    // MARK: - RouteInvalidate
    
    /// Validates that routeInvalidate finishes successfully if the partner adapter responds with a successful invalidate result.
    func testRouteInvalidateSucceedsIfPartnerInvalidateSucceeds() {
        // set up adapters
        setUp3Adapters()
        let ad = adapter1.returnValue(for: .makeAd) as PartnerAdMock
        // set no error throw on invalidate() call
        ad.setReturnValue(nil, for: .invalidate)
        // set storage to contain ad, like it would be after a load
        adapterStorage1.ads.append(ad)
        
        // invalidate
        var completed = false
        partnerController.routeInvalidate(ad) { error in
            if error != nil {
                XCTFail("Unexpected failure result")
            }
            completed = true
        }
        
        // only adapter1 gets called, nothing happens to others
        XCTAssertTrue(completed)
        XCTAssertMethodCalls(ad, .invalidate)
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertNoMethodCalls(adapter3)
        // check storage is updated
        XCTAssertAnyEqual(adapterStorage1.ads, [PartnerAd]())
    }
    
    /// Validates that routeInvalidate finishes with failure if the partner adapter responds with a failed invalidate result.
    func testRouteInvalidateFailsIfPartnerInvalidateFails() {
        // set up adapters and load ad
        setUp3Adapters()
        let ad = adapter1.returnValue(for: .makeAd) as PartnerAdMock
        // set error throw on invalidate() call
        let partnerError = ChartboostMediationError(code: .partnerError)
        ad.setReturnValue(partnerError, for: .invalidate)
        // set storage to contain ad, like it would be after a load
        adapterStorage1.ads.append(ad)
        // add other ads to storage to check that nothing happens to them
        let otherAds = [PartnerAdMock(), PartnerAdMock()]
        adapterStorage1.ads.append(contentsOf: otherAds)
        
        // invalidate
        var completed = false
        partnerController.routeInvalidate(ad) { error in
            if let error = error {
                XCTAssertEqual(error as NSError, partnerError)
            } else {
                XCTFail("Unexpected successful result")
            }
            completed = true
        }
        
        // only adapter1 gets called, nothing happens to others
        XCTAssertTrue(completed)
        XCTAssertMethodCalls(ad, .invalidate)
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertNoMethodCalls(adapter3)

        
        // check storage is updated
        XCTAssertAnyEqual(adapterStorage1.ads, otherAds)
    }
    
    /// Validates that routeInvalidate finishes with an ChartboostMediationError error failure if the partner adapter responds with a non-ChartboostMediationError error.
    func testRouteInvalidateFailsWithChartboostMediationErrorIfPartnerInvalidateFailsWithNonChartboostMediationError() {
        // set up adapters and load ad
        setUp3Adapters()
        let ad = adapter1.returnValue(for: .makeAd) as PartnerAdMock
        // set error throw on invalidate() call
        let partnerError = NSError.test()
        ad.setReturnValue(partnerError, for: .invalidate)
        // set storage to contain ad, like it would be after a load
        adapterStorage1.ads.append(ad)
        
        // invalidate
        var completed = false
        partnerController.routeInvalidate(ad) { error in
            if let error = error {
                let expectedError = ChartboostMediationError(code: .invalidateFailureUnknown, error: partnerError)
                XCTAssertEqual(error.chartboostMediationCode, expectedError.chartboostMediationCode)
                XCTAssertEqual(error.userInfo[NSUnderlyingErrorKey] as? NSError, partnerError)
            } else {
                XCTFail("Unexpected successful result")
            }
            completed = true
        }
        
        // only adapter1 gets called, nothing happens to others
        XCTAssertTrue(completed)
        XCTAssertMethodCalls(ad, .invalidate)
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertNoMethodCalls(adapter3)
        // check storage is updated
        XCTAssertAnyEqual(adapterStorage1.ads, [PartnerAd]())
    }
    
    // MARK: - RouteFetchBidderInformation
    
    /// Validates that routeFetchBidderInfo returns the info from all the adapters when they return before the timeout.
    func testRouteFetchBidderInformationWhenAllAdaptersFinishInTime() {
        setUp3Adapters()
        let group = mocks.taskDispatcher.returnGroup
        group.executedFinishedCompletionImmediately = false
        
        let bidderInfo1 = ["hello": "1234"]
        let bidderInfo2 = ["": "1234ia9sdfu9", "__": "", "aoijf j92j3r0 8qh2ofh": "adsjfi8u9  2"]
        let bidderInfo3 = ["423": "2", "fa_": ""]
        let expectedResult = [
            adapter1.partnerIdentifier: bidderInfo1,
            adapter2.partnerIdentifier: bidderInfo2,
            adapter3.partnerIdentifier: bidderInfo3
        ]
        
        // call routeFetchBidderInfo
        var completed = false
        let request = PreBidRequest(chartboostPlacement: "some placement", format: .interstitial, loadID: loadID)
        partnerController.routeFetchBidderInformation(request: request) { result in
            XCTAssertJSONEqual(result, expectedResult)
            completed = true
        }
        
        // check that adapters are asked to fetch bidder info
        var adapter1Completion: ([String: String]?) -> Void = { _ in }
        XCTAssertMethodCalls(adapter1, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter1Completion = $0 }])
        var adapter2Completion: ([String: String]?) -> Void = { _ in }
        XCTAssertMethodCalls(adapter2, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter2Completion = $0 }])
        var adapter3Completion: ([String: String]?) -> Void = { _ in }
        XCTAssertMethodCalls(adapter3, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter3Completion = $0 }])
        // check that dispatch group is set to timeout with expected value
        XCTAssertEqual(group.finishTimeout, mocks.partnerControllerConfiguration.prebidFetchTimeout)
        // check that partnerController's routeFechBidderInfo has not completed yet
        XCTAssertFalse(completed)
        
        // make adapter1 finish
        adapter1Completion(bidderInfo1)
        XCTAssertFalse(completed)   // check that nothing happened yet
        
        // make adapter3 finish
        adapter3Completion(bidderInfo3)
        XCTAssertFalse(completed)   // check that nothing happened yet
        
        // make adapter2 finish
        adapter2Completion(bidderInfo2)
        XCTAssertFalse(completed)   // check that nothing happened yet
        
        // make task group finish, which should trigger the completion
        group.finishedCompletion()
        
        // check that event is logged
        XCTAssertMethodCalls(mocks.metrics, .logPrebid, parameters: [loadID, XCTMethodSomeParameter<[MetricsEvent]> { [self] events in
            XCTAssertEqual(events.count, 3)
            XCTAssert(events.contains(where: { $0.partnerIdentifier == adapter1.partnerIdentifier }))
            XCTAssert(events.contains(where: { $0.partnerIdentifier == adapter2.partnerIdentifier }))
            XCTAssert(events.contains(where: { $0.partnerIdentifier == adapter3.partnerIdentifier }))
            for event in events {
                // latencies should be close to 0 since this test runs synchronously. they are in ms
                XCTAssertGreaterThanOrEqual(event.duration, 0)
                XCTAssertLessThan(event.duration, 100)
            }
        }])
        // check that partnerController's routeFechBidderInfo has completed
        XCTAssertTrue(completed)
    }
    
    /// Validates that routeFetchBidderInfo returns immediately when no adapters are available.
    func testRouteFetchBidderInformationWithNoAdapters() {
        // no adapter setup
        let group = mocks.taskDispatcher.returnGroup
        group.executedFinishedCompletionImmediately = false
        
        // call routeFetchBidderInfo
        var completed = false
        let request = PreBidRequest(chartboostPlacement: "some placement", format: .rewarded, loadID: loadID)
        partnerController.routeFetchBidderInformation(request: request) { result in
            XCTAssertJSONEqual(result, [PartnerIdentifier: [String: String]]())
            completed = true
        }
        
        // make task group finish, which should trigger the completion
        group.finishedCompletion()
        
        // check that event is logged
        XCTAssertMethodCalls(mocks.metrics, .logPrebid, parameters: [loadID, XCTMethodSomeParameter<[MetricsEvent]> { events in
            XCTAssertEqual(events.count, 0)
        }])
        // check that partnerController's routeFechBidderInfo has completed
        XCTAssertTrue(completed)
    }
    
    /// Validates that routeFetchBidderInfo returns the info from some adapters when others timeout.
    func testRouteFetchBidderInformationWhenSomeAdaptersTimeout() {
        setUp3Adapters()
        let group = mocks.taskDispatcher.returnGroup
        group.executedFinishedCompletionImmediately = false
        
        let bidderInfo2 = ["": "1234ia9sdfu9", "__": "", "aoijf j92j3r0 8qh2ofh": "adsjfi8u9  2"]
        let bidderInfo3 = ["423": "2", "fa_": ""]
        let expectedResult = [
            adapter2.partnerIdentifier: bidderInfo2,
            adapter3.partnerIdentifier: bidderInfo3
        ]
        
        // call routeFetchBidderInfo
        var completed = false
        let request = PreBidRequest(chartboostPlacement: "some placement", format: .rewarded, loadID: loadID)
        partnerController.routeFetchBidderInformation(request: request) { result in
            XCTAssertJSONEqual(result, expectedResult)  // no info for adapter1 which will time out
            completed = true
        }
        
        // check that adapters are asked to fetch bidder info
        XCTAssertMethodCalls(adapter1, .fetchBidderInformation, parameters: [request, XCTMethodIgnoredParameter()])
        var adapter2Completion: ([String: String]?) -> Void = { _ in }
        XCTAssertMethodCalls(adapter2, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter2Completion = $0 }])
        var adapter3Completion: ([String: String]?) -> Void = { _ in }
        XCTAssertMethodCalls(adapter3, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter3Completion = $0 }])
        // check that dispatch group is set to timeout with expected value
        XCTAssertEqual(group.finishTimeout, mocks.partnerControllerConfiguration.prebidFetchTimeout)
        // check that partnerController's routeFechBidderInfo has not completed yet
        XCTAssertFalse(completed)
        
        // make adapter3 finish
        adapter3Completion(bidderInfo3)
        XCTAssertFalse(completed)   // check that nothing happened yet
        
        // make adapter2 finish
        adapter2Completion(bidderInfo2)
        XCTAssertFalse(completed)   // check that nothing happened yet
        
        // make task group finish before adapter1 can finish, which considers it as timed out
        group.finishedCompletion()
        
        // check that event is logged
        XCTAssertMethodCalls(mocks.metrics, .logPrebid, parameters: [loadID, XCTMethodSomeParameter<[MetricsEvent]> { [self] events in
            XCTAssertEqual(events.count, 2)
            XCTAssert(events.contains(where: { $0.partnerIdentifier == adapter2.partnerIdentifier }))
            XCTAssert(events.contains(where: { $0.partnerIdentifier == adapter3.partnerIdentifier }))
            for event in events {
                switch event.partnerIdentifier {
                case adapter2.partnerIdentifier, adapter3.partnerIdentifier:
                    XCTAssertEqual(event.error, nil)
                default:
                    XCTFail("Unknown partner identifier")
                }
            }
        }])
        // check that partnerController's routeFechBidderInfo has completed
        XCTAssertTrue(completed)
    }
    
    /// Validates that routeFetchBidderInfo returns proper info when all adapters timeout.
    func testRouteFetchBidderInformationWhenAllAdaptersTimeout() {
        setUp3Adapters()
        let group = mocks.taskDispatcher.returnGroup
        group.executedFinishedCompletionImmediately = false
        
        // call routeFetchBidderInfo
        var completed = false
        let request = PreBidRequest(chartboostPlacement: "some placement", format: .banner, loadID: loadID)
        partnerController.routeFetchBidderInformation(request: request) { result in
            XCTAssertJSONEqual(result, [PartnerIdentifier: [String: String]]()) // empty result
            completed = true
        }
        
        // check that adapters are asked to fetch bidder info
        var adapter1Completion: ([String: String]?) -> Void = { _ in }
        XCTAssertMethodCalls(adapter1, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter1Completion = $0 }])
        XCTAssertMethodCalls(adapter2, .fetchBidderInformation, parameters: [request, XCTMethodIgnoredParameter()])
        XCTAssertMethodCalls(adapter3, .fetchBidderInformation, parameters: [request, XCTMethodIgnoredParameter()])
        // check that dispatch group is set to timeout with expected value
        XCTAssertEqual(group.finishTimeout, mocks.partnerControllerConfiguration.prebidFetchTimeout)
        // check that partnerController's routeFechBidderInfo has not completed yet
        XCTAssertFalse(completed)
        
        // make task group finish before calling any adapter completion to trigger a timeout
        group.finishedCompletion()
        
        // check that event is logged
        XCTAssertMethodCalls(mocks.metrics, .logPrebid, parameters: [loadID, XCTMethodSomeParameter<[MetricsEvent]> { events in
            XCTAssertEqual(events.count, 0)
        }])
        // check that partnerController's routeFechBidderInfo has completed
        XCTAssertTrue(completed)
        
        // make adapter1 finish just to make sure that nothing happens
        completed = false
        adapter1Completion(["this is a": "late response"])
        XCTAssertFalse(completed)
    }
    
    /// Validates that routeFetchBidderInfo logs proper latencies according to the time adapters finish their fetching.
    func testRouteFetchBidderInformationLogsProperLatencies() {
        setUp3Adapters()
        let group = mocks.taskDispatcher.returnGroup
        group.executedFinishedCompletionImmediately = false
        
        // call routeFetchBidderInfo
        var completed = false
        let startDate = Date()
        let request = PreBidRequest(chartboostPlacement: "some placement", format: .interstitial, loadID: loadID)
        partnerController.routeFetchBidderInformation(request: request) { result in
            XCTAssertNotNil(result)
            completed = true
        }
        
        // check that adapters are asked to fetch bidder info
        var adapter1Completion: ([String: String]?) -> Void = { _ in }
        XCTAssertMethodCalls(adapter1, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter1Completion = $0 }])
        var adapter2Completion: ([String: String]?) -> Void = { _ in }
        XCTAssertMethodCalls(adapter2, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter2Completion = $0 }])
        var adapter3Completion: ([String: String]?) -> Void = { _ in }
        XCTAssertMethodCalls(adapter3, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter3Completion = $0 }])
        
        // make adapter1 finish
        let adapter1EndDate = Date()
        adapter1Completion([:])
        
        wait(0.5)
        
        // make adapter3 finish
        let adapter3EndDate = Date()
        adapter3Completion([:])
        
        wait(1)
        
        // make adapter2 finish
        let adapter2EndDate = Date()
        adapter2Completion([:])
        
        // make task group finish, which should trigger the completion
        group.finishedCompletion()
        
        // check that event is logged
        XCTAssertMethodCalls(mocks.metrics, .logPrebid, parameters: [loadID, XCTMethodSomeParameter<[MetricsEvent]> { [self] events in
            XCTAssertEqual(events.count, 3)
            XCTAssert(events.contains(where: { $0.partnerIdentifier == adapter1.partnerIdentifier }))
            XCTAssert(events.contains(where: { $0.partnerIdentifier == adapter2.partnerIdentifier }))
            XCTAssert(events.contains(where: { $0.partnerIdentifier == adapter3.partnerIdentifier }))
            
            let adapter1Latency = events.first(where: { $0.partnerIdentifier == adapter1.partnerIdentifier })?.duration ?? 0
            let adapter2Latency = events.first(where: { $0.partnerIdentifier == adapter2.partnerIdentifier })?.duration ?? 0
            let adapter3Latency = events.first(where: { $0.partnerIdentifier == adapter3.partnerIdentifier })?.duration ?? 0
            
            // check latency with 0.2 error margins so slow CI succeeds
            // adapter1 latency should be close to 0s
            XCTAssertGreaterThanOrEqual(adapter1Latency, adapter1EndDate.timeIntervalSince(startDate) - 0.2)
            XCTAssertLessThan(adapter1Latency, adapter1EndDate.timeIntervalSince(startDate) + 0.2)
            // adapter2 latency should be close to 1.5s
            XCTAssertGreaterThanOrEqual(adapter2Latency, adapter2EndDate.timeIntervalSince(startDate) - 0.2)
            XCTAssertLessThan(adapter2Latency, adapter2EndDate.timeIntervalSince(startDate) + 0.2)

            // adapter3 latency should be close to 0.5s
            XCTAssertGreaterThanOrEqual(adapter3Latency, adapter3EndDate.timeIntervalSince(startDate) - 0.2)
            XCTAssertLessThan(adapter3Latency, adapter3EndDate.timeIntervalSince(startDate) + 0.2)
            // check that adapter1Latency < adapter3Latency < adapter2Latency
            XCTAssertLessThan(adapter1Latency, adapter3Latency)
            XCTAssertLessThan(adapter3Latency, adapter2Latency)
        }])
        // check that partnerController's routeFechBidderInfo has completed
        XCTAssertTrue(completed)
    }
    
    // MARK: - Privacy methods
    
    func testDidChangeGDPR() {
        setUp3Adapters()
        
        mocks.consentSettings.isSubjectToGDPR = true
        mocks.consentSettings.gdprConsent = .granted
        partnerController.didChangeGDPR()
        
        XCTAssertMethodCalls(adapter1, .setGDPR, parameters: [true, GDPRConsentStatus.granted])
        XCTAssertMethodCalls(adapter2, .setGDPR, parameters: [true, GDPRConsentStatus.granted])
        XCTAssertMethodCalls(adapter3, .setGDPR, parameters: [true, GDPRConsentStatus.granted])
    }
    
    func testDidChangeCCPA() {
        setUp3Adapters()
        
        mocks.consentSettings.ccpaConsent = false
        mocks.consentSettings.ccpaPrivacyString = "13k2o"
        partnerController.didChangeCCPA()
        
        XCTAssertMethodCalls(adapter1, .setCCPA, parameters: [false, "13k2o"])
        XCTAssertMethodCalls(adapter2, .setCCPA, parameters: [false, "13k2o"])
        XCTAssertMethodCalls(adapter3, .setCCPA, parameters: [false, "13k2o"])
    }
    
    func testDidChangeCOPPA() {
        setUp3Adapters()
        
        mocks.consentSettings.isSubjectToCOPPA = true
        partnerController.didChangeCOPPA()
        
        XCTAssertMethodCalls(adapter1, .setCOPPA, parameters: [true])
        XCTAssertMethodCalls(adapter2, .setCOPPA, parameters: [true])
        XCTAssertMethodCalls(adapter3, .setCOPPA, parameters: [true])
    }
}

// MARK: - Helpers

private extension PartnerAdapterControllerTests {
    /// Convenience method to set up the partner controller so its 3 adapters are ready to load ads.
    func setUp3Adapters() {
        let configurations = [
            adapter1.partnerIdentifier: partnerConfig1,
            adapter2.partnerIdentifier: partnerConfig2,
            adapter3.partnerIdentifier: partnerConfig3
        ]
        let classNames = Set(["C1", "C2", "C3"])
        
        partnerController.setUpAdapters(configurations: configurations, adapterClasses: classNames, skipping: [], completion: { _ in })
        
        // get set up completion handlers for 3 adapters
        var adapter1SetUpCompletion: (Error?) -> Void = { _ in }
        var adapter2SetUpCompletion: (Error?) -> Void = { _ in }
        var adapter3SetUpCompletion: (Error?) -> Void = { _ in }
        XCTAssertMethodCalls(adapter1, .setUp, parameters: [partnerConfig1, XCTMethodCaptureParameter { adapter1SetUpCompletion = $0 }])
        XCTAssertMethodCalls(adapter2, .setUp, parameters: [partnerConfig2, XCTMethodCaptureParameter { adapter2SetUpCompletion = $0 }])
        XCTAssertMethodCalls(adapter3, .setUp, parameters: [partnerConfig3, XCTMethodCaptureParameter { adapter3SetUpCompletion = $0 }])

        adapter1SetUpCompletion(nil)
        adapter2SetUpCompletion(nil)
        adapter3SetUpCompletion(nil)
        
        mocks.metrics.removeAllRecords()  // clean up metrics initialization event so it does not affect the test
    }
    
    func wait(_ duration: TimeInterval) {
        let expectation = XCTestExpectation(description: "wait for \(duration) seconds")
        expectation.isInverted = true
        wait(for: [expectation], timeout: duration)
    }
}

private extension PartnerAdapter {
    var info: PartnerAdapterInfo {
        PartnerAdapterInfo(
            partnerVersion: partnerSDKVersion,
            adapterVersion: adapterVersion,
            partnerIdentifier: partnerIdentifier,
            partnerDisplayName: partnerDisplayName
        )
    }
}
