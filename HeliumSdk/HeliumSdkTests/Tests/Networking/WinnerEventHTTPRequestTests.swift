// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class WinnerEventHTTPRequestTests: ChartboostMediationTestCase {

    private static let url = URL(unsafeString: "https://winner.mediation-sdk.chartboost.com/v3/event/winner")!
    private static let auctionID = "some auction ID"
    private static let loadID = "some load ID"
    private static let bids: [Bid] = [
        .init( // #0: lots of nil
            identifier: "identifier_0",
            partnerIdentifier: "partnerIdentifier_0",
            partnerPlacement: "partnerPlacement_0",
            adm: nil,
            partnerDetails: nil,
            lineItemIdentifier: nil,
            ilrd: nil,
            cpmPrice: nil,
            adRevenue: nil,
            auctionIdentifier: "auctionIdentifier_0",
            isProgrammatic: false,
            rewardedCallback: nil,
            clearingPrice: nil,
            winURL: nil,
            lossURL: nil,
            size: nil
        ),
        .init( // #1: non programmatic
            identifier: "identifier_1",
            partnerIdentifier: "partnerIdentifier_1",
            partnerPlacement: "partnerPlacement_1",
            adm: "adm_1",
            partnerDetails: nil,
            lineItemIdentifier: "lineItemIdentifier_1",
            ilrd: nil,
            cpmPrice: 1,
            adRevenue: 11,
            auctionIdentifier: "auctionIdentifier_1",
            isProgrammatic: false,
            rewardedCallback: nil,
            clearingPrice: 111,
            winURL: "https://win.url",
            lossURL: "https://loss.url",
            size: nil
        ),
        .init( // #2: programmatic
            identifier: "identifier_2",
            partnerIdentifier: "partnerIdentifier_2",
            partnerPlacement: "partnerPlacement_2",
            adm: "adm_2",
            partnerDetails: nil,
            lineItemIdentifier: "lineItemIdentifier_2",
            ilrd: nil,
            cpmPrice: 2,
            adRevenue: 22,
            auctionIdentifier: "auctionIdentifier_2",
            isProgrammatic: true,
            rewardedCallback: nil,
            clearingPrice: 222,
            winURL: "https://win.url",
            lossURL: "https://loss.url",
            size: nil
        )
    ]

    // MARK: - JSON

    private static let auctionIDJSON: [String: Any] = ["auction_id": auctionID]
    private static let loadIDJSON: [String: Any] = ["x-mediation-load-id": loadID]
    private static let biddersJSON: [String: [[String: Any]]] = [
        "bidders": [
            [
                "price": 0,
                "seat": "partnerIdentifier_0"
            ], [
                "price": 111,
                "seat": "partnerIdentifier_1"
            ], [
                "lurl": "https://loss.url",
                "nurl": "https://win.url",
                "price": 222,
                "seat": "partnerIdentifier_2"
            ]
        ]
    ]

    // MARK: - Tests

    /// Test the 1st of 3 `bids`.
    func testWinnerEventWithMostlyNilWinnerBid() throws {
        let winnerBid = Self.bids[0]
        let request = WinnerEventHTTPRequest(winner: winnerBid, of: Self.bids, loadID: Self.loadID, adFormat: .banner, size: nil)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        let expectedJSON = Dictionary.merge(Self.biddersJSON, [
            "auction_id": winnerBid.auctionIdentifier,
            "type": "mediation",
            "winner": winnerBid.partnerIdentifier,
            "price": -1,
            "partner_placement": winnerBid.partnerPlacement,
            "placement_type": "banner",
        ])
        XCTAssertEqual(try request.url, Self.url)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, expectedJSON)
    }

    /// Test the 2nd of 3 `bids`.
    func testWinnerEventWithNonProgrammaticWinnerBid() throws {
        let winnerBid = Self.bids[1]
        let request = WinnerEventHTTPRequest(winner: winnerBid, of: Self.bids, loadID: Self.loadID, adFormat: .banner, size: nil)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        let expectedJSON = Dictionary.merge(Self.biddersJSON, [
            "auction_id": winnerBid.auctionIdentifier,
            "type": "mediation",
            "winner": winnerBid.partnerIdentifier,
            "line_item_id": "lineItemIdentifier_1",
            "price": 111,
            "partner_placement": winnerBid.partnerPlacement,
            "placement_type": "banner",
        ])
        XCTAssertEqual(try request.url, Self.url)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, expectedJSON)
    }

    /// Test the 3rd of 3 `bids`.
    func testWinnerEventWithProgrammaticWinnerBid() throws {
        let winnerBid = Self.bids[2]
        let request = WinnerEventHTTPRequest(winner: winnerBid, of: Self.bids, loadID: Self.loadID, adFormat: .banner, size: nil)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        let expectedJSON = Dictionary.merge(Self.biddersJSON, [
            "auction_id": winnerBid.auctionIdentifier,
            "type": "bidding",
            "winner": winnerBid.partnerIdentifier,
            "line_item_id": "lineItemIdentifier_2",
            "price": 222,
            "placement_type": "banner",
        ])
        XCTAssertEqual(try request.url, Self.url)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testSendsSizeForAdaptiveBanner() throws {
        // The size should be the size sent in the `WinnerEventHTTPRequest`, not in the bid.
        let bid = Bid.makeMock(size: CGSize(width: 500.0, height: 120.0))
        let request = WinnerEventHTTPRequest(winner: bid, of: Self.bids, loadID: Self.loadID, adFormat: .adaptiveBanner, size: CGSize(width: 400.0, height: 100.0))
        let jsonDict = try XCTUnwrap(request.bodyJSON)
        XCTAssertEqual(jsonDict["placement_type"] as? String, "adaptive_banner")
        let sizeDict = try XCTUnwrap(jsonDict["size"] as? [String: Any])
        let width = try XCTUnwrap(sizeDict["w"] as? Int)
        let height = try XCTUnwrap(sizeDict["h"] as? Int)
        XCTAssertEqual(width, 400)
        XCTAssertEqual(height, 100)
    }

    func testSendsZeroWhenBidSizeIsNil() throws {
        let bid = Bid.makeMock()
        let request = WinnerEventHTTPRequest(winner: bid, of: Self.bids, loadID: Self.loadID, adFormat: .adaptiveBanner, size: nil)
        let jsonDict = try XCTUnwrap(request.bodyJSON)
        let sizeDict = try XCTUnwrap(jsonDict["size"] as? [String: Any])
        let width = try XCTUnwrap(sizeDict["w"] as? Int)
        let height = try XCTUnwrap(sizeDict["h"] as? Int)
        XCTAssertEqual(width, 0)
        XCTAssertEqual(height, 0)
    }

    func testDoesNotSendSizeWhenFormatIsNotAdaptiveBanner() throws {
        let bid = Bid.makeMock()
        let request = WinnerEventHTTPRequest(winner: bid, of: Self.bids, loadID: Self.loadID, adFormat: .banner, size: CGSize(width: 320.0, height: 50.0))
        let jsonDict = try XCTUnwrap(request.bodyJSON)
        XCTAssertEqual(jsonDict["placement_type"] as? String, "banner")
        XCTAssertNil(jsonDict["size"])
    }
}
