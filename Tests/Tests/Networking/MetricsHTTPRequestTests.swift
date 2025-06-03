// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class MetricsHTTPRequestTests: ChartboostMediationTestCase {

    private enum TestURL {
        static let initialization = URL(unsafeString: "https://initialization.mediation-sdk.chartboost.com/v1/event/initialization")!
        static let prebid = URL(unsafeString: "https://prebid.mediation-sdk.chartboost.com/v1/event/prebid")!
        static let load = URL(unsafeString: "https://load.mediation-sdk.chartboost.com/v2/event/load")!
        static let show = URL(unsafeString: "https://show.mediation-sdk.chartboost.com/v1/event/show")!
        static let click = URL(unsafeString: "https://click.mediation-sdk.chartboost.com/v2/event/click")!
        static let expiration = URL(unsafeString: "https://expiration.mediation-sdk.chartboost.com/v1/event/expiration")!
        static let heliumImpression = URL(unsafeString: "https://mediation-impression.mediation-sdk.chartboost.com/v2/event/helium_impression")!
        static let partnerImpression = URL(unsafeString: "https://partner-impression.mediation-sdk.chartboost.com/v1/event/partner_impression")!
        static let reward = URL(unsafeString: "https://reward.mediation-sdk.chartboost.com/v2/event/reward")!
    }

    let adFormat = AdFormat.interstitial
    let auctionID = "some auction ID"
    let loadID = "some load ID"
    let testString = "some data"
    lazy var testStringData = testString.data(using: .utf8)!
    lazy var testStringAsBased64Encoded = testStringData.base64EncodedString() // "c29tZSBkYXRh"
    let innerErrorDescription = "some description"

    let metricsEvents: [MetricsEvent] = [
        .init(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 1),
            partnerID: "id_0"
        ),
        .init(
            start: Date(timeIntervalSince1970: 2),
            end: Date(timeIntervalSince1970: 3),
            error: ChartboostMediationError(code: .initializationFailureUnknown),
            partnerID: "id_1",
            partnerSDKVersion: "1.2.3",
            partnerAdapterVersion: "4.5.6",
            partnerPlacement: "some placement",
            networkType: .bidding,
            lineItemIdentifier: "some line item ID"
        )
    ]

    let simpleCMError = ChartboostMediationError(code: .initializationFailureUnknown)
    lazy var innerNSError = NSError(domain: "some domain", code: 777, userInfo: [
        NSLocalizedDescriptionKey: innerErrorDescription
    ])
    lazy var nestedCMError = ChartboostMediationError(
        code: .initializationFailureUnknown,
        error: innerNSError,
        data: testStringData
    )

    // MARK: - JSON

    lazy var auctionIDJSON: [String: Any] = ["auction_id": auctionID]

    lazy var bidderJSON: [String: Any] = ["lurl": "lossURL", "nurl": "winURL", "price": 42.24, "seat": "some partnerIdentifier"]
    lazy var bidders: NSArray = [bidderJSON, bidderJSON]
    lazy var heliumImpressionJSON: [String: Any] = ["auction_id": auctionID, "bidders": bidders, "placement_type": "interstitial", "winner": "some partnerIdentifier", "type": "bidding", "line_item_id": "some lineItemID", "partner_placement": "some partnerPlacement", "price": 42.24]
    lazy var heliumImpressionAdaptiveBannerJSON: [String: Any] = ["auction_id": auctionID, "bidders": bidders, "placement_type": "adaptive_banner", "size": [ "w": 180, "h": 50], "winner": "some partnerIdentifier", "type": "bidding", "line_item_id": "some lineItemID", "partner_placement": "some partnerPlacement", "price": 42.24]

    func customHeaders(format: AdFormat? = nil) -> [String: Any] {
        ["x-mediation-load-id": loadID,
         "x-mediation-ad-type": (format ?? adFormat).rawValue]
    }

    let simpleMetricsEventJSON: [String: Any] = [
        "start": 0,
        "end": 1000,
        "duration": 1000,
        "is_success": 1,
        "partner": "id_0",
        "partner_sdk_version": NSNull(),
        "partner_adapter_version": NSNull()
    ]

    let fullMetricsEventJSON: [String: Any] = [
        "start": 2000,
        "end": 3000,
        "duration": 1000,
        "is_success": 0,
        "partner": "id_1",
        "partner_sdk_version": "1.2.3",
        "partner_adapter_version": "4.5.6",
        "partner_placement": "some placement",
        "line_item_id": "some line item ID",
        "network_type": "bidding",
        "helium_error": "CM_INITIALIZATION_FAILURE_UNKNOWN",
        "helium_error_code": "CM_100",
        "helium_error_message": "Initialization has failed."
    ]

    let emptyMetricsEventsJSON: [String: [String]] = [
        "metrics": []
    ]

    lazy var singleItemMetricsEventsJSON: [String: Any] = [
        "metrics": [simpleMetricsEventJSON]
    ]

    lazy var metricsEventsJSON: [String: Any] = [
        "metrics": [simpleMetricsEventJSON, fullMetricsEventJSON]
    ]

    let failureResultJSON: [String: String] = ["result": "failure"]

    lazy var simpleCMErrorJSON: [String: [String : Any]] = [
        "error": [
            "cm_code": "CM_\(simpleCMError.code)",
            "details": [
                "type": simpleCMError.chartboostMediationCode.name,
            ]
        ]
    ]

    lazy var nestedCMErrorJSON: [String: [String : Any]] = [
        "error": [
            "cm_code": "CM_\(nestedCMError.code)",
            "details": [
                "type": simpleCMError.chartboostMediationCode.name,
                "data_as_string": testStringAsBased64Encoded,
                "description": "Error Domain=\(innerNSError.domain) Code=\(innerNSError.code) \"\(innerErrorDescription)\" UserInfo={\(NSLocalizedDescriptionKey)=\(innerErrorDescription)}"
            ]
        ]
    ]

    // MARK: - Tests
    func testEmptyInitialization() throws {
        let request = MetricsHTTPRequest.initialization(
            eventTracker: ServerEventTracker(url: TestURL.initialization),
               metricsEvent: [],
               result: .failure,
               error: nil
           )

           XCTAssertEqual(request.url, TestURL.initialization)
           XCTAssertEqual(request.method, .post)
           XCTAssertFalse(request.isSDKInitializationRequired)
           XCTAssert(request.customHeaders.isEmpty)

           let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
           let expectedJSON = Dictionary.merge(failureResultJSON, emptyMetricsEventsJSON)
           XCTAssertAnyEqual(json, expectedJSON)
    }

    func testInitializationWithDifferentResults() throws {
        try SDKInitResult.allCases.forEach { result in
            let request = MetricsHTTPRequest.initialization(
                eventTracker: ServerEventTracker(url: TestURL.initialization),
                metricsEvent: [],
                result: result,
                error: nil
            )
            let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
            XCTAssertEqual( request.url, TestURL.initialization)
            XCTAssertEqual(request.method, .post)
            XCTAssertFalse(request.isSDKInitializationRequired)
            XCTAssert(request.customHeaders.isEmpty)

            let expectedJSON = Dictionary.merge(["result": result.rawValue], emptyMetricsEventsJSON)
            XCTAssertAnyEqual(json, expectedJSON)
        }
    }

    func testInitializationWithSimpleError() throws {

        let request = MetricsHTTPRequest.initialization(
            eventTracker: ServerEventTracker(url: TestURL.initialization),
            metricsEvent: metricsEvents,
            result: .failure,
            error: simpleCMError
        )
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        let expectedJSON = Dictionary.merge(metricsEventsJSON, failureResultJSON, simpleCMErrorJSON)
//        XCTAssertEqual(request.eventType, .initialization)
        XCTAssertEqual(request.url, TestURL.initialization)
        XCTAssertEqual(request.method, .post)
        XCTAssertFalse(request.isSDKInitializationRequired)
        XCTAssert(request.customHeaders.isEmpty)
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testInitializationWithNestedError() throws {
        let request = MetricsHTTPRequest.initialization(eventTracker: ServerEventTracker(url: TestURL.initialization), metricsEvent: metricsEvents,result: .failure, error: nestedCMError)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        let expectedJSON = Dictionary.merge(metricsEventsJSON, failureResultJSON, nestedCMErrorJSON)
        XCTAssertEqual(request.url, TestURL.initialization)
        XCTAssertEqual(request.method, .post)
        XCTAssertFalse(request.isSDKInitializationRequired)
        XCTAssert(request.customHeaders.isEmpty)
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testEmptyPrebid() throws {
        let request = MetricsHTTPRequest.prebid(eventTracker: ServerEventTracker(url: TestURL.prebid), adFormat: adFormat, loadID: loadID, metricsEvents: [])
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.url, TestURL.prebid)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, customHeaders())
        XCTAssertAnyEqual(json, emptyMetricsEventsJSON)
    }

    func testPrebid() throws {
        let request = MetricsHTTPRequest.prebid(eventTracker: ServerEventTracker(url: TestURL.prebid), adFormat: adFormat, loadID: loadID, metricsEvents: metricsEvents)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.url, TestURL.prebid)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, customHeaders())
        XCTAssertAnyEqual(json, metricsEventsJSON)
    }

    func testLoadWithOnlyAuctionID() throws {
        let start = Date()
        let end = start.addingTimeInterval(TimeInterval.random(in: 1...5))
        let duration = durationMs(start: start, end: end)
        let request = MetricsHTTPRequest.load(eventTracker: ServerEventTracker(url: TestURL.load), auctionID: auctionID, loadID: loadID, metricsEvent: [], error: nil, adFormat: .banner, size: nil, start: start, end: end, backgroundDuration: 0)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.url, TestURL.load)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, customHeaders(format: .banner))
        var expectedJSON = Dictionary.merge(auctionIDJSON, emptyMetricsEventsJSON)
        expectedJSON = Dictionary.merge(expectedJSON, ["placement_type": "banner", "start": start.unixTimestamp, "end": end.unixTimestamp, "duration": duration, "background_duration": 0])
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testLoad() throws {
        let start = Date()
        let end = start.addingTimeInterval(TimeInterval.random(in: 1...5))
        let duration = durationMs(start: start, end: end)
        let request = MetricsHTTPRequest.load(eventTracker: ServerEventTracker(url: TestURL.load),auctionID: auctionID, loadID: loadID, metricsEvent: metricsEvents, error: nil, adFormat: .banner, size: nil, start: start, end: end, backgroundDuration: nil)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        var expectedJSON = Dictionary.merge(auctionIDJSON, metricsEventsJSON)
        expectedJSON = Dictionary.merge(expectedJSON, ["placement_type": "banner", "start": start.unixTimestamp, "end": end.unixTimestamp, "duration": duration])
        XCTAssertEqual(request.url, TestURL.load)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, customHeaders(format: .banner))
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testLoadWithBackgroundDuration() throws {
        let start = Date()
        let end = start.addingTimeInterval(TimeInterval.random(in: 1...5))
        let duration = durationMs(start: start, end: end)
        let backgroundDuration = TimeInterval.random(in: 0.1...10.0)
        let request = MetricsHTTPRequest.load(eventTracker: ServerEventTracker(url: TestURL.load), auctionID: auctionID, loadID: loadID, metricsEvent: metricsEvents, error: nil, adFormat: .banner, size: nil, start: start, end: end, backgroundDuration: backgroundDuration)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        var expectedJSON = Dictionary.merge(auctionIDJSON, metricsEventsJSON)
        expectedJSON = Dictionary.merge(expectedJSON, ["placement_type": "banner", "start": start.unixTimestamp, "end": end.unixTimestamp, "duration": duration, "background_duration": Int(backgroundDuration * 1000)])
        XCTAssertEqual(request.url, TestURL.load)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, customHeaders(format: .banner))
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testLoadWithError() throws {
        let start = Date()
        let end = start.addingTimeInterval(TimeInterval.random(in: 1...5))
        let duration = durationMs(start: start, end: end)
        let request = MetricsHTTPRequest.load(eventTracker: ServerEventTracker(url: TestURL.load), auctionID: auctionID, loadID: loadID, metricsEvent: metricsEvents, error: nestedCMError, adFormat: .banner, size: nil, start: start, end: end, backgroundDuration: 0)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        var expectedJSON = Dictionary.merge(auctionIDJSON, metricsEventsJSON, nestedCMErrorJSON)
        expectedJSON = Dictionary.merge(expectedJSON, ["placement_type": "banner", "start": start.unixTimestamp, "end": end.unixTimestamp, "duration": duration, "background_duration": 0])
        XCTAssertEqual(request.url, TestURL.load)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, customHeaders(format: .banner))
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testLoadWithErrorAndBackgroundDuration() throws {
        let start = Date()
        let end = start.addingTimeInterval(TimeInterval.random(in: 1...5))
        let duration = durationMs(start: start, end: end)
        let backgroundDuration = TimeInterval.random(in: 0.1...10.0)
        let request = MetricsHTTPRequest.load(eventTracker: ServerEventTracker(url: TestURL.load), auctionID: auctionID, loadID: loadID, metricsEvent: metricsEvents, error: nestedCMError, adFormat: .banner, size: nil, start: start, end: end, backgroundDuration: backgroundDuration)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        var expectedJSON = Dictionary.merge(auctionIDJSON, metricsEventsJSON, nestedCMErrorJSON)
        expectedJSON = Dictionary.merge(expectedJSON, ["placement_type": "banner", "start": start.unixTimestamp, "end": end.unixTimestamp, "duration": duration, "background_duration": Int(backgroundDuration * 1000)])
        XCTAssertEqual(request.url, TestURL.load)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, customHeaders(format: .banner))
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testLoadAdaptiveBannerSize() throws {
        let request = MetricsHTTPRequest.load(
            eventTracker: ServerEventTracker(url: TestURL.load),
            auctionID: auctionID,
            loadID: loadID,
            metricsEvent: metricsEvents,
            error: nestedCMError,
            adFormat: .adaptiveBanner,
            size: CGSize(width: 400.0, height: 100.0),
            start: Date(),
            end: Date().addingTimeInterval(TimeInterval.random(in: 0.1...5)),
            backgroundDuration: 0
        )
        let jsonDict = try XCTUnwrap(request.bodyJSON)
        XCTAssertEqual(jsonDict["placement_type"] as? String, "adaptive_banner")
        let sizeDict = try XCTUnwrap(jsonDict["size"] as? [String: Any])
        let width = try XCTUnwrap(sizeDict["w"] as? Int)
        let height = try XCTUnwrap(sizeDict["h"] as? Int)
        XCTAssertEqual(width, 400)
        XCTAssertEqual(height, 100)
    }

    func testLoadAdaptiveBannerWhenSizeIsNil() throws {
        let request = MetricsHTTPRequest.load(
            eventTracker: ServerEventTracker(url: TestURL.load),
            auctionID: auctionID,
            loadID: loadID,
            metricsEvent: metricsEvents,
            error: nestedCMError,
            adFormat: .adaptiveBanner,
            size: nil,
            start: Date(),
            end: Date().addingTimeInterval(TimeInterval.random(in: 0.1...5)),
            backgroundDuration: 0
        )
        let jsonDict = try XCTUnwrap(request.bodyJSON)
        XCTAssertEqual(jsonDict["placement_type"] as? String, "adaptive_banner")
        // Size should be included, but it should be 0.
        let sizeDict = try XCTUnwrap(jsonDict["size"] as? [String: Any])
        let width = try XCTUnwrap(sizeDict["w"] as? Int)
        let height = try XCTUnwrap(sizeDict["h"] as? Int)
        XCTAssertEqual(width, 0)
        XCTAssertEqual(height, 0)
    }

    func testLoadSizeIsNilWhenAdFormatIsNotAdaptiveBanner() throws {
        let request = MetricsHTTPRequest.load(
            eventTracker: ServerEventTracker(url: TestURL.load),
            auctionID: auctionID,
            loadID: loadID,
            metricsEvent: metricsEvents,
            error: nestedCMError,
            adFormat: .banner,
            size: nil,
            start: Date(),
            end: Date().addingTimeInterval(TimeInterval.random(in: 0.1...5)),
            backgroundDuration: 0
        )
        let jsonDict = try XCTUnwrap(request.bodyJSON)
        XCTAssertEqual(jsonDict["placement_type"] as? String, "banner")
        XCTAssertNil(jsonDict["size"])
    }

    func testShow() throws {
        let request = MetricsHTTPRequest.show(eventTracker: ServerEventTracker(url: TestURL.show), adFormat: adFormat, auctionID: auctionID, loadID: loadID, metricsEvent: try XCTUnwrap(metricsEvents.first))
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        let expectedJSON = Dictionary.merge(auctionIDJSON, singleItemMetricsEventsJSON)
        XCTAssertEqual(request.url, TestURL.show)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, customHeaders())
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testClick() throws {
        let request = MetricsHTTPRequest.click(eventTracker: ServerEventTracker(url: TestURL.click), adFormat: adFormat, auctionID: auctionID, loadID: loadID)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.url, TestURL.click)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, customHeaders())
        XCTAssertAnyEqual(json, auctionIDJSON)
    }

    func testExpiration() throws {
        let request = MetricsHTTPRequest.expiration(eventTracker: ServerEventTracker(url: TestURL.expiration), adFormat: adFormat, auctionID: auctionID, loadID: loadID)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.url, TestURL.expiration)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, customHeaders())
        XCTAssertAnyEqual(json, auctionIDJSON)
    }

    func testHeliumImpressionEvent() throws {
        let bids: [Bid] = [Bid.test(), Bid.test()]
        let bidders = bids.map { LoadedAd.Bidder(bid: $0) }

        let request = MetricsHTTPRequest.mediationImpression(eventTracker: ServerEventTracker(url: TestURL.heliumImpression), adFormat: adFormat, size: nil, auctionID: auctionID, loadID: loadID, bidders: bidders, winner: bids[0].partnerID, type: "bidding", price: 42.24, lineItemID: "some lineItemID", partnerPlacement: "some partnerPlacement")
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.url, TestURL.heliumImpression)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, customHeaders())
        XCTAssertAnyEqual(json, heliumImpressionJSON)
    }

    func testHeliumImpressionAdaptiveBannerEvent() throws {
        let bids: [Bid] = [Bid.test(), Bid.test()]
        let bidders = bids.map { LoadedAd.Bidder(bid: $0) }

        let request = MetricsHTTPRequest.mediationImpression(eventTracker: ServerEventTracker(url: TestURL.heliumImpression), adFormat: .adaptiveBanner, size: CGSize(width: 180, height: 50), auctionID: auctionID, loadID: loadID, bidders: bidders, winner: bids[0].partnerID, type: "bidding", price: 42.24, lineItemID: "some lineItemID", partnerPlacement: "some partnerPlacement")
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.url, TestURL.heliumImpression)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, customHeaders(format: .adaptiveBanner))
        XCTAssertAnyEqual(json, heliumImpressionAdaptiveBannerJSON)
    }

    func testPartnerImpressionEvent() throws {
        let request = MetricsHTTPRequest.partnerImpression(eventTracker: ServerEventTracker(url: TestURL.partnerImpression), adFormat: adFormat, auctionID: auctionID, loadID: loadID)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.url, TestURL.partnerImpression)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, customHeaders())
        XCTAssertAnyEqual(json, auctionIDJSON)
    }

    func testRewardEvent() throws {
        let request = MetricsHTTPRequest.reward(eventTracker: ServerEventTracker(url: TestURL.reward), adFormat: adFormat, auctionID: auctionID, loadID: loadID)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.url, TestURL.reward)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, customHeaders())
        XCTAssertAnyEqual(json, auctionIDJSON)
    }

    func durationMs(start: Date, end: Date) -> Int {
        end.unixTimestamp - start.unixTimestamp
    }
}
