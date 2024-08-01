// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import XCTest
import ChartboostCoreSDK
@testable import ChartboostMediationSDK

class NetworkAdAuctionServiceTests: ChartboostMediationTestCase {

    lazy var service = NetworkAdAuctionService()

    private static let nonTracking_auctionsURLString = "https://non-tracking.auction.mediation-sdk.chartboost.com/v3/auctions"
    private static let nonTracking_auctionsURL = URL(unsafeString: nonTracking_auctionsURLString)!
    private static let tracking_auctionsURLString = "https://tracking.auction.mediation-sdk.chartboost.com/v3/auctions"
    private static let tracking_auctionsURL = URL(unsafeString: tracking_auctionsURLString)!
    static let loadID = "some load ID"
    static let auctionID = "some auction ID"
    static let rateLimitReset = "5"
    static let interstitialRequestKeywords = ["k1": "v1", "k2": "v2"]
    static let interstitialRequest = InternalAdLoadRequest.test(adFormat: .interstitial, keywords: interstitialRequestKeywords, loadID: loadID)
    let bidderInfo = ["partner1": ["1": "2"], "partner2": ["1": "2", "a": "b"], "partner3": ["1234": "2423", "asdf ": "fsdfsdf", "asdf-o-": "sdfj"]]

    override func setUp() {
        super.setUp()
        mocks.environment.randomizeAll()
        mocks.consentSettings.consents = [
            "key1": "value1",
            ConsentKeys.tcf: "asdfb",
            ConsentKeys.usp: "12345",
            ConsentKeys.gpp: "gpp12345",
            ConsentKeys.ccpaOptIn: ConsentValues.granted
        ]
        mocks.partnerController.initializedAdapterInfo = [
            "partner1": InternalPartnerAdapterInfo(partnerVersion: "1.2.3", adapterVersion: "1.2.3.4", partnerID: "-", partnerDisplayName: "-"),
            "partner4": InternalPartnerAdapterInfo(partnerVersion: "a.b.c", adapterVersion: "a.b.c.d", partnerID: "-", partnerDisplayName: "-")
        ]
    }

    // MARK: - Basic

