// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class AdaptiveBannerSizeHTTPRequestTests: ChartboostMediationTestCase {

    private static let url = URL(unsafeString: "https://banner_size.mediation-sdk.chartboost.com/v1/event/banner_size")!

    // MARK: AdaptiveBannerSizeHTTPRequest
    func testRequestHeaders() throws {
        let data = AdaptiveBannerSizeData(
            auctionID: "test_auction_id",
            creativeSize: nil,
            containerSize: nil,
            requestSize: nil
        )
        let request = AdaptiveBannerSizeHTTPRequest(eventTracker: ServerEventTracker(url: AdaptiveBannerSizeHTTPRequestTests.url), adFormat: .banner, data: data, loadID: "test_load_id")
        XCTAssertJSONEqual(
            request.customHeaders,
            ["x-mediation-load-id": "test_load_id",
             "x-mediation-ad-type": "banner"]
        )
    }

    func testRequestBodyWithMinimumFields() throws {
        let expectedResult: [String: Any] = [
            "auction_id": "test_auction_id",
        ]

        let data = AdaptiveBannerSizeData(
            auctionID: "test_auction_id",
            creativeSize: nil,
            containerSize: nil,
            requestSize: nil
        )
        let request = AdaptiveBannerSizeHTTPRequest(eventTracker: ServerEventTracker(url: AdaptiveBannerSizeHTTPRequestTests.url), adFormat: .adaptiveBanner, data: data, loadID: "test")
        let jsonDict = request.bodyJSON
        XCTAssertAnyEqual(jsonDict, expectedResult)
    }

    func testRequestBodyWithAllFields() throws {
        let expectedResult: [String: Any] = [
            "auction_id": "test_auction_id",
            "creative_size": [
                "w": 100,
                "h": 100,
            ],
            "container_size": [
                "w": 200,
                "h": 200,
            ],
            "request_size": [
                "w": 300,
                "h": 300,
            ],
        ]

        let data = AdaptiveBannerSizeData(
            auctionID: "test_auction_id",
            creativeSize: BackendEncodableSize(cgSize: CGSize(width: 100, height: 100)),
            containerSize: BackendEncodableSize(cgSize: CGSize(width: 200, height: 200)),
            requestSize: BackendEncodableSize(cgSize: CGSize(width: 300, height: 300))
        )
        let request = AdaptiveBannerSizeHTTPRequest(eventTracker: ServerEventTracker(url: AdaptiveBannerSizeHTTPRequestTests.url), adFormat: .adaptiveBanner, data: data, loadID: "test")
        let jsonDict = request.bodyJSON
        XCTAssertAnyEqual(jsonDict, expectedResult)
    }
}
