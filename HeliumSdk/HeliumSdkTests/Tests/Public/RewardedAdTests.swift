// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class RewardedAdTests: ChartboostMediationTestCase {

    lazy var rewarded = RewardedAd(
        heliumPlacement: placement,
        delegate: mocks.rewardedDelegate,
        controller: mocks.adController
    )
    let placement = "some placement"
    let delegate = HeliumRewardedAdDelegateMock()
    let controller = AdControllerMock()
    let taskDispatcher = TaskDispatcherMock()
    var lastLoadAdCompletion: ((AdLoadResult) -> Void)?

    override func setUp() {
        super.setUp()
        
        // force AdController init
        _ = rewarded
        // clear records to ignore the AdController addObserver() call made on RewardedAd init
        // This is just for convenience so we don't need to think about this call on every test
        mocks.adController.removeAllRecords()
    }
    
    /// Validates that the ad adds itself as an observer for AdController events on init.
    func testInitAddsSelfAsControllerObserver() {
        let rewarded = RewardedAd(
            heliumPlacement: placement,
            delegate: mocks.rewardedDelegate,
            controller: mocks.adController
        )
        
        XCTAssertMethodCalls(mocks.adController, .addObserver, parameters: [rewarded])
    }
    
    /// Validates that the ad load succeeds when the controller reports a successful load.
    func testLoadSucceedsWhenControllerSucceeds() {
        // Load
        rewarded.load()
        
        // Check that controller is called
        assertAdControllerLoad()

        // Delegate is not called yet since operation is not finished
        XCTAssertNoMethodCalls(delegate)
        
        // Finish the controller operation
        let ad = LoadedAd.test()
        lastLoadAdCompletion?(AdLoadResult(result: .success(ad), metrics: nil))
        
        // Check delegate is called with the proper bid info
        XCTAssertMethodCalls(mocks.rewardedDelegate, .didLoad, parameters: [placement, ad.request.loadID, ad.bidInfo, nil])
    }
    
    /// Validates that the ad load fails when the controller reports a failed load.
    func testLoadFailsWhenControllerFails() {
        // Load
        rewarded.load()

        // Check that controller is called
        assertAdControllerLoad()

        // Delegate is not called yet since operation is not finished
        XCTAssertNoMethodCalls(delegate)
        
        // Finish the controller operation
        lastLoadAdCompletion?(AdLoadResult(result: .failure(ChartboostMediationError(code: .partnerError)), metrics: nil))
        
        // Check delegate is called with the proper error
        XCTAssertMethodCalls(mocks.rewardedDelegate, .didLoad, parameters: [placement, XCTMethodIgnoredParameter(), XCTMethodIgnoredParameter(), XCTMethodSomeParameter<ChartboostMediationError> {
            XCTAssertEqual($0.code, ChartboostMediationError.Code.partnerError.rawValue)
        }])
    }
    
    /// Validates that the ad load passes the keywords dictionary on load requests when set by the user.
    func testLoadForwardsKeywordsWhenAvailable() {
        // Set keywords
        rewarded.keywords = HeliumKeywords(["hello": "1234"])
        
        // Load
        rewarded.load()

        // Check that controller is called with the expected request keywords
        assertAdControllerLoad(keywords: ["hello": "1234"])
    }
    
    /// Validates that clearLoadedAd() returns a proper value based on what the controller says.
    func testClearLoadedAd() {
        mocks.adController.setReturnValue(true, for: .clearLoadedAd)
        
        rewarded.clearLoadedAd()
        
        XCTAssertMethodCalls(mocks.adController, .clearLoadedAd)
    }
    
    /// Validates that ad show succeeds when the controller reports a successful show.
    func testShowSucceedsWhenControllerSucceeds() {
        // Show
        let viewController = UIViewController()
        rewarded.show(with: viewController)
        
        // Check that controller is called
        var completion: (AdShowResult) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adController, .showAd, parameters: [viewController, XCTMethodCaptureParameter { completion = $0 }])
        // Delegate is not called yet since operation is not finished
        XCTAssertNoMethodCalls(delegate)
        
        // Finish the controller operation
        completion(AdShowResult(error: nil, metrics: nil))
        
        // Check delegate is called with nil error
        XCTAssertMethodCalls(mocks.rewardedDelegate, .didShow, parameters: [placement, nil])
    }
    
    /// Validates that ad show fails when the controller reports a failed show.
    func testShowFailsWhenControllerFails() {
        // Show
        let viewController = UIViewController()
        rewarded.show(with: viewController)
        
        // Check that controller is called
        var completion: (AdShowResult) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adController, .showAd, parameters: [viewController, XCTMethodCaptureParameter { completion = $0 }])
        // Delegate is not called yet since operation is not finished
        XCTAssertNoMethodCalls(delegate)
        
        // Finish the controller operation
        completion(AdShowResult(error: ChartboostMediationError(code: .loadFailureUnknown), metrics: nil))
        
        // Check delegate is called with proper error
        XCTAssertMethodCalls(mocks.rewardedDelegate, .didShow, parameters: [placement, XCTMethodSomeParameter<ChartboostMediationError> {
            XCTAssertEqual($0.code, ChartboostMediationError.Code.loadFailureUnknown.rawValue)
        }])
    }
    
    /// Validates that the isReadyToShow value corresponds to what the controller says.
    func testIsReadyToShow() {
        mocks.adController.isReadyToShowAd = true
        
        XCTAssertTrue(rewarded.readyToShow())
        
        mocks.adController.isReadyToShowAd = false
        
        XCTAssertFalse(rewarded.readyToShow())
    }
    
    /// Validates that the customData value is forwarded to the mocks.adController.
    func testCustomData() {
        rewarded.customData = nil
        
        XCTAssertNil(rewarded.customData)
        XCTAssertNil(mocks.adController.customData)
        
        rewarded.customData = "hello"
        
        XCTAssertEqual(rewarded.customData, "hello")
        XCTAssertEqual(mocks.adController.customData, "hello")
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidTrackImpression() {
        rewarded.didTrackImpression()
        
        XCTAssertMethodCalls(mocks.rewardedDelegate, .didRecordImpression, parameters: [placement])
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidClick() {
        rewarded.didClick()
        
        XCTAssertMethodCalls(mocks.rewardedDelegate, .didClick, parameters: [placement, nil])
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidReward() {
        rewarded.didReward()
        
        XCTAssertMethodCalls(mocks.rewardedDelegate, .didGetReward, parameters: [placement])
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidDismiss() {
        rewarded.didDismiss(error: nil)
        
        XCTAssertMethodCalls(mocks.rewardedDelegate, .didClose, parameters: [placement, nil])
        
        rewarded.didDismiss(error: ChartboostMediationError(code: .adServerError))
        
        XCTAssertMethodCalls(mocks.rewardedDelegate, .didClose, parameters: [placement, XCTMethodSomeParameter<ChartboostMediationError> {
            XCTAssertEqual($0.code, ChartboostMediationError.Code.adServerError.rawValue)
        }])
    }
}

// MARK: - Helpers

private extension RewardedAdTests {
    typealias RequestID = String

    func expectedLoadRequest(loadID: String = "", keywords: [String: String]?) -> AdLoadRequest {
        AdLoadRequest(
            adSize: nil,
            adFormat: .rewarded,
            keywords: keywords,
            heliumPlacement: placement,
            loadID: loadID
        )
    }
    
    func assertAdControllerLoad(keywords: [String: String]? = nil) {
        let expectedRequest = expectedLoadRequest(keywords: keywords)
        XCTAssertMethodCalls(mocks.adController, .loadAd, parameters: [
            XCTMethodSomeParameter<AdLoadRequest> {
                XCTAssertEqual($0.adSize, expectedRequest.adSize)
                XCTAssertEqual($0.adFormat, expectedRequest.adFormat)
                XCTAssertEqual($0.heliumPlacement, expectedRequest.heliumPlacement)
                XCTAssertEqual($0.keywords, expectedRequest.keywords)
                XCTAssertFalse($0.loadID.isEmpty)
            },
            nil,
            XCTMethodCaptureParameter { self.lastLoadAdCompletion = $0 }
        ])
    }
}
