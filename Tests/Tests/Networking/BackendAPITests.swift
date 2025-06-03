// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class BackendAPITests: ChartboostMediationTestCase {

    static let allEndpoints: [BackendAPI.Endpoint] = [
        .auction_nonTracking,
        .auction_tracking,
        .config,
        .load,
    ]

    func testEndpointValues() {
        Self.allEndpoints.forEach { endpoint in
            XCTAssertEqual(endpoint.scheme, "https")

            switch endpoint {
            case .auction_nonTracking:
                XCTAssertEqual(endpoint.host, "non-tracking.auction.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v3/auctions")
            case .auction_tracking:
                XCTAssertEqual(endpoint.host, "tracking.auction.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v3/auctions")
            case .config:
                XCTAssertEqual(endpoint.host, "config.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v1/sdk_init")
            case .load:
                XCTAssertEqual(endpoint.host, "load.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v2/event/load")
            }
        }
    }

    func testAPIHostOverride() throws {
        let testModeInfoMock = try XCTUnwrap(mocks.environment.testMode as? TestModeInfoProvidingMock)

        Self.allEndpoints.forEach { endpoint in
            // Reset with nil
            testModeInfoMock.sdkAPIHostOverride = nil
            XCTAssertEqual(endpoint.scheme, "https")
            XCTAssert(endpoint.host.hasSuffix("mediation-sdk.chartboost.com"))

            // Reset with empty string
            testModeInfoMock.sdkAPIHostOverride = ""
            XCTAssertEqual(endpoint.scheme, "https")
            XCTAssert(endpoint.host.hasSuffix("mediation-sdk.chartboost.com"))

            // Success: URL scheme is HTTPS by default
            testModeInfoMock.sdkAPIHostOverride = "sdk.com"
            XCTAssertEqual(endpoint.scheme, "https")
            XCTAssert(endpoint.host.hasSuffix("sdk.com"))

            // Reset with nil
            testModeInfoMock.sdkAPIHostOverride = nil
            XCTAssertEqual(endpoint.scheme, "https")
            XCTAssert(endpoint.host.hasSuffix("mediation-sdk.chartboost.com"))
        }
    }
}
