// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class ChartboostMediationAdLoadRequestTests: ChartboostMediationTestCase {

    func testInitWithoutKeywords() {
        let request = ChartboostMediationAdLoadRequest(placement: "hello")
        
        XCTAssertEqual(request.placement, "hello")
        XCTAssertAnyEqual(request.keywords, [String: String]())
    }
    
    func testInitWithKeywords() {
        let request = ChartboostMediationAdLoadRequest(placement: "hello", keywords: ["asdf": "1234"])
        
        XCTAssertEqual(request.placement, "hello")
        XCTAssertAnyEqual(request.keywords, ["asdf": "1234"])
    }
}
