// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class BidTests: ChartboostMediationTestCase {

    /// Validate that no rewarded callback object is created when there is no data specified.
    func testNoData() throws {
        let bid = Bid.test(rewardedCallbackData: nil)
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
        let bid = Bid.test(rewardedCallbackData: rewardedCallbackData)
        XCTAssertNil(bid.rewardedCallback)
    }

    func testConsumesWidthAndHeightFromRTBBidResponse() throws {
        let bidResponse = OpenRTB.BidResponse.test(
            seatbid: [
                .test(
                    bid: [
                        .test(w: 400, h: 100)
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
        let bidResponse = OpenRTB.BidResponse.test(
            seatbid: [
                .test(
                    bid: [
                        .test(w: nil, h: 100)
                    ]
                )
            ]
        )
        let bids = Bid.makeBids(response: bidResponse, request: .test(adFormat: .adaptiveBanner))
        let bid = try XCTUnwrap(bids.first)
        XCTAssertNil(bid.size)
    }

    func testBidSizeIsNilWhenHeightIsNil() throws {
        let bidResponse = OpenRTB.BidResponse.test(
            seatbid: [
                .test(
                    bid: [
                        .test(w: 400, h: nil)
                    ]
                )
            ]
        )
        let bids = Bid.makeBids(response: bidResponse, request: .test(adFormat: .adaptiveBanner))
        let bid = try XCTUnwrap(bids.first)
        XCTAssertNil(bid.size)
    }

    func testBidSizeIsNilWhenAdFormatIsNotAdaptiveBanner() throws {
        let bidResponse = OpenRTB.BidResponse.test(
            seatbid: [
                .test(
                    bid: [
                        .test(w: 400, h: 100)
                    ]
                )
            ]
        )
        let bids = Bid.makeBids(response: bidResponse, request: .test(adFormat: .banner))
        let bid = try XCTUnwrap(bids.first)
        XCTAssertNil(bid.size)
    }

    func testBidCombinesPartnerSettingsWithPartnerDetails() throws {
        let bidResponse = OpenRTB.BidResponse.test(
            seatbid: [
                .test(
                    bid: [
                        .test(
                            ext: .test(
                                bidder: JSON(value: [
                                    "helium": [
                                        "BidTests key": "dfn4as"
                                    ]
                                ])
                            ),
                            w: 400,
                            h: 100
                        )
                    ]
                )
            ]
        )
        let bids = Bid.makeBids(response: bidResponse, request: .test(adFormat: .banner))
        let bid = try XCTUnwrap(bids.first)
        XCTAssertAnyEqual(
            bid.partnerDetails,
            [
                "BidTests key": "dfn4as",
                "InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"
            ]
        )
    }

    func testEmptyEventTrackers() throws {
        let bidResponse = OpenRTB.BidResponse.test(
            ext: .test(eventTrackers: nil) // No event_trackers in JSON
        )

        let bids = Bid.makeBids(response: bidResponse, request: .test(adFormat: .banner))
        let bid = try XCTUnwrap(bids.first)

        XCTAssertNotNil(bid)
        XCTAssertEqual(bid.eventTrackers.values.count, 0)
    }

    func testInvalidEventTrackers() throws {
        let bidResponse = OpenRTB.BidResponse.test(
               ext: .test(eventTrackers: JSON(value: [
                   "click": [["invalid_key": "invalid_value"]]
               ]))
           )
        let bids = Bid.makeBids(response: bidResponse, request: .test(adFormat: .banner))
        let bid = try XCTUnwrap(bids.first)

        XCTAssertNotNil(bid)
        XCTAssertEqual(bid.eventTrackers.count, 0)
    }

    func testValidEventTrackers() throws {

        let bidResponse =  OpenRTB.BidResponse.test(
            ext: .test(eventTrackers: JSON(value: [
                "click": [
                    ["url": "https://url_one.com"],
                    ["url": "https://url_two.com"]
                ],
                "helium_impression": [
                    ["url": "https://mediation-impression.mediation-sdk.chartboost.com/v2/event/helium_impression"]
                ]
            ])))

        let bids = Bid.makeBids(response: bidResponse, request: .test(adFormat: .banner))
        let bid = try XCTUnwrap(bids.first)

        XCTAssertNotNil(bid)
        XCTAssertEqual(bid.eventTrackers.count, 2)
        XCTAssertEqual(bid.eventTrackers[.click]?.count, 2)
        XCTAssertEqual(bid.eventTrackers[.mediationImpression]?.count, 1)
    }
}
