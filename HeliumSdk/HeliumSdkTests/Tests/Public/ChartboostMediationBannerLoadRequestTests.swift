// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import Foundation
import XCTest

class ChartboostMediationBannerLoadRequestTests: ChartboostMediationTestCase {
    func testIsEqual() {
        var request1: ChartboostMediationBannerLoadRequest = .test(placement: "placement", size: .adaptive(width: 100.0, maxHeight: 50.0))
        var request2: ChartboostMediationBannerLoadRequest = .test(placement: "placement", size: .adaptive(width: 100, maxHeight: 50))
        XCTAssertEqual(request1, request2)

        request1 = .test(placement: "placement1")
        request2 = .test(placement: "placement2")
        XCTAssertNotEqual(request1, request2)

        request1 = .test(size: .standard)
        request2 = .test(size: .adaptive(width: 320.0, maxHeight: 50.0))
        XCTAssertNotEqual(request1, request2)

        request1 = .test(size: .adaptive(width: 99.0, maxHeight: 50.0))
        request2 = .test(size: .adaptive(width: 100.0, maxHeight: 50.0))
        XCTAssertNotEqual(request1, request2)
    }
}

