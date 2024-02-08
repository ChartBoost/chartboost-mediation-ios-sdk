// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class FullscreenAdTests: ChartboostMediationTestCase {

    lazy var ad = FullscreenAd(request: request, winningBidInfo: winningBidInfo, controller: mocks.adController)
    let request = ChartboostMediationAdLoadRequest(placement: "some placement", keywords: ["some": "keywords"])
    let winningBidInfo: [String: Any] = ["hello": 1, "abc": ["1", "2"]]
    
    override func setUp() {
        super.setUp()
        
        // force ad init
        _ = ad
        // clear records to ignore the AdController addObserver() call made on FullscreenAd init
        // This is just for convenience so we don't need to think about this call on every test
        mocks.adController.removeAllRecords()
    }
    
    /// Validates that custom data is synced between the ad and the controller
    func testCustomData() {
        mocks.adController.customData = nil
        XCTAssertNil(ad.customData)
        XCTAssertNil(mocks.adController.customData)
        
        mocks.adController.customData = "hello"
        XCTAssertEqual(ad.customData, "hello")
        XCTAssertEqual(mocks.adController.customData, "hello")
        
        ad.customData = "bye"
        XCTAssertEqual(ad.customData, "bye")
        XCTAssertEqual(mocks.adController.customData, "bye")
        
        ad.customData = nil
        XCTAssertNil(ad.customData)
        XCTAssertNil(mocks.adController.customData)
    }
    
    /// Validates that the ad has proper property values on init
    func testInit() {
        XCTAssertNil(ad.delegate)
        XCTAssertEqual(ad.request, request)
        XCTAssertAnyEqual(ad.winningBidInfo, winningBidInfo)
    }
    
    /// Validates that the ad sets itself as the AdController delegate on init.
    func testInitSetsSelfAsControllerDelegate() {
        let ad = FullscreenAd(request: request, winningBidInfo: winningBidInfo, controller: mocks.adController)
        
        XCTAssertIdentical(ad, mocks.adController.delegate)
    }
    
    /// Validates that ad show succeeds when the controller reports a successful show.
    func testShowSucceedsWhenControllerSucceeds() {
        let viewController = UIViewController()
        
        // Show
        var finished = false
        ad.show(with: viewController) { result in
            // Check the result has no error
            XCTAssertNil(result.error)
            XCTAssertNil(result.metrics)
            finished = true
        }
        
        // Check we are not finished since the ad controller hasn't completed yet
        XCTAssertFalse(finished)
        
        // Check that controller is called
        var completion: (AdShowResult) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adController, .showAd, parameters: [viewController, XCTMethodCaptureParameter { completion = $0 }])
        
        // Finish the controller operation with no error
        completion(AdShowResult(error: nil, metrics: nil))
        
        // Check that we finished
        XCTAssertTrue(finished)
    }
    
    /// Validates that ad show fails when the controller reports a failed show.
    func testShowFailsWhenControllerFails() {
        let viewController = UIViewController()
        let expectedError = ChartboostMediationError(code: .showFailureNoFill)
        let expectedRawMetrics: [String: Any] = ["hello": 23, "babab": "asdasfd"]
        
        // Show
        var finished = false
        ad.show(with: viewController) { result in
            // Check the result contains the error
            XCTAssertIdentical(result.error, expectedError)
            XCTAssertAnyEqual(result.metrics, expectedRawMetrics)
            finished = true
        }
        
        // Check we are not finished since the ad controller hasn't completed yet
        XCTAssertFalse(finished)
        
        // Check that controller is called
        var completion: (AdShowResult) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.adController, .showAd, parameters: [viewController, XCTMethodCaptureParameter { completion = $0 }])
        
        // Finish the controller operation with error
        completion(AdShowResult(error: expectedError, metrics: expectedRawMetrics))
        
        // Check that we finished
        XCTAssertTrue(finished)
    }
    
    /// Validates that invalidate() calls are forwarded to the controller.
    func testInvalidate() {
        ad.invalidate()
        
        XCTAssertMethodCalls(mocks.adController, .clearLoadedAd)
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidTrackImpression() {
        ad.delegate = mocks.fullscreenAdDelegate
        
        ad.didTrackImpression()
        
        XCTAssertMethodCalls(mocks.fullscreenAdDelegate, .didRecordImpression, parameters: [ad])
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidClick() {
        ad.delegate = mocks.fullscreenAdDelegate
        
        ad.didClick()
        
        XCTAssertMethodCalls(mocks.fullscreenAdDelegate, .didClick, parameters: [ad])
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidReward() {
        ad.delegate = mocks.fullscreenAdDelegate
        
        ad.didReward()
        
        XCTAssertMethodCalls(mocks.fullscreenAdDelegate, .didReward, parameters: [ad])
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidDismiss() {
        ad.delegate = mocks.fullscreenAdDelegate
        let error = ChartboostMediationError(code: .internal)
        
        ad.didDismiss(error: error)
        
        XCTAssertMethodCalls(mocks.fullscreenAdDelegate, .didClose, parameters: [ad, error])
    }
    
    /// Validates that the ad forwards the delegate method call.
    func testDidExpire() {
        ad.delegate = mocks.fullscreenAdDelegate
        
        ad.didExpire()
        
        XCTAssertMethodCalls(mocks.fullscreenAdDelegate, .didExpire, parameters: [ad])
    }
}
