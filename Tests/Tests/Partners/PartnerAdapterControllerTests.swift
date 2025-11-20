// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class PartnerAdapterControllerTests: ChartboostMediationTestCase {

    lazy var partnerController = PartnerAdapterController()

    let loadID = "some load ID"

    let adapter1 = PartnerAdapterMock(configuration: PartnerAdapterConfigurationMock1.self)
    let adapter2 = PartnerAdapterMock(configuration: PartnerAdapterConfigurationMock2.self)
    let adapter3 = PartnerAdapterMock(configuration: PartnerAdapterConfigurationMock3.self)
    
    let adapterStorage1 = MutablePartnerAdapterStorage()
    let adapterStorage2 = MutablePartnerAdapterStorage()
    let adapterStorage3 = MutablePartnerAdapterStorage()

    let partnerCredentials1 = ["142": "a42", "242": "b42"]
    lazy var partnerConfig1 = PartnerConfiguration(
        credentials: partnerCredentials1,
        consents: mocks.consentSettings.consents,
        isUserUnderage: mocks.consentSettings.isUserUnderage
    )
    let partnerCredentials2 = ["1_3": "a", "2_3": "b..s"]
    lazy var partnerConfig2 = PartnerConfiguration(
        credentials: partnerCredentials2,
        consents: mocks.consentSettings.consents,
        isUserUnderage: mocks.consentSettings.isUserUnderage
    )
    let partnerCredentials3 = ["1": "a", "2": "b"]
    lazy var partnerConfig3 = PartnerConfiguration(
        credentials: partnerCredentials3,
        consents: mocks.consentSettings.consents,
        isUserUnderage: mocks.consentSettings.isUserUnderage
    )

    let viewController = UIViewController()
    let delegate = PartnerAdDelegateMock()
    
    override func setUp() {
        super.setUp()
        
        mocks.adapterFactory.setReturnValue([(adapter1, adapterStorage1), (adapter2, adapterStorage2), (adapter3, adapterStorage3)], for: .adapters)
        mocks.consentSettings.consents = ["a": "1", "b": "2"]
        mocks.consentSettings.isUserUnderage = true
    }
    
    // MARK: - SetUpAdapters
    
    /// Validates that on setup configurations that do not correspond to any adapter get ignored and available adapters for which there is no configuration also get ignored.
    func testSetUpAdaptersWithMissingAndUnknownConfigurations() {
        let credentials = [
            "uknown adapter ID": partnerCredentials3,
            adapter1.configuration.partnerID: partnerCredentials1,
            adapter2.configuration.partnerID: partnerCredentials2
        ]
        let classNames = Set(["C1", "C2", "C3"])
        
        // Set up to check that adapters get properly set up
        partnerController.setUpAdapters(credentials: credentials, adapterClasses: classNames, skipping: [], completion: { _ in })

        // adapter3 was not in the configurations map so it doesn't get initialized
        XCTAssertNoMethodCalls(adapter3)
        // adapter1 gets initialized with the proper configuration
        var adapter1SetUpCompletion: (Result<PartnerDetails, Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter1, .setUp, parameters: [partnerConfig1, XCTMethodCaptureParameter { adapter1SetUpCompletion = $0 }])
        // adapter2 gets initialized with the proper configuration
        var adapter2SetUpCompletion: (Result<PartnerDetails, Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter2, .setUp, parameters: [partnerConfig2, XCTMethodCaptureParameter { adapter2SetUpCompletion = $0 }])
        
        // At this point adapters are not initialized yet
        XCTAssertEqual(partnerController.initializedAdapterInfo, [:])
        
        // Complete adapter2 set up
        adapter2SetUpCompletion(.success([:]))

        // Now only adapter2 should be initialized
        XCTAssertEqual(partnerController.initializedAdapterInfo, [adapter2.configuration.partnerID: adapter2.info])

        // Complete adapter1 set up
        adapter1SetUpCompletion(.success([:]))

        // Now both adapters should be initialized
        XCTAssertEqual(partnerController.initializedAdapterInfo, [adapter2.configuration.partnerID: adapter2.info, adapter1.configuration.partnerID: adapter1.info])
    }
    
    /// Validates that adapters that report a failed initialization are not considered initialized by the PartnerController.
    func testSetUpAdaptersWithFailures() {
        let credentials = [
            adapter1.configuration.partnerID: partnerCredentials1,
            adapter2.configuration.partnerID: partnerCredentials2,
            adapter3.configuration.partnerID: partnerCredentials3
        ]
        let classNames = Set(["C1", "C2", "C3"])
        
        // Set up to check that adapters get properly set up
        partnerController.setUpAdapters(credentials: credentials, adapterClasses: classNames, skipping: [], completion: { _ in })

        // get set up completion handlers for 3 adapters
        var adapter1SetUpCompletion: (Result<PartnerDetails, Error>) -> Void = { _ in }
        var adapter2SetUpCompletion: (Result<PartnerDetails, Error>) -> Void = { _ in }
        var adapter3SetUpCompletion: (Result<PartnerDetails, Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter1, .setUp, parameters: [partnerConfig1, XCTMethodCaptureParameter { adapter1SetUpCompletion = $0 }])
        XCTAssertMethodCalls(adapter2, .setUp, parameters: [partnerConfig2, XCTMethodCaptureParameter { adapter2SetUpCompletion = $0 }])
        XCTAssertMethodCalls(adapter3, .setUp, parameters: [partnerConfig3, XCTMethodCaptureParameter { adapter3SetUpCompletion = $0 }])
        
        // At this point adapters are not initialized yet
        XCTAssertEqual(partnerController.initializedAdapterInfo, [:])
        
        // Complete adapter2 set up with an error
        adapter2SetUpCompletion(.failure(NSError.test()))
        // adapter2 should not be initialized
        XCTAssertEqual(partnerController.initializedAdapterInfo, [:])
        
        // Complete adapter3 set up successfully
        adapter3SetUpCompletion(.success([:]))
        // adapter3 should be initialized
        XCTAssertEqual(partnerController.initializedAdapterInfo, [adapter3.configuration.partnerID: adapter3.info])

        // Complete adapter1 set up with an error
        adapter1SetUpCompletion(.failure(NSError.test()))
        // Only adapter3 remains initialized
        XCTAssertEqual(partnerController.initializedAdapterInfo, [adapter3.configuration.partnerID: adapter3.info])
    }
    
    /// Validates that privacy consent values are set on adapters after initialization if they were called before.
    func testSetUpAdaptersAfterSettingConsentValues() {
        let credentials = [
            adapter1.configuration.partnerID: partnerCredentials1,
            adapter2.configuration.partnerID: partnerCredentials2,
            adapter3.configuration.partnerID: partnerCredentials3
        ]
        let classNames = Set(["C1", "C2", "C3"])
        
        // Set GDPR applies before initialization
        mocks.consentSettings.consents = ["key1": "value1"]

        // Set up to check that adapters get properly set up
        partnerController.setUpAdapters(credentials: credentials, adapterClasses: classNames, skipping: [], completion: { _ in })

        // get set up completion handlers for 3 adapters
        var adapter1SetUpCompletion: (Result<PartnerDetails, Error>) -> Void = { _ in }
        var adapter2SetUpCompletion: (Result<PartnerDetails, Error>) -> Void = { _ in }
        var adapter3SetUpCompletion: (Result<PartnerDetails, Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter1, .setUp, parameters: [partnerConfig1, XCTMethodCaptureParameter { adapter1SetUpCompletion = $0 }])
        XCTAssertMethodCalls(adapter2, .setUp, parameters: [partnerConfig2, XCTMethodCaptureParameter { adapter2SetUpCompletion = $0 }])
        XCTAssertMethodCalls(adapter3, .setUp, parameters: [partnerConfig3, XCTMethodCaptureParameter { adapter3SetUpCompletion = $0 }])
        
        // Complete adapter1 setup should set no new consents since they haven't changed
        adapter1SetUpCompletion(.success([:]))

        XCTAssertNoMethodCalls(adapter1)
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertNoMethodCalls(adapter3)
        
        // Set other consent key during initialization applies immediately to adapter1
        mocks.consentSettings.consents = ["key1": "value1", "key2": "value2"]
        partnerController.setConsents(mocks.consentSettings.consents, modifiedKeys: ["key2"])

        XCTAssertMethodCalls(adapter1, .setConsents, parameters: [mocks.consentSettings.consents, Set(["key2"])])
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertNoMethodCalls(adapter3)

        // Complete adapter3 setup should set both consent keys on it
        adapter3SetUpCompletion(.success([:]))

        XCTAssertNoMethodCalls(adapter1)
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertMethodCalls(adapter3, .setConsents, parameters: [mocks.consentSettings.consents, Set(["key2"])])

        // Set consent during initialization applies immediately to adapter1 and adapter3
        mocks.consentSettings.consents = ["key1": "value3", "key2": "value2"]
        partnerController.setConsents(mocks.consentSettings.consents, modifiedKeys: ["key1"])

        XCTAssertMethodCalls(adapter1, .setConsents, parameters: [mocks.consentSettings.consents, Set(["key1"])])
        XCTAssertNoMethodCalls(adapter2)
        XCTAssertMethodCalls(adapter3, .setConsents, parameters: [mocks.consentSettings.consents, Set(["key1"])])

        // Complete adapter2 setup should set all previous consents
        adapter2SetUpCompletion(.success([:]))

        XCTAssertNoMethodCalls(adapter1)
        XCTAssertMethodCalls(adapter2, .setConsents, parameters: [mocks.consentSettings.consents, Set(["key1", "key2"])])
        XCTAssertNoMethodCalls(adapter3)
    }
    
    // MARK: - RouteLoad
    
    /// Validates that routeLoad fails early if the requested partner is not available.
    func testRouteLoadFailsImmediatelyIfAdapterIsUnavailable() {
        // initialize adapters
        setUp3Adapters()
        // load ad
        var completed = false
        let request = PartnerAdLoadRequest.test(partnerID: "unknown partner ID")
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
        let ad = adapter2.returnValue(for: .makeFullscreenAd) as PartnerFullscreenAdMock
        let request = PartnerAdLoadRequest.test(partnerID: adapter2.configuration.partnerID)

        // load ad
        var completed = false
        _ = partnerController.routeLoad(request: request, viewController: viewController, delegate: delegate) { result in
            if case .success(let returnedAd) = result {
                XCTAssertIdentical(returnedAd, ad)
            } else {
                XCTFail("Unexpected failure result")
            }
            completed = true
        }

        // check partner ad is created
        XCTAssertMethodCalls(adapter2, .makeFullscreenAd, parameters: [request, delegate])
        // check partner call is made
        var partnerLoadCompletion: (Error?) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .load, parameters: [viewController, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        XCTAssertFalse(completed)
        
        // call partner completion
        partnerLoadCompletion(nil)

        // check that partner controller is done
        XCTAssertTrue(completed)
        // check adapter storage is updated
        XCTAssertAnyEqual(adapterStorage2.ads, [ad])
        // check other partners are unaffected
        XCTAssertNoMethodCalls(adapter1)
        XCTAssertNoMethodCalls(adapter3)
    }

    /// Validates that routeLoad uses the right makeAd() method to create a banner ad when requesting a banner format.
    func testRouteLoadMakesBannerForBannerFormats() {
        // initialize adapters
        setUp3Adapters()
        let ad = adapter2.returnValue(for: .makeBannerAd) as PartnerBannerAdMock
        let request = PartnerAdLoadRequest.test(partnerID: adapter2.configuration.partnerID, adFormat: .banner)

        // load ad
        var completed = false
        _ = partnerController.routeLoad(request: request, viewController: viewController, delegate: delegate) { result in
            if case .success(let returnedAd) = result {
                XCTAssertIdentical(returnedAd, ad)
            } else {
                XCTFail("Unexpected failure result")
            }
            completed = true
        }

        // check partner ad is created
        XCTAssertMethodCalls(adapter2, .makeBannerAd, parameters: [request, delegate])
        // check partner call is made
        var partnerLoadCompletion: (Error?) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .load, parameters: [viewController, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        XCTAssertFalse(completed)

        // call partner completion
        partnerLoadCompletion(nil)

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
        let request = PartnerAdLoadRequest.test(partnerID: adapter2.configuration.partnerID)
        _ = partnerController.routeLoad(request: request, viewController: viewController, delegate: delegate) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error as NSError, adapterError)
            } else {
                XCTFail("Unexpected error sent")
            }
            completed = true
        }

        // check partner ad is created
        XCTAssertMethodCalls(adapter2, .makeFullscreenAd, parameters: [request, delegate])
        let ad = adapter2.returnValue(for: .makeFullscreenAd) as PartnerFullscreenAdMock
        // check partner call is made
        var partnerLoadCompletion: (Error?) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .load, parameters: [viewController, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        XCTAssertFalse(completed)
        
        // call partner completion
        partnerLoadCompletion(adapterError)
        
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
        let request = PartnerAdLoadRequest.test(partnerID: adapter2.configuration.partnerID)
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
        XCTAssertMethodCalls(adapter2, .makeFullscreenAd, parameters: [request, delegate])
        let ad = adapter2.returnValue(for: .makeFullscreenAd) as PartnerFullscreenAdMock
        // check partner call is made
        var partnerLoadCompletion: (Error?) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .load, parameters: [viewController, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        XCTAssertFalse(completed)
        
        // call partner completion passing a NSError instead of an ChartboostMediationError
        partnerLoadCompletion(adapterError)
        
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
        adapter2.setReturnValue(adapterError, for: .makeFullscreenAd)
        
        // load ad
        var completed = false
        let request = PartnerAdLoadRequest.test(partnerID: adapter2.configuration.partnerID)
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
        XCTAssertMethodCalls(adapter2, .makeFullscreenAd, parameters: [request, delegate])
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
        let ad = adapter2.returnValue(for: .makeFullscreenAd) as PartnerFullscreenAdMock
        let request = PartnerAdLoadRequest.test(partnerID: adapter2.configuration.partnerID)

        // load ad
        var completed = false
        let cancelAction = partnerController.routeLoad(request: request, viewController: viewController, delegate: delegate) { result in
            XCTFail("Unexpected call")
            completed = true
        }
        
        // check partner ad is created
        XCTAssertMethodCalls(adapter2, .makeFullscreenAd, parameters: [request, delegate])
        // check partner call is made
        var partnerLoadCompletion: (Error?) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .load, parameters: [viewController, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        XCTAssertFalse(completed)
        
        // cancel the load operation
        cancelAction()
        
        // check that completion is not called and ad is invalidated
        XCTAssertFalse(completed)
        XCTAssertMethodCalls(ad, .invalidate)
        
        // call partner completion to make sure it is ignored
        partnerLoadCompletion(nil)

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
        let ad = PartnerFullscreenAdMock()

        // show
        var completed = false
        partnerController.routeShow(ad, viewController: viewController) { error in
            if error != nil {
                XCTFail("Unexpected failure result")
            }
            completed = true
        }

        // check that partner show was called
        var partnerCompletion: (Error?) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .show, parameters: [viewController, XCTMethodCaptureParameter { partnerCompletion = $0 }])
        XCTAssertFalse(completed)
        
        // perform partner completion
        partnerCompletion(nil)

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
        let ad = PartnerFullscreenAdMock()

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
        var partnerCompletion: (Error?) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .show, parameters: [viewController, XCTMethodCaptureParameter { partnerCompletion = $0 }])
        XCTAssertFalse(completed)
        
        // perform partner completion
        partnerCompletion(partnerError)
        
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
        let ad = PartnerFullscreenAdMock()

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
        var partnerCompletion: (Error?) -> Void = { _ in }
        XCTAssertMethodCalls(ad, .show, parameters: [viewController, XCTMethodCaptureParameter { partnerCompletion = $0 }])
        XCTAssertFalse(completed)
        
        // call partner completion passing a NSError instead of an ChartboostMediationError
        partnerCompletion(partnerError)
        
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
        let ad = adapter1.returnValue(for: .makeFullscreenAd) as PartnerFullscreenAdMock
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
        let ad = adapter1.returnValue(for: .makeFullscreenAd) as PartnerFullscreenAdMock
        // set error throw on invalidate() call
        let partnerError = ChartboostMediationError(code: .partnerError)
        ad.setReturnValue(partnerError, for: .invalidate)
        // set storage to contain ad, like it would be after a load
        adapterStorage1.ads.append(ad)
        // add other ads to storage to check that nothing happens to them
        let otherAds = [PartnerFullscreenAdMock(), PartnerFullscreenAdMock()]
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
        let ad = adapter1.returnValue(for: .makeFullscreenAd) as PartnerFullscreenAdMock
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
            adapter1.configuration.partnerID: bidderInfo1,
            adapter2.configuration.partnerID: bidderInfo2,
            adapter3.configuration.partnerID: bidderInfo3
        ]
        
        // call routeFetchBidderInfo
        var completed = false
        let request = PartnerAdPreBidRequest(
            mediationPlacement: "some placement",
            format: PartnerAdFormats.interstitial,
            bannerSize: nil, 
            partnerSettings: [:],
            keywords: [:],
            loadID: loadID,
            internalAdFormat: .interstitial
        )
        partnerController.routeFetchBidderInformation(request: request) { result in
            XCTAssertJSONEqual(result, expectedResult)
            completed = true
        }
        
        // check that adapters are asked to fetch bidder info
        var adapter1Completion: (Result<[String: String], Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter1, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter1Completion = $0 }])
        var adapter2Completion: (Result<[String: String], Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter2, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter2Completion = $0 }])
        var adapter3Completion: (Result<[String: String], Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter3, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter3Completion = $0 }])
        // check that dispatch group is set to timeout with expected value
        XCTAssertEqual(group.finishTimeout, mocks.partnerControllerConfiguration.prebidFetchTimeout)
        // check that partnerController's routeFechBidderInfo has not completed yet
        XCTAssertFalse(completed)
        
        // make adapter1 finish
        adapter1Completion(.success(bidderInfo1))
        XCTAssertFalse(completed)   // check that nothing happened yet
        
        // make adapter3 finish
        adapter3Completion(.success(bidderInfo3))
        XCTAssertFalse(completed)   // check that nothing happened yet
        
        // make adapter2 finish
        adapter2Completion(.success(bidderInfo2))
        XCTAssertFalse(completed)   // check that nothing happened yet
        
        // make task group finish, which should trigger the completion
        group.finishedCompletion()
        
        // check that event is logged
        XCTAssertMethodCalls(mocks.metrics, .logPrebid, parameters: [request, XCTMethodSomeParameter<[MetricsEvent]> { [self] events in
            XCTAssertEqual(events.count, 3)
            XCTAssert(events.contains(where: { $0.partnerID == adapter1.configuration.partnerID }))
            XCTAssert(events.contains(where: { $0.partnerID == adapter2.configuration.partnerID }))
            XCTAssert(events.contains(where: { $0.partnerID == adapter3.configuration.partnerID }))
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
        let request = PartnerAdPreBidRequest(
            mediationPlacement: "some placement",
            format: PartnerAdFormats.rewarded,
            bannerSize: nil, 
            partnerSettings: [:],
            keywords: [:],
            loadID: loadID,
            internalAdFormat: .rewarded
        )
        partnerController.routeFetchBidderInformation(request: request) { result in
            XCTAssertJSONEqual(result, [PartnerID: [String: String]]())
            completed = true
        }
        
        // make task group finish, which should trigger the completion
        group.finishedCompletion()
        
        // check that event is logged
        XCTAssertMethodCalls(mocks.metrics, .logPrebid, parameters: [request, XCTMethodSomeParameter<[MetricsEvent]> { events in
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
            adapter2.configuration.partnerID: bidderInfo2,
            adapter3.configuration.partnerID: bidderInfo3
        ]
        
        // call routeFetchBidderInfo
        var completed = false
        let request = PartnerAdPreBidRequest(
            mediationPlacement: "some placement",
            format: PartnerAdFormats.rewarded,
            bannerSize: nil, 
            partnerSettings: [:],
            keywords: [:],
            loadID: loadID,
            internalAdFormat: .rewarded
        )
        partnerController.routeFetchBidderInformation(request: request) { result in
            XCTAssertJSONEqual(result, expectedResult)  // no info for adapter1 which will time out
            completed = true
        }
        
        // check that adapters are asked to fetch bidder info
        XCTAssertMethodCalls(adapter1, .fetchBidderInformation, parameters: [request, XCTMethodIgnoredParameter()])
        var adapter2Completion: (Result<[String: String], Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter2, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter2Completion = $0 }])
        var adapter3Completion: (Result<[String: String], Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter3, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter3Completion = $0 }])
        // check that dispatch group is set to timeout with expected value
        XCTAssertEqual(group.finishTimeout, mocks.partnerControllerConfiguration.prebidFetchTimeout)
        // check that partnerController's routeFechBidderInfo has not completed yet
        XCTAssertFalse(completed)
        
        // make adapter3 finish
        adapter3Completion(.success(bidderInfo3))
        XCTAssertFalse(completed)   // check that nothing happened yet
        
        // make adapter2 finish
        adapter2Completion(.success(bidderInfo2))
        XCTAssertFalse(completed)   // check that nothing happened yet
        
        // make task group finish before adapter1 can finish, which considers it as timed out
        group.finishedCompletion()
        
        // check that event is logged
        XCTAssertMethodCalls(mocks.metrics, .logPrebid, parameters: [request, XCTMethodSomeParameter<[MetricsEvent]> { [self] events in
            XCTAssertEqual(events.count, 2)
            XCTAssert(events.contains(where: { $0.partnerID == adapter2.configuration.partnerID }))
            XCTAssert(events.contains(where: { $0.partnerID == adapter3.configuration.partnerID }))
            for event in events {
                switch event.partnerID {
                case adapter2.configuration.partnerID, adapter3.configuration.partnerID:
                    XCTAssertNil(event.error)
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
        let request = PartnerAdPreBidRequest(
            mediationPlacement: "some placement",
            format: PartnerAdFormats.banner,
            bannerSize: .standard, 
            partnerSettings: [:],
            keywords: [:],
            loadID: loadID,
            internalAdFormat: .banner
        )
        partnerController.routeFetchBidderInformation(request: request) { result in
            XCTAssertJSONEqual(result, [PartnerID: [String: String]]()) // empty result
            completed = true
        }
        
        // check that adapters are asked to fetch bidder info
        var adapter1Completion: (Result<[String: String], Error>) -> Void = { _ in }
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
        XCTAssertMethodCalls(mocks.metrics, .logPrebid, parameters: [request, XCTMethodSomeParameter<[MetricsEvent]> { events in
            XCTAssertEqual(events.count, 0)
        }])
        // check that partnerController's routeFechBidderInfo has completed
        XCTAssertTrue(completed)
        
        // make adapter1 finish just to make sure that nothing happens
        completed = false
        adapter1Completion(.success(["this is a": "late response"]))
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
        let request = PartnerAdPreBidRequest(
            mediationPlacement: "some placement",
            format: PartnerAdFormats.interstitial,
            bannerSize: nil, 
            partnerSettings: [:],
            keywords: [:],
            loadID: loadID,
            internalAdFormat: .interstitial
        )
        partnerController.routeFetchBidderInformation(request: request) { result in
            XCTAssertNotNil(result)
            completed = true
        }
        
        // check that adapters are asked to fetch bidder info
        var adapter1Completion: (Result<[String: String], Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter1, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter1Completion = $0 }])
        var adapter2Completion: (Result<[String: String], Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter2, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter2Completion = $0 }])
        var adapter3Completion: (Result<[String: String], Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter3, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter3Completion = $0 }])
        
        // make adapter1 finish
        let adapter1EndDate = Date()
        adapter1Completion(.success([:]))
        
        wait(0.5)
        
        // make adapter3 finish
        let adapter3EndDate = Date()
        adapter3Completion(.success([:]))
        
        wait(1)
        
        // make adapter2 finish
        let adapter2EndDate = Date()
        adapter2Completion(.success([:]))
        
        // make task group finish, which should trigger the completion
        group.finishedCompletion()
        
        // check that event is logged
        XCTAssertMethodCalls(mocks.metrics, .logPrebid, parameters: [request, XCTMethodSomeParameter<[MetricsEvent]> { [self] events in
            XCTAssertEqual(events.count, 3)
            XCTAssert(events.contains(where: { $0.partnerID == adapter1.configuration.partnerID }))
            XCTAssert(events.contains(where: { $0.partnerID == adapter2.configuration.partnerID }))
            XCTAssert(events.contains(where: { $0.partnerID == adapter3.configuration.partnerID }))

            let adapter1Latency = events.first(where: { $0.partnerID == adapter1.configuration.partnerID })?.duration ?? 0
            let adapter2Latency = events.first(where: { $0.partnerID == adapter2.configuration.partnerID })?.duration ?? 0
            let adapter3Latency = events.first(where: { $0.partnerID == adapter3.configuration.partnerID })?.duration ?? 0

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

    /// Validates that routeFetchBidderInfomation excludes partner errors from the final token map, but includes them
    /// in the metrics event, mapping non-standard errors to standard errors when needed.
    func testRouteFetchBidderInformationWithPartnerFailures() {
        setUp3Adapters()
        let group = mocks.taskDispatcher.returnGroup
        group.executedFinishedCompletionImmediately = false

        let bidderInfo1 = ["hello": "1234"]
        let expectedResult = [
            adapter1.configuration.partnerID: bidderInfo1,
        ]

        // call routeFetchBidderInfo
        var completed = false
        let request = PartnerAdPreBidRequest(
            mediationPlacement: "some placement",
            format: PartnerAdFormats.interstitial,
            bannerSize: nil,
            partnerSettings: [:],
            keywords: [:],
            loadID: loadID,
            internalAdFormat: .interstitial
        )
        partnerController.routeFetchBidderInformation(request: request) { result in
            // Expect the results to contain the token for only one adapter, since the other ones will be made to fail
            XCTAssertJSONEqual(result, expectedResult)
            completed = true
        }

        // check that adapters are asked to fetch bidder info
        var adapter1Completion: (Result<[String: String], Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter1, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter1Completion = $0 }])
        var adapter2Completion: (Result<[String: String], Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter2, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter2Completion = $0 }])
        var adapter3Completion: (Result<[String: String], Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter3, .fetchBidderInformation, parameters: [request, XCTMethodCaptureParameter { adapter3Completion = $0 }])
        // check that dispatch group is set to timeout with expected value
        XCTAssertEqual(group.finishTimeout, mocks.partnerControllerConfiguration.prebidFetchTimeout)
        // check that partnerController's routeFechBidderInfo has not completed yet
        XCTAssertFalse(completed)

        // make adapter1 finish
        adapter1Completion(.success(bidderInfo1))
        XCTAssertFalse(completed)   // check that nothing happened yet

        // make adapter3 finish with a standard Mediation error
        let mediationError = ChartboostMediationError(code: .prebidFailureUnsupportedAdFormat)
        adapter3Completion(.failure(mediationError))
        XCTAssertFalse(completed)   // check that nothing happened yet

        // make adapter2 finish with a non-standard generic error
        let nonMediationError = NSError.test()
        adapter2Completion(.failure(nonMediationError))
        XCTAssertFalse(completed)   // check that nothing happened yet

        // make task group finish, which should trigger the completion
        group.finishedCompletion()

        // check that event is logged with the expected errors
        XCTAssertMethodCalls(mocks.metrics, .logPrebid, parameters: [request, XCTMethodSomeParameter<[MetricsEvent]> { [self] events in
            XCTAssertEqual(events.count, 3)
            XCTAssertEqual(events[0].partnerID, adapter1.configuration.partnerID)
            XCTAssertNil(events[0].error)
            XCTAssertEqual(events[1].partnerID, adapter3.configuration.partnerID)
            XCTAssertIdentical(events[1].error, mediationError)
            XCTAssertEqual(events[2].partnerID, adapter2.configuration.partnerID)
            XCTAssertEqual(events[2].error?.chartboostMediationCode, .prebidFailureUnknown)
            XCTAssertIdentical(events[2].error?.underlyingError as? NSError, nonMediationError)
        }])
        // check that partnerController's routeFechBidderInfo has completed
        XCTAssertTrue(completed)
    }

    // MARK: - Privacy methods

    func testSetConsents() {
        setUp3Adapters()

        mocks.consentSettings.consents = ["key1": "value1", "key2": "value2"]
        partnerController.setConsents(mocks.consentSettings.consents, modifiedKeys: ["key1", "key2"])

        XCTAssertMethodCalls(adapter1, .setConsents, parameters: [mocks.consentSettings.consents, Set(["key1", "key2"])])
        XCTAssertMethodCalls(adapter2, .setConsents, parameters: [mocks.consentSettings.consents, Set(["key1", "key2"])])
        XCTAssertMethodCalls(adapter3, .setConsents, parameters: [mocks.consentSettings.consents, Set(["key1", "key2"])])
    }

    func testIsUserUnderage() {
        setUp3Adapters()

        mocks.consentSettings.isUserUnderage = true
        partnerController.setIsUserUnderage(true)

        XCTAssertMethodCalls(adapter1, .setIsUserUnderage, parameters: [true])
        XCTAssertMethodCalls(adapter2, .setIsUserUnderage, parameters: [true])
        XCTAssertMethodCalls(adapter3, .setIsUserUnderage, parameters: [true])
    }
}

