// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class TestModeInfoTests: XCTestCase {

    /// Copied from `TestModeInfo`.
    enum EnvKey {
        static let rateLimitingOverride = "CB_MEDIATION_RATE_LIMITING_OVERRIDE"
        static let sdkAPIHostOverride = "CB_MEDIATION_SDK_API_HOST_OVERRIDE"

        static var allKeys: [String] {
            [rateLimitingOverride, sdkAPIHostOverride]
        }
    }

    override func tearDown() {
        EnvKey.allKeys.forEach {
            unsetenv($0.cString(using: .utf8))
        }
    }

    func testRateLimitingOverride() throws {
        let testModeInfo = TestModeInfo()

        // Part 1: Env flag is unset
        unsetenv(EnvKey.rateLimitingOverride)
        XCTAssert(testModeInfo.isRateLimitingEnabled)

        // Part 2: Env flag is set with expected value "OFF"
        setenv(EnvKey.rateLimitingOverride, "OFF", 1)
        XCTAssertFalse(testModeInfo.isRateLimitingEnabled)

        // Part 3: Env flag is set with unexpected value "ON"
        setenv(EnvKey.rateLimitingOverride, "ON", 1)
        XCTAssert(testModeInfo.isRateLimitingEnabled)

        // Part 4: Env flag is unset again
        unsetenv(EnvKey.rateLimitingOverride)
        XCTAssert(testModeInfo.isRateLimitingEnabled)
    }

    func testSDKAPIHostOverride() throws {
        let testModeInfo = TestModeInfo()

        // Part 1: Env flag is unset
        unsetenv(EnvKey.sdkAPIHostOverride)
        XCTAssertNil(testModeInfo.sdkAPIHostOverride)

        // Part 2: Env flag is set with valid URL string
        setenv(EnvKey.sdkAPIHostOverride, "www.test.com", 1)
        XCTAssertEqual(testModeInfo.sdkAPIHostOverride, "www.test.com")

        // Part 3: Env flag is set with invalid URL string
        setenv(EnvKey.sdkAPIHostOverride, "invalid_url", 1)
        XCTAssertEqual(testModeInfo.sdkAPIHostOverride, "invalid_url")

        // Part 4: Env flag is unset again
        unsetenv(EnvKey.sdkAPIHostOverride)
        XCTAssertNil(testModeInfo.sdkAPIHostOverride)
    }
}
