// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class AuctionsHTTPRequestTests: HeliumTestCase {

    /// Test URL prefix: "tracking" if ATT auth status is `.authorized` on iOS 17+, "non-tracking" for all other cases.
    func testTrackingVsNonTracking() throws {
        let mockBidRequest = OpenRTB.BidRequest(imp: [], app: nil, device: nil, user: nil, regs: nil, ext: nil, test: nil)
        let dependencyMock = mocks.appTrackingInfoProviderDependency

        AppTrackingInfoProviderDependencyMock.AuthStatusOverride.allCases.forEach { authStatus in
            dependencyMock.authStatusOverride = authStatus
            let request = AuctionsHTTPRequest(bidRequest: mockBidRequest, loadRateLimit: 0, loadID: "")

            switch authStatus {
            case .authorized:
                if #available(iOS 17.0, *) { // unfortunately we cannot mock #available()
                    XCTAssertEqual(try? request.url.absoluteString, "https://tracking.auction.mediation-sdk.chartboost.com/v3/auctions")
                } else {
                    XCTAssertEqual(try? request.url.absoluteString, "https://non-tracking.auction.mediation-sdk.chartboost.com/v3/auctions")
                }
            default:
                XCTAssertEqual(try? request.url.absoluteString, "https://non-tracking.auction.mediation-sdk.chartboost.com/v3/auctions")
            }
        }
    }
}
