// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class ChartboostMediationAdLoadResultTests: ChartboostMediationTestCase {

    func testInitWithError() {
        let error = ChartboostMediationError(code: .loadFailureUnknown)
        let result = ChartboostMediationAdLoadResult(error: error, loadID: "hello", metrics: ["abc": 123])
        
        XCTAssertEqual(result.loadID, "hello")
        XCTAssertAnyEqual(result.metrics, ["abc": 123])
        XCTAssertIdentical(result.error, error)
    }
    
    func testInitWithNoError() {
        let result = ChartboostMediationAdLoadResult(error: nil, loadID: "hello", metrics: ["abc": 123])
        
        XCTAssertEqual(result.loadID, "hello")
        XCTAssertAnyEqual(result.metrics, ["abc": 123])
        XCTAssertNil(result.error)
    }
}