// MARK: - Helpers

private extension PartnerAdapterControllerTests {
    /// Convenience method to set up the partner controller so its 3 adapters are ready to load ads.
    func setUp3Adapters() {
        let credentials = [
            adapter1.configuration.partnerID: partnerCredentials1,
            adapter2.configuration.partnerID: partnerCredentials2,
            adapter3.configuration.partnerID: partnerCredentials3
        ]
        let classNames = Set(["C1", "C2", "C3"])
        
        partnerController.setUpAdapters(credentials: credentials, adapterClasses: classNames, skipping: [], completion: { _ in })

        // get set up completion handlers for 3 adapters
        var adapter1SetUpCompletion: (Result<PartnerDetails, Error>) -> Void = { _ in }
        var adapter2SetUpCompletion: (Result<PartnerDetails, Error>) -> Void = { _ in }
        var adapter3SetUpCompletion: (Result<PartnerDetails, Error>) -> Void = { _ in }
        XCTAssertMethodCalls(adapter1, .setUp, parameters: [partnerConfig1, XCTMethodCaptureParameter { adapter1SetUpCompletion = $0 }])
        XCTAssertMethodCalls(adapter2, .setUp, parameters: [partnerConfig2, XCTMethodCaptureParameter { adapter2SetUpCompletion = $0 }])
        XCTAssertMethodCalls(adapter3, .setUp, parameters: [partnerConfig3, XCTMethodCaptureParameter { adapter3SetUpCompletion = $0 }])

        adapter1SetUpCompletion(.success([:]))
        adapter2SetUpCompletion(.success([:]))
        adapter3SetUpCompletion(.success([:]))

        mocks.metrics.removeAllRecords()  // clean up metrics initialization event so it does not affect the test
    }
    
    func wait(_ duration: TimeInterval) {
        let expectation = XCTestExpectation(description: "wait for \(duration) seconds")
        expectation.isInverted = true
        wait(for: [expectation], timeout: duration)
    }
}

private extension PartnerAdapter {
    var info: InternalPartnerAdapterInfo {
        InternalPartnerAdapterInfo(
            partnerVersion: configuration.partnerSDKVersion,
            adapterVersion: configuration.adapterVersion,
            partnerID: configuration.partnerID,
            partnerDisplayName: configuration.partnerDisplayName
        )
    }
}
