// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class BackendAPITests: HeliumTestCase {

    func testAPIHostOverride() throws {
        let testModeInfoMock = mocks.environment.testMode as! EnvironmentMock.TestModeInfoProviderMock

        // Reset with nil
        testModeInfoMock.rtbAPIHostOverride = nil
        testModeInfoMock.sdkAPIHostOverride = nil
        XCTAssertEqual(BackendAPI.rtb.scheme, "https")
        XCTAssertEqual(BackendAPI.sdk.scheme, "https")
        XCTAssertEqual(BackendAPI.rtb.host, "helium-rtb.chartboost.com")
        XCTAssertEqual(BackendAPI.sdk.host, "helium-sdk.chartboost.com")

        // Reset with empty string
        testModeInfoMock.rtbAPIHostOverride = ""
        testModeInfoMock.sdkAPIHostOverride = ""
        XCTAssertEqual(BackendAPI.rtb.scheme, "https")
        XCTAssertEqual(BackendAPI.sdk.scheme, "https")
        XCTAssertEqual(BackendAPI.rtb.host, "helium-rtb.chartboost.com")
        XCTAssertEqual(BackendAPI.sdk.host, "helium-sdk.chartboost.com")

        // Failure: required scheme missing
        testModeInfoMock.rtbAPIHostOverride = "rtb.com"
        testModeInfoMock.sdkAPIHostOverride = "sdk.com"
        XCTAssertEqual(BackendAPI.rtb.scheme, "https")
        XCTAssertEqual(BackendAPI.sdk.scheme, "https")
        XCTAssertEqual(BackendAPI.rtb.host, "helium-rtb.chartboost.com")
        XCTAssertEqual(BackendAPI.sdk.host, "helium-sdk.chartboost.com")

        // Success
        testModeInfoMock.rtbAPIHostOverride = "https://rtb.com"
        testModeInfoMock.sdkAPIHostOverride = "https://sdk.com"
        XCTAssertEqual(BackendAPI.rtb.scheme, "https")
        XCTAssertEqual(BackendAPI.sdk.scheme, "https")
        XCTAssertEqual(BackendAPI.rtb.host, "rtb.com")
        XCTAssertEqual(BackendAPI.sdk.host, "sdk.com")

        // Success: HTTP localhost
        testModeInfoMock.rtbAPIHostOverride = "http://localhost"
        testModeInfoMock.sdkAPIHostOverride = "http://localhost"
        XCTAssertEqual(BackendAPI.rtb.scheme, "http")
        XCTAssertEqual(BackendAPI.sdk.scheme, "http")
        XCTAssertEqual(BackendAPI.rtb.host, "localhost")
        XCTAssertEqual(BackendAPI.sdk.host, "localhost")

        // Reset with nil
        testModeInfoMock.rtbAPIHostOverride = nil
        testModeInfoMock.sdkAPIHostOverride = nil
        XCTAssertEqual(BackendAPI.rtb.scheme, "https")
        XCTAssertEqual(BackendAPI.sdk.scheme, "https")
        XCTAssertEqual(BackendAPI.rtb.host, "helium-rtb.chartboost.com")
        XCTAssertEqual(BackendAPI.sdk.host, "helium-sdk.chartboost.com")
    }
}
