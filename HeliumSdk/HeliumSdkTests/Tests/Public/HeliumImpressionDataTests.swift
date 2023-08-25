// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class HeliumImpressionDataTests: HeliumTestCase {

    /// Validates that ILRD payloads with JSON null values will have those entries removed.
    func testJSONNullParsing() {
        // Preconditions
        let placement = "some name"
        let payload = [
            "valid": 1,
            "invalid": NSNull()
        ] as [String : Any]
        
        let ilrd = HeliumImpressionData(placement: placement, jsonData:payload)
        XCTAssertNotNil(ilrd)
        XCTAssertNotNil(ilrd.jsonData)
        XCTAssertNotNil(ilrd.jsonData["valid"])
        XCTAssertNil(ilrd.jsonData["invalid"])
    }
}
