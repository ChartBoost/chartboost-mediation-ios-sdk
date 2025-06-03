// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class InfoPlistTests: ChartboostMediationTestCase {
    func testSKANIDsFromInfoPlist() {
        @Injected(\.bundleInfo) var bundleInfo
        let skanIDs = InfoPlist().skAdNetworkIDs
        XCTAssertEqual(skanIDs, ["test-0.skadnetwork", "test-1.skadnetwork", "test-2.skadnetwork"])
    }
}
