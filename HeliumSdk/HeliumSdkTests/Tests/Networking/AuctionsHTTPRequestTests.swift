// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class AuctionsHTTPRequestTests: ChartboostMediationTestCase {

    /// Test URL prefix: "tracking" if ATT auth status is `.authorized` on iOS 17+, "non-tracking" for all other cases.
    func testTrackingVsNonTracking() throws {
        let mockBidRequest = OpenRTB.BidRequest(imp: [], app: nil, device: nil, user: nil, regs: nil, ext: nil, test: nil)
        let dependencyMock = mocks.appTrackingInfoProviderDependency

        AppTrackingInfoProviderDependencyMock.AuthStatusOverride.allCases.forEach { authStatus in
            dependencyMock.authStatusOverride = authStatus
            let request = AuctionsHTTPRequest(bidRequest: mockBidRequest, loadRateLimit: 0, loadID: "")

            if #available(iOS 17.0, *) { // unfortunately we cannot mock #available()
                switch authStatus {
                case .authorized:
                    XCTAssertEqual(
                        try? request.url.absoluteString,
                        "https://tracking.auction.mediation-sdk.chartboost.com/v3/auctions",
                        "iOS 17+: use `tracking` API if authorized"
                    )
                default:
                    XCTAssertEqual(
                        try? request.url.absoluteString,
                        "https://non-tracking.auction.mediation-sdk.chartboost.com/v3/auctions",
                        "iOS 17+: use `non-tracking` API if authorized"
                    )
                }
            } else {
                XCTAssertEqual(
                    try? request.url.absoluteString, 
                    "https://tracking.auction.mediation-sdk.chartboost.com/v3/auctions",
                    "Before iOS 17: use `tracking` API because iOS does not block it"
                )
            }
        }
    }
}
