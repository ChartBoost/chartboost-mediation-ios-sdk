// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class ChartboostMediationFullscreenAdLoadResultTests: HeliumTestCase {

    func testInitWithError() {
        let error = ChartboostMediationError(code: .loadFailureUnknown)
        let result = ChartboostMediationFullscreenAdLoadResult(ad: nil, error: error, loadID: "hello", metrics: ["abc": 123])
        
        XCTAssertNil(result.ad)
        XCTAssertEqual(result.loadID, "hello")
        XCTAssertAnyEqual(result.metrics, ["abc": 123])
        XCTAssertIdentical(result.error, error)
    }
    
    func testInitWithAd() {
        let ad = ChartboostMediationFullscreenAdMock()
        let result = ChartboostMediationFullscreenAdLoadResult(ad: ad, error: nil, loadID: "hello", metrics: ["abc": 123])
        
        XCTAssertIdentical(result.ad, ad)
        XCTAssertEqual(result.loadID, "hello")
        XCTAssertAnyEqual(result.metrics, ["abc": 123])
        XCTAssertNil(result.error)
    }
}
