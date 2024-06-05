// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class BidTests: ChartboostMediationTestCase {

    /// Validate that no rewarded callback object is created when there is no data specified.
    func testNoData() throws {
        let bid = Bid.makeMock(rewardedCallbackData: nil)
        XCTAssertNil(bid.rewardedCallback)
    }

    /// Validate that no rewarded callback object is created when there is no URL specified.
    func testNoURL() throws {
        let dictionary: [String: Any] = [
            "method": "POST",
            "max_retries": 5,
            "body": "{\"load_ts\":123232445434,\"hash\":\"999123424212324122324\",\"data\":\"%%CUSTOM_DATA%%\",\"imp_ts\":\"%%SDK_TIMESTAMP%%\",\"keyword_A\":\"value_of_keyword_A_set_by_server\",\"hello\":\"world\",\"network\":\"%%NETWORK_NAME%%\",\"revenue\":%%AD_REVENUE%%}"
        ]
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let decoder = JSONDecoder()
        let rewardedCallbackData = try decoder.decode(RewardedCallbackData.self, from: data)
        let bid = Bid.makeMock(rewardedCallbackData: rewardedCallbackData)
        XCTAssertNil(bid.rewardedCallback)
    }

    func testConsumesWidthAndHeightFromRTBBidResponse() throws {
        let bidResponse = OpenRTB.BidResponse.mock(
            seatbid: [
                .mock(
                    bid: [
                        .mock(w: 400, h: 100)
                    ]
                )
            ]
        )
        let bids = Bid.makeBids(response: bidResponse, request: .test(adFormat: .adaptiveBanner))
        let bid = try XCTUnwrap(bids.first)
        XCTAssertEqual(bid.size?.width, 400.0)
        XCTAssertEqual(bid.size?.height, 100.0)
    }

    func testBidSizeIsNilWhenWidthIsNil() throws {
        let bidResponse = OpenRTB.BidResponse.mock(
            seatbid: [
                .mock(
                    bid: [
                        .mock(w: nil, h: 100)
                    ]
                )
            ]
        )
        let bids = Bid.makeBids(response: bidResponse, request: .test(adFormat: .adaptiveBanner))
        let bid = try XCTUnwrap(bids.first)
        XCTAssertNil(bid.size)
    }

    func testBidSizeIsNilWhenHeightIsNil() throws {
        let bidResponse = OpenRTB.BidResponse.mock(
            seatbid: [
                .mock(
                    bid: [
                        .mock(w: 400, h: nil)
                    ]
                )
            ]
        )
        let bids = Bid.makeBids(response: bidResponse, request: .test(adFormat: .adaptiveBanner))
        let bid = try XCTUnwrap(bids.first)
        XCTAssertNil(bid.size)
    }

    func testBidSizeIsNilWhenAdFormatIsNotAdaptiveBanner() throws {
        let bidResponse = OpenRTB.BidResponse.mock(
            seatbid: [
                .mock(
                    bid: [
                        .mock(w: 400, h: 100)
                    ]
                )
            ]
        )
        let bids = Bid.makeBids(response: bidResponse, request: .test(adFormat: .banner))
        let bid = try XCTUnwrap(bids.first)
        XCTAssertNil(bid.size)
    }
}
