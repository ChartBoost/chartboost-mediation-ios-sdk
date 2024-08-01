// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class AdLoadResultTests: ChartboostMediationTestCase {

    func testInitWithError() {
        let error = ChartboostMediationError(code: .loadFailureUnknown)
        let result = AdLoadResult(error: error, loadID: "hello", metrics: ["abc": 123], winningBidInfo: ["hello": 1, "abc": ["1", "2"]])

        XCTAssertEqual(result.loadID, "hello")
        XCTAssertAnyEqual(result.metrics, ["abc": 123])
        XCTAssertIdentical(result.error, error)
        XCTAssertAnyEqual(result.winningBidInfo, ["hello": 1, "abc": ["1", "2"]])
    }
    
    func testInitWithNoError() {
        let result = AdLoadResult(error: nil, loadID: "hello", metrics: ["abc": 123], winningBidInfo: nil)
        
        XCTAssertEqual(result.loadID, "hello")
        XCTAssertAnyEqual(result.metrics, ["abc": 123])
        XCTAssertNil(result.error)
    }
}
