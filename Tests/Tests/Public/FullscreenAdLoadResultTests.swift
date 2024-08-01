// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class FullscreenAdLoadResultTests: ChartboostMediationTestCase {

    /// Validates that the type constructor creates a model with the expected properties.
    func testInitWithError() {
        let error = ChartboostMediationError(code: .loadFailureUnknown)
        let result = FullscreenAdLoadResult(ad: nil, error: error, loadID: "hello", metrics: ["abc": 123], winningBidInfo: nil)

        XCTAssertNil(result.ad)
        XCTAssertEqual(result.loadID, "hello")
        XCTAssertAnyEqual(result.metrics, ["abc": 123])
        XCTAssertIdentical(result.error, error)
    }
    
    func testInitWithAd() {
        let ad = FullscreenAd(request: .init(placement: "some placement"), winningBidInfo: [:], controller: AdControllerMock(), loadID: "hello")
        let result = FullscreenAdLoadResult(ad: ad, error: nil, loadID: "hello", metrics: ["abc": 123], winningBidInfo: nil)
        
        XCTAssertIdentical(result.ad, ad)
        XCTAssertEqual(result.loadID, "hello")
        XCTAssertAnyEqual(result.metrics, ["abc": 123])
        XCTAssertNil(result.error)
        XCTAssertEqual(result.ad?.loadID, "hello")
    }
}
