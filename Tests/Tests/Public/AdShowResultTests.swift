// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class ChartboostMediationAdShowResultTests: ChartboostMediationTestCase {
    
    func testInitWithError() {
        let error = ChartboostMediationError(code: .loadFailureUnknown)
        let result = AdShowResult(error: error, metrics: ["abc": 123])
        
        XCTAssertAnyEqual(result.metrics, ["abc": 123])
        XCTAssertIdentical(result.error, error)
    }
    
    func testInitWithNoError() {
        let result = AdShowResult(error: nil, metrics: ["abc": 123])
        
        XCTAssertAnyEqual(result.metrics, ["abc": 123])
        XCTAssertNil(result.error)
    }
}
