// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class AdLoaderTests: ChartboostMediationTestCase {

    let adLoader = AdLoader()
    
    /// Validates that the ad loader makes the proper requests and returns a proper result when the ad controller succeeds to load an ad.
    func testLoadFullscreenAdWithSuccess() {
        let placement = "some placement"
        let keywords = ["key1": "value 1", "key-2": "this is value 2"]
        let format: AdFormat = .rewardedInterstitial
        let request = FullscreenAdLoadRequest(placement: placement, keywords: keywords, partnerSettings: ["poiu" : "9876"])
        let expectedAd = mocks.adFactory.returnValue(for: .makeFullscreenAd) as FullscreenAd
        let expectedLoadID = "some load ID"
        let bids: [Bid] = [Bid.test(), Bid.test(), Bid.test()]
        let loadedAd = LoadedAd(bids: bids, winner: bids[0], bidInfo: ["hello": 23], partnerAd: PartnerBannerAdMock(), bannerSize: .init(size: .zero, type: .fixed), request: .test(loadID: expectedLoadID))
        mocks.adLoaderConfiguration.setReturnValue(format, for: .adFormat)

        // Load the ad
        var finished = false
        adLoader.loadFullscreenAd(with: request) { result in
            // Check we get a successful result
            XCTAssertIdentical(result.ad, expectedAd)
            XCTAssertNil(result.error)
            XCTAssertNil(result.metrics)
            XCTAssertEqual(result.loadID, expectedLoadID)
            finished = true
        }
        
        // Check we have not finished since ad controller is still loading
        XCTAssertFalse(finished)
        
        // Check that we obtained a new ad controller
        XCTAssertMethodCalls(mocks.adControllerFactory, .makeAdController)
        
        // Check that we passed the proper info to the ad controller
        let adController = mocks.adControllerFactory.returnValue(for: .makeAdController) as AdControllerMock
        var loadCompletion: (InternalAdLoadResult) -> Void = { _ in }
        XCTAssertMethodCalls(adController, .loadAd, parameters: [
            XCTMethodSomeParameter<InternalAdLoadRequest> {
                XCTAssertNil($0.adSize)
                XCTAssertEqual($0.adFormat, format)
                XCTAssertEqual($0.mediationPlacement, placement)
                XCTAssertEqual($0.keywords, keywords)
                XCTAssertFalse($0.loadID.isEmpty)
            },
            nil,    // the view controller
            XCTMethodCaptureParameter { loadCompletion = $0 }
        ])
        
        // Make the ad controller finish loading, passing no metrics to check this is properly handled
        loadCompletion(InternalAdLoadResult(result: .success(loadedAd), metrics: nil))
        
        // Check that the fullscreen ad is created with the proper info
        XCTAssertMethodCalls(mocks.adFactory, .makeFullscreenAd, parameters: [adController, loadedAd, request])
        
        // Check we finished
        XCTAssertTrue(finished)
    }
    
    /// Validates that the ad loader makes the proper requests and returns a proper result when the ad controller fails to load an ad.
    func testLoadFullscreenAdWithFailure() {
        let placement = "some placement"
        let keywords = ["key1": "value 1", "key-2": "this is value 2"]
        let format: AdFormat = .interstitial
        let request = FullscreenAdLoadRequest(placement: placement, keywords: keywords)
        let expectedError = ChartboostMediationError(code: .loadFailureAborted)
        var expectedLoadID = ""
        let expectedRawMetrics: [String: Any] = ["hello": 23, "babab": "asdasfd"]
        mocks.adLoaderConfiguration.setReturnValue(format, for: .adFormat)
        
        // Load the ad
        var finished = false
        adLoader.loadFullscreenAd(with: request) { result in
            // Check we get a successful result
            XCTAssertNil(result.ad)
            XCTAssertIdentical(result.error, expectedError)
            XCTAssertAnyEqual(result.metrics, expectedRawMetrics)
            XCTAssertEqual(result.loadID, expectedLoadID)
            finished = true
        }
        
        // Check we have not finished since ad controller is still loading
        XCTAssertFalse(finished)
        
        // Check that we obtained a new ad controller
        XCTAssertMethodCalls(mocks.adControllerFactory, .makeAdController)
        
        // Check that we passed the proper info to the ad controller
        let adController = mocks.adControllerFactory.returnValue(for: .makeAdController) as AdControllerMock
        var loadCompletion: (InternalAdLoadResult) -> Void = { _ in }
        XCTAssertMethodCalls(adController, .loadAd, parameters: [
            XCTMethodSomeParameter<InternalAdLoadRequest> {
                XCTAssertNil($0.adSize)
                XCTAssertEqual($0.adFormat, format)
                XCTAssertEqual($0.mediationPlacement, placement)
                XCTAssertEqual($0.keywords, keywords)
                XCTAssertFalse($0.loadID.isEmpty)
                expectedLoadID = $0.loadID  // save the request loadID to compare later with the one in the result
            },
            nil,    // the view controller
            XCTMethodCaptureParameter { loadCompletion = $0 }
        ])
        
        // Make the ad controller finish loading with failure, this time passing proper metrics
        loadCompletion(InternalAdLoadResult(result: .failure(expectedError), metrics: expectedRawMetrics))
        
        // Check that no fullscreen ad is created
        XCTAssertNoMethodCalls(mocks.adFactory)
        
        // Check we finished
        XCTAssertTrue(finished)
    }
    
    /// Validates that the ad loader fails immediately if it cannot find the ad format associated to the requested placement.
    func testLoadFullscreenAdWithUnknownPlacement() {
        let request = FullscreenAdLoadRequest(placement: "")
        let expectedError = ChartboostMediationError(code: .loadFailureInvalidChartboostMediationPlacement)
        mocks.adLoaderConfiguration.setReturnValue(nil, for: .adFormat)
        
        // Load the ad
        var finished = false
        adLoader.loadFullscreenAd(with: request) { result in
            // Check we get a successful result
            XCTAssertNil(result.ad)
            XCTAssertEqual(result.error, expectedError)
            XCTAssertNil(result.metrics)
            XCTAssertEqual(result.loadID, "")
            finished = true
        }
        
        // Check we finished
        XCTAssertTrue(finished)
    }
    
    /// Validates that the ad loader fails immediately if the ad format associated to the requested placement is a banner.
    func testLoadFullscreenAdWithBannerPlacement() {
        let request = FullscreenAdLoadRequest(placement: "")
        let expectedError = ChartboostMediationError(code: .loadFailureMismatchedAdFormat)
        mocks.adLoaderConfiguration.setReturnValue(AdFormat.banner, for: .adFormat)
        
        // Load the ad
        var finished = false
        adLoader.loadFullscreenAd(with: request) { result in
            // Check we get a successful result
            XCTAssertNil(result.ad)
            XCTAssertEqual(result.error, expectedError)
            XCTAssertNil(result.metrics)
            XCTAssertEqual(result.loadID, "")
            finished = true
        }
        
        // Check we finished
        XCTAssertTrue(finished)
    }

    func testLoadFullscreenAdWithAdaptiveBannerPlacement() {
        let request = FullscreenAdLoadRequest(placement: "")
        let expectedError = ChartboostMediationError(code: .loadFailureMismatchedAdFormat)
        mocks.adLoaderConfiguration.setReturnValue(AdFormat.adaptiveBanner, for: .adFormat)

        // Load the ad
        var finished = false
        adLoader.loadFullscreenAd(with: request) { result in
            // Check we get a successful result
            XCTAssertNil(result.ad)
            XCTAssertEqual(result.error, expectedError)
            XCTAssertNil(result.metrics)
            XCTAssertEqual(result.loadID, "")
            finished = true
        }

        // Check we finished
        XCTAssertTrue(finished)
    }
}
