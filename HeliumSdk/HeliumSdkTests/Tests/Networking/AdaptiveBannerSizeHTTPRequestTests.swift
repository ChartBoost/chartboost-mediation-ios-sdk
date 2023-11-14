// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class AdaptiveBannerSizeHTTPRequestTests: ChartboostMediationTestCase {
    // MARK: AdaptiveBannerSizeHTTPRequest
    func testRequestHeaders() throws {
        let data = AdaptiveBannerSizeData(
            auctionID: "test_auction_id",
            creativeSize: nil,
            containerSize: nil,
            requestSize: nil
        )
        let request = AdaptiveBannerSizeHTTPRequest(data: data, loadID: "test_load_id")
        let headers = request.customHeaders
        XCTAssertEqual(headers["x-mediation-load-id"], "test_load_id")
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
        let request = AdaptiveBannerSizeHTTPRequest(data: data, loadID: "test")
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
        let request = AdaptiveBannerSizeHTTPRequest(data: data, loadID: "test")
        let jsonDict = request.bodyJSON
        XCTAssertAnyEqual(jsonDict, expectedResult)
    }
}
