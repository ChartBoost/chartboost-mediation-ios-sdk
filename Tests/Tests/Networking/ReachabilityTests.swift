// Copyright 2025-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import XCTest

class NetworkStatusProviderTests: ChartboostMediationTestCase {
    let reachability = ReachabilityMonitor.make()

    /// We can't fully unit test this since it depends on the current network connectivity.
    /// These are some sanity checks to ensure basic functionality and that nothing crashes.
    func testSanityChecks() {
        reachability.startNotifier()
        XCTAssertEqual(reachability.status, .reachableViaWiFi) // assuming tests are run on simulator with WiFi
        reachability.stopNotifier()
    }
}