    func testSingleProgrammatic() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.Test_BidResp_OnlyProg)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(1, bids.count)
                if bids.count == 1 {
                    let bid = bids[0]
                    XCTAssertEqual("10ed5d777b23d503a05e9e2d7cc6d9f1aaea7a09", bid.auctionID)
                    XCTAssertEqual("chartboost", bid.partnerID)
                    XCTAssertEqual(99, bid.clearingPrice)
                    XCTAssertTrue(bid.isProgrammatic)
                    XCTAssertEqual("chartboost:\(request.mediationPlacement)", bid.partnerPlacement)
                    XCTAssertEqual("PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz5cbjxW", bid.adm)
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    func testSingleNonProgramatic() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.Test_BidResp_Only1NonProg)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(1, bids.count)
                if bids.count == 1 {
                    let bid = bids[0]
                    XCTAssertEqual("10ed5d777b23d503a05e9e2d7cc6d9f1aaea7a09", bid.auctionID)
                    XCTAssertEqual("adcolony", bid.partnerID)
                    XCTAssertEqual(2, bid.clearingPrice)
                    XCTAssertFalse(bid.isProgrammatic)
                    XCTAssertEqual("vz2d478b18e6f14747a0", bid.partnerPlacement)
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    func testOrderOfMultipleBids() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.Test_BidResp_Order)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(5, bids.count)
                if bids.count == 5 {
                    XCTAssertEqual("chartboost", bids[0].partnerID)
                    XCTAssertTrue(bids[0].isProgrammatic)
                    XCTAssertEqual("tapjoy", bids[1].partnerID)
                    XCTAssertEqual("facebook", bids[2].partnerID)
                    XCTAssertEqual("chartboost", bids[3].partnerID)
                    XCTAssertFalse(bids[3].isProgrammatic)
                    XCTAssertEqual("adcolony", bids[4].partnerID)
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    func testPartnerExt() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.Test_BidResp_OnlyTJProg)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(1, bids.count)
                if bids.count == 1 {
                    let bid = bids[0]
                    if let partnerDetails = bid.partnerDetails {
                        if let placementName = partnerDetails["placement_name"] as? String {
                            XCTAssertEqual("iOSTJRewarded", placementName)
                        } else {
                            XCTFail("Missing placement name")
                        }
                    } else {
                        XCTFail("Missing partner details")
                    }
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // MARK: - ILRD

    // Validates that the bidder's ILRD information is merged into the base ILRD information.
    func testILRDBidderAndBase() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.BidResponseILRD)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        let expectedBidILRD0: [String: Any] = [
            "impression_id": "ab82501b580000bb8ace119907f7a4d6665212c3",
            "currency_type": "USD",
            "country": "USA",
            "placement_name": "AllNetworkInterstitial",
            "placement_type": "interstitial",
            "network_name": "fyber",
            "network_type": "mediation",
            "precision": "publisher_defined",
            "line_item_name": "FNonProAndroidInterstitialTest",
            "network_placement_id": "490251",
            "ad_revenue": 100.0
        ]

        let expectedBidILRD2: [String: Any] = [
            "impression_id": "ab82501b580000bb8ace119907f7a4d6665212c3",
            "currency_type": "USD",
            "country": "USA",
            "placement_name": "AllNetworkInterstitial",
            "placement_type": "interstitial",
            "network_name": "unity",
            "network_type": "mediation",
            "precision": "publisher_defined",
            "line_item_name": "UANonProInterstitialLow",
            "network_placement_id": "UANonProInterstitialLow",
            "ad_revenue": 1.25
        ]

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(3, bids.count)
                if bids.count == 3 {
                    let bid0 = bids[0]
                    XCTAssertNotNil(bid0.ilrd)
                    if let bid0ILRD = bid0.ilrd {
                        XCTAssertTrue(NSDictionary(dictionary: expectedBidILRD0).isEqual(to: bid0ILRD))
                    }
                    let bid2 = bids[2]
                    XCTAssertNotNil(bid2.ilrd)
                    if let bid2ILRD = bid2.ilrd {
                        XCTAssertTrue(NSDictionary(dictionary: expectedBidILRD2).isEqual(to: bid2ILRD))
                    }
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // Validates that the bidder's ILRD information is merged into a non-existent base ILRD information.
    func testILRDBidderAndNoBase() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.BidResponseNoBaseILRD)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        let expectedBidILRDFirst: [String: Any] = [
            "network_name": "fyber",
            "network_type": "mediation",
            "precision": "publisher_defined",
            "line_item_name": "FNonProAndroidInterstitialTest",
            "network_placement_id": "490251",
            "ad_revenue": 100.0
        ]

        let expectedBidILRDLast: [String: Any] = [
            "network_name": "adcolony",
            "network_type": "bidding",
            "precision": "exact",
            "ad_revenue": 25.0,
            "network_placement_id": "vz6ea19a677c314d1a86"
        ]

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                if let firstBid = bids.first {
                    XCTAssertNotNil(firstBid.ilrd)
                    if let bidFirstILRD = firstBid.ilrd {
                        XCTAssertTrue(NSDictionary(dictionary: expectedBidILRDFirst).isEqual(to: bidFirstILRD))
                    }
                } else {
                    XCTFail("Missing first bid")
                }
                if let lastBid = bids.last {
                    XCTAssertNotNil(lastBid.ilrd)
                    if let bidLastILRD = lastBid.ilrd {
                        XCTAssertTrue(NSDictionary(dictionary: expectedBidILRDLast).isEqual(to: bidLastILRD))
                    }
                } else {
                    XCTFail("Missing first bid")
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // Validates that the bidders with no ILRD information still contain the base ILRD information.
    func testILRDNoBidder() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.BidResponseNoBidderILRD)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        let expectedBidILRD: [String: Any] = [
            "impression_id": "ab82501b580000bb8ace119907f7a4d6665212c3",
            "currency_type": "USD",
            "country": "USA",
            "placement_name": "AllNetworkInterstitial",
            "placement_type": "interstitial"
        ]

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(3, bids.count)
                bids.forEach { bid in
                    if let bidILRD = bid.ilrd {
                        XCTAssertTrue(NSDictionary(dictionary: expectedBidILRD).isEqual(to: bidILRD))
                    } else {
                        XCTFail("Missing ILRD")
                    }
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // Validates that responses with no ILRD information will result in bids with `nil` ILRD values.
    func testILRDNoInformation() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.BidResponseNoILRD)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(3, bids.count)
                bids.forEach { bid in
                    XCTAssertNil(bid.ilrd)
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // Validates that responses with null ILRD information will result in bids.
    func testILRDNullInformation() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.BidResponseILRDNullValues)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(1, bids.count)
                bids.forEach { bid in
                    XCTAssertNotNil(bid.ilrd)
                    XCTAssertNil(bid.adRevenue)
                    XCTAssertNil(bid.cpmPrice)
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // MARK: - Rewarded Callback

    // Validate that parsing a bid response with no rewarded callbacks will result in no rewarded callback objects.
    func testRewardedCallbackNotPresent() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.BidResponseNoILRD)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(3, bids.count)
                bids.forEach { bid in
                    XCTAssertNil(bid.rewardedCallback)
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // Validates that given the sparse (minimal) rewarded callback payload, it is successfully parsed
    // and generates valid URL requests.
    func testRewardedCallbackSparse() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.BidResponseRewardedCallbackSparse)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(3, bids.count)
                bids.forEach { bid in
                    XCTAssertNotNil(bid.rewardedCallback)
                    if let rewardedCallback = bid.rewardedCallback {
                        XCTAssertTrue(!rewardedCallback.urlString.isEmpty)
                        XCTAssertEqual(.get, rewardedCallback.method)

                        // Generate the URL request with custom data, validating that none of the macros still exist.
                        do {
                            let requestWithCustomData = try XCTUnwrap(RewardedCallbackHTTPRequest(rewardedCallback: rewardedCallback, customData: "{}"))
                            XCTAssertFalse(requestWithCustomData.url.path.contains("%%CUSTOM_DATA%%"))
                            XCTAssertFalse(requestWithCustomData.url.path.contains("%%SDK_TIMESTAMP%%"))
                            XCTAssertNil(requestWithCustomData.bodyData)
                            XCTAssertEqual(requestWithCustomData.method, .get)
                        } catch {
                            XCTFail(error.localizedDescription)
                        }

                        // Generate the URL request without custom data, validating that none of the macros still exist.
                        do {
                            let requestWithoutCustomData = try XCTUnwrap(RewardedCallbackHTTPRequest(rewardedCallback: rewardedCallback, customData: nil))
                            XCTAssertFalse(requestWithoutCustomData.url.path.contains("%%CUSTOM_DATA%%"))
                            XCTAssertFalse(requestWithoutCustomData.url.path.contains("%%SDK_TIMESTAMP%%"))
                            XCTAssertNil(requestWithoutCustomData.bodyData)
                            XCTAssertEqual(requestWithoutCustomData.method, .get)
                        } catch {
                            XCTFail(error.localizedDescription)
                        }

                    } else {
                        XCTFail("No rewarded callback present")
                    }
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // Validates that given the rewarded callback payload, it is successfully parsed and generates valid URL requests.
    func testRewardedCallback() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.BidResponseRewardedCallbackPOST)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(3, bids.count)
                bids.forEach { bid in
                    XCTAssertNotNil(bid.rewardedCallback)
                    if let rewardedCallback = bid.rewardedCallback {
                        XCTAssertTrue(!rewardedCallback.urlString.isEmpty)
                        XCTAssertEqual(.post, rewardedCallback.method)
                        XCTAssertEqual(5, rewardedCallback.maxRetries)
                        XCTAssertNotNil(rewardedCallback.body)
                        if let body = rewardedCallback.body {
                            XCTAssertTrue(body.contains("%%CUSTOM_DATA%%"))
                            XCTAssertTrue(body.contains("%%SDK_TIMESTAMP%%"))
                        }

                        // Generate the URL request with custom data, validating that none of the macros still exist.
                        do {
                            let requestWithCustomData = try XCTUnwrap(RewardedCallbackHTTPRequest(rewardedCallback: rewardedCallback, customData: "{}"))
                            XCTAssertEqual(requestWithCustomData.method, .post)
                            if let json = try JSONSerialization.jsonObject(with: try XCTUnwrap(requestWithCustomData.bodyData), options: []) as? [String: Any] {
                                XCTAssertFalse(json.values.contains(where: { $0 as? String == "%%CUSTOM_DATA%%" }))
                                XCTAssertFalse(json.values.contains(where: { $0 as? String == "%%SDK_TIMESTAMP%%" }))
                            } else {
                                XCTFail("Invalid JSON object")
                            }
                        } catch {
                            XCTFail(error.localizedDescription)
                        }

                        // Generate the URL request without custom data, validating that none of the macros still exist.
                        do {
                            let requestWithoutCustomData = try XCTUnwrap(RewardedCallbackHTTPRequest(rewardedCallback: rewardedCallback, customData: nil))
                            XCTAssertEqual(requestWithoutCustomData.method, .post)
                            if let json = try JSONSerialization.jsonObject(with: try XCTUnwrap(requestWithoutCustomData.bodyData), options: []) as? [String: Any] {
                                XCTAssertFalse(json.values.contains(where: { $0 as? String == "%%CUSTOM_DATA%%" }))
                                XCTAssertFalse(json.values.contains(where: { $0 as? String == "%%SDK_TIMESTAMP%%" }))
                            } else {
                                XCTFail("Invalid JSON object")
                            }
                        } catch {
                            XCTFail(error.localizedDescription)
                        }
                    } else {
                        XCTFail("No rewarded callback present")
                    }
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // Validates that given the rewarded callback payload with `null` CPM price and Ad Revenue, it is successfully parsed
    // and generates valid URL requests with empty string macro replacements for GET requests.
    func testRewardedCallbackNullCPMPriceNullAdRevenueGET() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.BidResponseRewardedCallbackNullGET)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(3, bids.count)
                bids.forEach { bid in
                    XCTAssertNotNil(bid.rewardedCallback)
                    if let rewardedCallback = bid.rewardedCallback {
                        XCTAssertTrue(!rewardedCallback.urlString.isEmpty)
                        XCTAssertEqual(.get, rewardedCallback.method)
                        XCTAssertEqual(5, rewardedCallback.maxRetries)
                        XCTAssertTrue(rewardedCallback.urlString.contains("%25%25CUSTOM_DATA%25%25"))
                        XCTAssertTrue(rewardedCallback.urlString.contains("%25%25SDK_TIMESTAMP%25%25"))
                        XCTAssertTrue(rewardedCallback.urlString.contains("%25%25AD_REVENUE%25%25"))
                        XCTAssertTrue(rewardedCallback.urlString.contains("%25%25CPM_PRICE%25%25"))

                        // Generate the URL request with custom data, validating that none of the macros still exist.
                        do {
                            let requestWithCustomData = try XCTUnwrap(RewardedCallbackHTTPRequest(rewardedCallback: rewardedCallback, customData: "{}"))
                            XCTAssertEqual(requestWithCustomData.method, .get)
                            XCTAssertFalse(requestWithCustomData.url.absoluteString.contains("%%CUSTOM_DATA%%"))
                            XCTAssertFalse(requestWithCustomData.url.absoluteString.contains("%%SDK_TIMESTAMP%%"))
                            XCTAssertFalse(requestWithCustomData.url.absoluteString.contains("%%CPM_PRICE%%"))
                            XCTAssertFalse(requestWithCustomData.url.absoluteString.contains("%%AD_REVENUE%%"))

                            XCTAssertTrue(requestWithCustomData.url.absoluteString.contains("revenue="))
                            XCTAssertTrue(requestWithCustomData.url.absoluteString.contains("cpm="))
                        } catch {
                            XCTFail(error.localizedDescription)
                        }

                        // Generate the URL request without custom data, validating that none of the macros still exist.
                        do {
                            let requestWithoutCustomData = try XCTUnwrap(RewardedCallbackHTTPRequest(rewardedCallback: rewardedCallback, customData: nil))
                            XCTAssertEqual(requestWithoutCustomData.method, .get)
                            XCTAssertFalse(requestWithoutCustomData.url.absoluteString.contains("%%CUSTOM_DATA%%"))
                            XCTAssertFalse(requestWithoutCustomData.url.absoluteString.contains("%%SDK_TIMESTAMP%%"))
                            XCTAssertFalse(requestWithoutCustomData.url.absoluteString.contains("%%CPM_PRICE%%"))
                            XCTAssertFalse(requestWithoutCustomData.url.absoluteString.contains("%%AD_REVENUE%%"))

                            XCTAssertTrue(requestWithoutCustomData.url.absoluteString.contains("revenue="))
                            XCTAssertTrue(requestWithoutCustomData.url.absoluteString.contains("cpm="))
                        } catch {
                            XCTFail(error.localizedDescription)
                        }
                    } else {
                        XCTFail("No rewarded callback present")
                    }
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // Validates that given the rewarded callback payload with `null` CPM price and Ad Revenue, it is successfully parsed
    // and generates valid URL requests with non-existent macro replacements for POST requests.
    func testRewardedCallbackNullCPMPriceNullAdRevenuePOST() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.BidResponseRewardedCallbackNullPOST)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(3, bids.count)
                bids.forEach { bid in
                    XCTAssertNotNil(bid.rewardedCallback)
                    if let rewardedCallback = bid.rewardedCallback {
                        XCTAssertTrue(!rewardedCallback.urlString.isEmpty)
                        XCTAssertEqual(.post, rewardedCallback.method)
                        XCTAssertEqual(5, rewardedCallback.maxRetries)
                        XCTAssertNotNil(rewardedCallback.body)
                        if let body = rewardedCallback.body {
                            XCTAssertTrue(body.contains("%%CUSTOM_DATA%%"))
                            XCTAssertTrue(body.contains("%%SDK_TIMESTAMP%%"))
                            XCTAssertTrue(body.contains("%%AD_REVENUE%%"))
                            XCTAssertTrue(body.contains("%%CPM_PRICE%%"))
                        }

                        // Generate the URL request with custom data, validating that none of the macros still exist.
                        do {
                            let requestWithCustomData = try XCTUnwrap(RewardedCallbackHTTPRequest(rewardedCallback: rewardedCallback, customData: "{}"))
                            XCTAssertEqual(requestWithCustomData.method, .post)
                            if let bodyString = String(data: try XCTUnwrap(requestWithCustomData.bodyData), encoding: .utf8) {
                                XCTAssertFalse(bodyString.contains("%%CUSTOM_DATA%%"))
                                XCTAssertFalse(bodyString.contains("%%SDK_TIMESTAMP%%"))
                                XCTAssertFalse(bodyString.contains("%%CPM_PRICE%%"))
                                XCTAssertFalse(bodyString.contains("%%AD_REVENUE%%"))

                                XCTAssertFalse(bodyString.contains("revenue"))
                                XCTAssertFalse(bodyString.contains("cpm"))
                            } else {
                                XCTFail("Invalid body")
                            }
                        } catch {
                            XCTFail(error.localizedDescription)
                        }

                        // Generate the URL request without custom data, validating that none of the macros still exist.
                        do {
                            let requestWithoutCustomData = try XCTUnwrap(RewardedCallbackHTTPRequest(rewardedCallback: rewardedCallback, customData: nil))
                            XCTAssertEqual(requestWithoutCustomData.method, .post)
                            if let bodyString = String(data: try XCTUnwrap(requestWithoutCustomData.bodyData), encoding: .utf8) {
                                XCTAssertFalse(bodyString.contains("%%CUSTOM_DATA%%"))
                                XCTAssertFalse(bodyString.contains("%%SDK_TIMESTAMP%%"))
                                XCTAssertFalse(bodyString.contains("%%CPM_PRICE%%"))
                                XCTAssertFalse(bodyString.contains("%%AD_REVENUE%%"))

                                XCTAssertFalse(bodyString.contains("revenue"))
                                XCTAssertFalse(bodyString.contains("cpm"))
                            } else {
                                XCTFail("Invalid body")
                            }
                        } catch {
                            XCTFail(error.localizedDescription)
                        }
                    } else {
                        XCTFail("No rewarded callback present")
                    }
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // Validates that given a malformed rewarded callback payload, it is successfully parsed
    // and generates valid URL requests.
    func testRewardedCallbackMalformed() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.BidResponseRewardedCallbackMalformed)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(3, bids.count)
                bids.forEach { bid in
                    XCTAssertNil(bid.rewardedCallback)
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // MARK: - Real Response

    // Test the parsing of a completely backend realistically generated response for interstitials.
    func testRealInterstitialResponse() throws {
        let request = Self.interstitialRequest
        Self.registerResponseJSON(.bid_response_interstitial_real)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(1, bids.count)
                if bids.count == 1 {
                    let bid = bids[0]
                    XCTAssertEqual("d0acdc55dcdbc534100b8d406945d6168ef66011", bid.auctionID)
                    XCTAssertEqual("chartboost", bid.partnerID)
                    XCTAssertTrue(bid.isProgrammatic)
                    XCTAssertEqual("CBInterstitial", bid.partnerPlacement)
                    XCTAssertNotNil(bid.adm)
                    XCTAssertNil(bid.rewardedCallback)
                    XCTAssertNotNil(bid.ilrd)
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // Test the parsing of a completely backend realistically generated response for rewarded.
    func testRealRewardedResponse() throws {
        let request = InternalAdLoadRequest.test(adFormat: .rewarded, keywords: nil, loadID: Self.loadID)
        Self.registerResponseJSON(.bid_response_rewarded_real)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(1, bids.count)
                if bids.count == 1 {
                    let bid = bids[0]
                    XCTAssertEqual("1bc263c982eb5794f01d562b99204f8ac7c6438a", bid.auctionID)
                    XCTAssertEqual("chartboost", bid.partnerID)
                    XCTAssertTrue(bid.isProgrammatic)
                    XCTAssertEqual("CBRewarded", bid.partnerPlacement)
                    XCTAssertNotNil(bid.adm)
                    XCTAssertNotNil(bid.rewardedCallback)
                    XCTAssertNotNil(bid.ilrd)
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // Test the parsing of a completely backend realistically generated response for banners.
    func testRealBannerResponse() throws {
        let request = InternalAdLoadRequest.test(adFormat: .banner, keywords: nil, loadID: Self.loadID)
        Self.registerResponseJSON(.bid_response_banner_real)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        var completed = false
        service.startAuction(request: request) { response in
            switch response.result {
            case .success(let bids):
                XCTAssertEqual(1, bids.count)
                if bids.count == 1 {
                    let bid = bids[0]
                    XCTAssertEqual("eed8b5be5a3b66e89df0f3869b345856bc77dc0c", bid.auctionID)
                    XCTAssertEqual("chartboost", bid.partnerID)
                    XCTAssertTrue(bid.isProgrammatic)
                    XCTAssertEqual("CBBanner", bid.partnerPlacement)
                    XCTAssertNotNil(bid.adm)
                    XCTAssertNil(bid.rewardedCallback)
                    XCTAssertNotNil(bid.ilrd)
                }
            case .failure(let error):
                XCTFail("Unexpected failed result received: \(error.localizedDescription)")
            }
            completed = true
            expectation.fulfill()
        }

        // Check that PartnerController was asked for bidder info
        let expectedPreBidRequest = PartnerAdPreBidRequest(
            mediationPlacement: request.mediationPlacement,
            format: request.adFormat.rawValue,
            bannerSize: nil,
            partnerSettings: ["InternalAdLoadRequest+Test key": "InternalAdLoadRequest+Test value"],
            keywords: Self.interstitialRequestKeywords,
            loadID: Self.loadID,
            internalAdFormat: request.adFormat
        )
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            expectedPreBidRequest, XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        // Check that operation has not completed
        XCTAssertFalse(completed)

        // Finish the PartnerController bidder info fetch
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(completed)
    }

    // MARK: - Invalid Response

    func testEmptyDataWithDifferentHTTPStatusCodes() {
        [200, 204, 404, 500].forEach { httpResponseStatusCode in
            Self.registerResponseJSON(nil, statusCode: httpResponseStatusCode)
            mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()
            let request = InternalAdLoadRequest.test(adFormat: .interstitial, keywords: nil)
            let expectation = XCTestExpectation(description: "auction")
            service.startAuction(request: request) { response in
                if httpResponseStatusCode == 204 {
                    XCTAssertEqual(response.result.error?.code, ChartboostMediationError.Code.loadFailureAuctionNoBid.rawValue)
                } else if httpResponseStatusCode == 200 {
                    XCTAssertEqual(response.result.error?.code, ChartboostMediationError.Code.loadFailureInvalidBidResponse.rawValue)
                } else { // 404, 500
                    XCTAssertEqual(response.result.error?.code, ChartboostMediationError.Code.loadFailureNetworkingError.rawValue)
                }
                expectation.fulfill()
            }

            var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
            XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
                XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
            ])
            fetchBidderInfoCompletion(bidderInfo)
            wait(for: [expectation], timeout: 1)
        }
    }

    func testValidDataWithDifferentHTTPStatusCodes() {
        [200, 204, 404, 500].forEach { httpResponseStatusCode in
            Self.registerResponseJSON(.Test_BidResp_OnlyProg, statusCode: httpResponseStatusCode)
            mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()
            let request = InternalAdLoadRequest.test(adFormat: .interstitial, keywords: nil)
            let expectation = XCTestExpectation(description: "auction")
            service.startAuction(request: request) { response in
                if httpResponseStatusCode == 200 {
                    XCTAssertNil(response.result.error)
                } else if httpResponseStatusCode == 204 {
                    XCTAssertEqual(response.result.error?.code, ChartboostMediationError.Code.loadFailureAuctionNoBid.rawValue)
                } else { // 404, 500
                    XCTAssertEqual(response.result.error?.code, ChartboostMediationError.Code.loadFailureNetworkingError.rawValue)
                }
                expectation.fulfill()
            }

            var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
            XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
                XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
            ])
            fetchBidderInfoCompletion(bidderInfo)
            wait(for: [expectation], timeout: 1)
        }
    }
    
    /// Validates that the service completes with the proper info when the network manager fails due to an error decoding the response data.
    func testNetworkManagerJSONDecodingErrorIsReportedPropery() {
        // Mock network manager
        let networkManager = CompleteNetworkManagerMock()
        mocks.networkManager = networkManager
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        let responseData = "some data".data(using: .utf8)!
        let decodingError = NSError.test(domain: "decoding", code: 5)
        let networkManagerError = NetworkManager.RequestError.jsonDecodeError(
            httpRequest: HTTPRequestMock(urlString: "apple.com"),
            httpURLResponse: HTTPURLResponse(),
            data: responseData,
            originalError: decodingError
        )
        let expectedError = ChartboostMediationError(
            code: .loadFailureInvalidBidResponse,
            description: networkManagerError.localizedDescription,
            error: decodingError,
            data: responseData
        )
        
        // Start auction
        var finished = false
        service.startAuction(request: .test()) { response in
            // Check the response is a failure with all the info from the original JSON decoding error
            guard case let .failure(error) = response.result else {
                XCTFail("Received unexpected successful response")
                return
            }
            XCTAssertEqual(error, expectedError)
            finished = true
        }
        
        // Complete bidder info fetching
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        fetchBidderInfoCompletion(bidderInfo)
        
        // Complete network auction request with JSON decoding error
        var auctionRequestCompletion: (NetworkManager.RequestCompletionWithJSONResponse<OpenRTB.BidResponse>) = { _ in }
        XCTAssertMethodCalls(networkManager, .send, parameters: [XCTMethodIgnoredParameter(), 0, 0.0, XCTMethodCaptureParameter { auctionRequestCompletion = $0 }])
        auctionRequestCompletion(.failure(networkManagerError))
        
        // Check that the auction finished
        XCTAssertTrue(finished)
    }

    // MARK: - Auction ID
    
    /// Validates that a nil auction ID is returned if the operation fails before the auction starts.
    func testAuctionIDIsNotIncludedIfAuctionFailsEarly() {
        // Setup: load rate limiter rejects the load
        mocks.loadRateLimiter.setReturnValue(9.0, for: .timeUntilNextLoadIsAllowed)
        let request = InternalAdLoadRequest.test(adFormat: .interstitial, keywords: nil)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        var completed = false
        service.startAuction(request: request) { response in
            // Check the response contains the auction ID and a failed result
            XCTAssertNil(response.auctionID)
            XCTAssertNotNil(response.result.error)
            completed = true
        }
        
        // Check that bidding tokens are not fetched
        XCTAssertNoMethodCalls(mocks.partnerController)
        
        // Check that operation has completed
        XCTAssertTrue(completed)
    }
    
    /// Validates that the auction ID in the response header is returned even in a failure path.
    func testAuctionIDIsIncludedIfNetworkFails() {
        // Setup: network manager fails with a response that includes auction ID
        let request = InternalAdLoadRequest.test(adFormat: .interstitial, keywords: nil)
        Self.registerResponseJSON(nil, statusCode: 500)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        service.startAuction(request: request) { response in
            // Check the response contains the auction ID and a failed result
            XCTAssertEqual(response.auctionID, Self.auctionID)
            XCTAssertNotNil(response.result.error)
            expectation.fulfill()
        }
        
        // Finish the PartnerController bidder info fetch
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        fetchBidderInfoCompletion(bidderInfo)
        
        // Check that operation has completed
        wait(for: [expectation], timeout: 1)
    }
    
    /// Validates that the auction ID in the response header is returned in a success path.
    func testAuctionIDIsIncludedIfNetworkSucceeds() {
        // Setup: network manager succeeds with a response that includes auction ID
        let request = InternalAdLoadRequest.test(adFormat: .interstitial, keywords: nil)
        Self.registerResponseJSON(.Test_BidResp_OnlyProg)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()

        // Start the auction
        let expectation = XCTestExpectation(description: "auction")
        service.startAuction(request: request) { response in
            // Check the response contains the auction ID and a success result
            XCTAssertEqual(response.auctionID, Self.auctionID)
            XCTAssertNotNil(try? response.result.get())
            expectation.fulfill()
        }
        
        // Finish the PartnerController bidder info fetch
        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        fetchBidderInfoCompletion(bidderInfo)
        
        // Check that operation has completed
        wait(for: [expectation], timeout: 1)
    }

    // MARK: - Rate Limit

    /// Validates that the load rate limit is not updated by x-mediation-ratelimit-reset in the response header.
    func testRateLimitResetIfNetworkFails() {
        Self.registerResponseJSON(.Test_BidResp_OnlyProg, statusCode: 500)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()
        let request = Self.interstitialRequest
        let expectation = XCTestExpectation(description: "auction")
        service.startAuction(request: request) { response in
            expectation.fulfill()
        }

        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 1)
        XCTAssertMethodCalls(
            mocks.loadRateLimiter,
            .timeUntilNextLoadIsAllowed,
            .loadRateLimit,
            parameters:
                [request.mediationPlacement], // .timeUntilNextLoadIsAllowed
                [request.mediationPlacement] // .loadRateLimit
        )
    }

    /// Validates that the load rate limit is updated by x-mediation-ratelimit-reset in the response header.
    func testRateLimitResetIfNetworkSucceeds() {
        Self.registerResponseJSON(.Test_BidResp_OnlyProg)
        mocks.auctionRequestFactory.autoCompletionResult = AuctionsHTTPRequest.test()
        let request = Self.interstitialRequest
        let expectation = XCTestExpectation(description: "auction")
        service.startAuction(request: request) { response in
            expectation.fulfill()
        }

        var fetchBidderInfoCompletion: (BidderTokens) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeFetchBidderInformation, parameters: [
            XCTMethodIgnoredParameter(), XCTMethodCaptureParameter { fetchBidderInfoCompletion = $0 }
        ])
        fetchBidderInfoCompletion(bidderInfo)

        wait(for: [expectation], timeout: 1)
        XCTAssertMethodCalls(
            mocks.loadRateLimiter,
            .timeUntilNextLoadIsAllowed,
            .loadRateLimit,
            .setLoadRateLimit,
            parameters:
                [request.mediationPlacement], // .timeUntilNextLoadIsAllowed
                [request.mediationPlacement], // .loadRateLimit
                [TimeInterval(5), request.mediationPlacement] // .setLoadRateLimit
        )
    }

    // MARK: - Helper

    private static func registerResponseJSON(_ responseJSON: JSONLoader.JSONFile?, statusCode: Int = 200) {
        let data: Data?
        if let responseJSON = responseJSON {
            data = JSONLoader.loadData(responseJSON)
        } else {
            data = nil
        }

        URLProtocolMock.registerRequestHandler(httpMethod: "POST", urlString: Self.nonTracking_auctionsURLString) { request in
            (
                response: HTTPURLResponse(
                    url: Self.nonTracking_auctionsURL,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: [
                        "x-mediation-ratelimit-reset": Self.rateLimitReset,
                        "x-mediation-auction-id": Self.auctionID
                    ]
                ),
                data: data
            )
        }

        URLProtocolMock.registerRequestHandler(httpMethod: "POST", urlString: Self.tracking_auctionsURLString) { request in
            (
                response: HTTPURLResponse(
                    url: Self.tracking_auctionsURL,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: [
                        "x-mediation-ratelimit-reset": Self.rateLimitReset,
                        "x-mediation-auction-id": Self.auctionID
                    ]
                ),
                data: data
            )
        }
    }
}
