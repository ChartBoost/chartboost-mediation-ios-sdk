// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class ChartboostMediationAdShowResultTests: HeliumTestCase {
    
    func testInitWithError() {
        let error = ChartboostMediationError(code: .loadFailureUnknown)
        let result = ChartboostMediationAdShowResult(error: error, metrics: ["abc": 123])
        
        XCTAssertAnyEqual(result.metrics, ["abc": 123])
        XCTAssertIdentical(result.error, error)
    }
    
    func testInitWithNoError() {
        let result = ChartboostMediationAdShowResult(error: nil, metrics: ["abc": 123])
        
        XCTAssertAnyEqual(result.metrics, ["abc": 123])
        XCTAssertNil(result.error)
    }
}
