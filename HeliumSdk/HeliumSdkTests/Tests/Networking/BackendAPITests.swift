// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class BackendAPITests: ChartboostMediationTestCase {

    static let allEndpoints: [BackendAPI.Endpoint] = [
        .auction_nonTracking,
        .auction_tracking,
        .bannerSize,
        .click,
        .config,
        .expiration,
        .initialization,
        .load,
        .mediationImpression,
        .partnerImpression,
        .prebid,
        .reward,
        .show,
        .winner
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
            case .bannerSize:
                XCTAssertEqual(endpoint.host, "banner-size.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v1/event/banner_size")
            case .click:
                XCTAssertEqual(endpoint.host, "click.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v2/event/click")
            case .config:
                XCTAssertEqual(endpoint.host, "config.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v1/sdk_init")
            case .expiration:
                XCTAssertEqual(endpoint.host, "expiration.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v1/event/expiration")
            case .initialization:
                XCTAssertEqual(endpoint.host, "initialization.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v1/event/initialization")
            case .load:
                XCTAssertEqual(endpoint.host, "load.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v2/event/load")
            case .mediationImpression:
                XCTAssertEqual(endpoint.host, "mediation-impression.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v1/event/helium_impression")
            case .partnerImpression:
                XCTAssertEqual(endpoint.host, "partner-impression.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v1/event/partner_impression")
            case .prebid:
                XCTAssertEqual(endpoint.host, "prebid.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v1/event/prebid")
            case .reward:
                XCTAssertEqual(endpoint.host, "reward.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v2/event/reward")
            case .show:
                XCTAssertEqual(endpoint.host, "show.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v1/event/show")
            case .winner:
                XCTAssertEqual(endpoint.host, "winner.mediation-sdk.chartboost.com")
                XCTAssertEqual(endpoint.basePath, "/v3/event/winner")
            }
        }
    }

    func testAPIHostOverride() throws {
        let testModeInfoMock = try XCTUnwrap(mocks.environment.testMode as? EnvironmentMock.TestModeInfoProviderMock)

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
