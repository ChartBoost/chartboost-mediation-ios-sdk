// Copyright 2018-2024 Chartboost, Inc.
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
        static let heliumImpression = URL(unsafeString: "https://mediation-impression.mediation-sdk.chartboost.com/v1/event/helium_impression")!
        static let partnerImpression = URL(unsafeString: "https://partner-impression.mediation-sdk.chartboost.com/v1/event/partner_impression")!
        static let reward = URL(unsafeString: "https://reward.mediation-sdk.chartboost.com/v2/event/reward")!
    }

    private static let auctionID = "some auction ID"
    private static let loadID = "some load ID"
    private static let testString = "some data"
    private static let testStringData = testString.data(using: .utf8)!
    private static let testStringAsBased64Encoded = testStringData.base64EncodedString() // "c29tZSBkYXRh"
    private static let innerErrorDescription = "some description"

    private static let metricsEvents: [MetricsEvent] = [
        .init(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 1),
            partnerIdentifier: "id_0"
        ),
        .init(
            start: Date(timeIntervalSince1970: 2),
            end: Date(timeIntervalSince1970: 3),
            error: ChartboostMediationError(code: .initializationFailureUnknown),
            partnerIdentifier: "id_1",
            partnerSDKVersion: "1.2.3",
            partnerAdapterVersion: "4.5.6",
            partnerPlacement: "some placement",
            networkType: .bidding,
            lineItemIdentifier: "some line item ID"
        )
    ]

    private static let simpleCMError = ChartboostMediationError(code: .initializationFailureUnknown)
    private static let innerNSError = NSError(domain: "some domain", code: 777, userInfo: [
        NSLocalizedDescriptionKey: innerErrorDescription
    ])
    private static let nestedCMError = ChartboostMediationError(
        code: .initializationFailureUnknown,
        error: innerNSError,
        data: testStringData
    )

    // MARK: - JSON

    private static let auctionIDJSON: [String: Any] = ["auction_id": auctionID]

    private static let loadIDJSON: [String: Any] = ["x-mediation-load-id": loadID]

    private static let simpleMetricsEventJSON: [String: Any] = [
        "start": 0,
        "end": 1000,
        "duration": 1000,
        "is_success": 1,
        "partner": "id_0",
        "partner_sdk_version": NSNull(),
        "partner_adapter_version": NSNull()
    ]

    private static let fullMetricsEventJSON: [String: Any] = [
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
        "helium_error_message": "Chartboost Mediation initialization has failed."
    ]

    private static let emptyMetricsEventsJSON: [String: [String]] = [
        "metrics": []
    ]

    private static let singleItemMetricsEventsJSON: [String: Any] = [
        "metrics": [simpleMetricsEventJSON]
    ]

    private static let metricsEventsJSON: [String: Any] = [
        "metrics": [simpleMetricsEventJSON, fullMetricsEventJSON]
    ]

    private static let failureResultJSON: [String: String] = ["result": "failure"]

    private static let simpleCMErrorJSON: [String: [String : Any]] = [
        "error": [
            "cm_code": "CM_\(simpleCMError.code)",
            "details": [
                "type": simpleCMError.chartboostMediationCode.name,
            ]
        ]
    ]

    private static let nestedCMErrorJSON: [String: [String : Any]] = [
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
        let request = MetricsHTTPRequest.initialization(events: [], result: .failure, error: nil)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.eventType, .initialization)
        XCTAssertEqual(try request.url, TestURL.initialization)
        XCTAssertEqual(request.method, .post)
        XCTAssertFalse(request.isSDKInitializationRequired)
        XCTAssert(request.customHeaders.isEmpty)
        XCTAssertAnyEqual(json, Dictionary.merge(Self.failureResultJSON, Self.emptyMetricsEventsJSON))
    }

    func testInitializationWithDifferentResults() throws {
        try SDKInitResult.allCases.forEach {
            let request = MetricsHTTPRequest.initialization(events: [], result: $0, error: nil)
            let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
            XCTAssertEqual(request.eventType, .initialization)
            XCTAssertEqual(try request.url, TestURL.initialization)
            XCTAssertEqual(request.method, .post)
            XCTAssertFalse(request.isSDKInitializationRequired)
            XCTAssert(request.customHeaders.isEmpty)
            XCTAssert(NSDictionary(dictionary: json).isEqual(to: Dictionary.merge(["result": $0.rawValue], Self.emptyMetricsEventsJSON)))
        }
    }

    func testInitializationWithSimpleError() throws {
        let request = MetricsHTTPRequest.initialization(events: Self.metricsEvents, result: .failure, error: Self.simpleCMError)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        let expectedJSON = Dictionary.merge(Self.metricsEventsJSON, Self.failureResultJSON, Self.simpleCMErrorJSON)
        XCTAssertEqual(request.eventType, .initialization)
        XCTAssertEqual(try request.url, TestURL.initialization)
        XCTAssertEqual(request.method, .post)
        XCTAssertFalse(request.isSDKInitializationRequired)
        XCTAssert(request.customHeaders.isEmpty)
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testInitializationWithNestedError() throws {
        let request = MetricsHTTPRequest.initialization(events: Self.metricsEvents,result: .failure, error: Self.nestedCMError)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        let expectedJSON = Dictionary.merge(Self.metricsEventsJSON, Self.failureResultJSON, Self.nestedCMErrorJSON)
        XCTAssertEqual(request.eventType, .initialization)
        XCTAssertEqual(try request.url, TestURL.initialization)
        XCTAssertEqual(request.method, .post)
        XCTAssertFalse(request.isSDKInitializationRequired)
        XCTAssert(request.customHeaders.isEmpty)
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testEmptyPrebid() throws {
        let request = MetricsHTTPRequest.prebid(loadID: Self.loadID, events: [])
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.eventType, .prebid)
        XCTAssertEqual(try request.url, TestURL.prebid)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, Self.emptyMetricsEventsJSON)
    }

    func testPrebid() throws {
        let request = MetricsHTTPRequest.prebid(loadID: Self.loadID, events: Self.metricsEvents)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.eventType, .prebid)
        XCTAssertEqual(try request.url, TestURL.prebid)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, Self.metricsEventsJSON)
    }

    func testLoadWithOnlyAuctionID() throws {
        let request = MetricsHTTPRequest.load(auctionID: Self.auctionID, loadID: Self.loadID, events: [], error: nil, adFormat: .banner, size: nil, backgroundDuration: 0)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.eventType, .load)
        XCTAssertEqual(try request.url, TestURL.load)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        var expectedJSON = Dictionary.merge(Self.auctionIDJSON, Self.emptyMetricsEventsJSON)
        expectedJSON = Dictionary.merge(expectedJSON, ["placement_type": "banner", "background_duration": 0])
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testLoad() throws {
        let request = MetricsHTTPRequest.load(auctionID: Self.auctionID, loadID: Self.loadID, events: Self.metricsEvents, error: nil, adFormat: .banner, size: nil, backgroundDuration: nil)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        var expectedJSON = Dictionary.merge(Self.auctionIDJSON, Self.metricsEventsJSON)
        expectedJSON = Dictionary.merge(expectedJSON, ["placement_type": "banner"])
        XCTAssertEqual(request.eventType, .load)
        XCTAssertEqual(try request.url, TestURL.load)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testLoadWithBackgroundDuration() throws {
        let backgroundDuration = TimeInterval.random(in: 0.1...10.0)
        let request = MetricsHTTPRequest.load(auctionID: Self.auctionID, loadID: Self.loadID, events: Self.metricsEvents, error: nil, adFormat: .banner, size: nil, backgroundDuration: backgroundDuration)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        var expectedJSON = Dictionary.merge(Self.auctionIDJSON, Self.metricsEventsJSON)
        expectedJSON = Dictionary.merge(expectedJSON, ["placement_type": "banner", "background_duration": Int(backgroundDuration * 1000)])
        XCTAssertEqual(request.eventType, .load)
        XCTAssertEqual(try request.url, TestURL.load)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testLoadWithError() throws {
        let request = MetricsHTTPRequest.load(auctionID: Self.auctionID, loadID: Self.loadID, events: Self.metricsEvents, error: Self.nestedCMError, adFormat: .banner, size: nil, backgroundDuration: 0)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        var expectedJSON = Dictionary.merge(Self.auctionIDJSON, Self.metricsEventsJSON, Self.nestedCMErrorJSON)
        expectedJSON = Dictionary.merge(expectedJSON, ["placement_type": "banner", "background_duration": 0])
        XCTAssertEqual(request.eventType, .load)
        XCTAssertEqual(try request.url, TestURL.load)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testLoadWithErrorAndBackgroundDuration() throws {
        let backgroundDuration = TimeInterval.random(in: 0.1...10.0)
        let request = MetricsHTTPRequest.load(auctionID: Self.auctionID, loadID: Self.loadID, events: Self.metricsEvents, error: Self.nestedCMError, adFormat: .banner, size: nil, backgroundDuration: backgroundDuration)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        var expectedJSON = Dictionary.merge(Self.auctionIDJSON, Self.metricsEventsJSON, Self.nestedCMErrorJSON)
        expectedJSON = Dictionary.merge(expectedJSON, ["placement_type": "banner", "background_duration": Int(backgroundDuration * 1000)])
        XCTAssertEqual(request.eventType, .load)
        XCTAssertEqual(try request.url, TestURL.load)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testLoadAdaptiveBannerSize() throws {
        let request = MetricsHTTPRequest.load(
            auctionID: Self.auctionID,
            loadID: Self.loadID,
            events: Self.metricsEvents,
            error: Self.nestedCMError,
            adFormat: .adaptiveBanner,
            size: CGSize(width: 400.0, height: 100.0), 
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
            auctionID: Self.auctionID,
            loadID: Self.loadID,
            events: Self.metricsEvents,
            error: Self.nestedCMError,
            adFormat: .adaptiveBanner,
            size: nil, 
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
            auctionID: Self.auctionID,
            loadID: Self.loadID,
            events: Self.metricsEvents,
            error: Self.nestedCMError,
            adFormat: .banner,
            size: nil,
            backgroundDuration: 0
        )
        let jsonDict = try XCTUnwrap(request.bodyJSON)
        XCTAssertEqual(jsonDict["placement_type"] as? String, "banner")
        XCTAssertNil(jsonDict["size"])
    }

    func testShow() throws {
        let request = MetricsHTTPRequest.show(auctionID: Self.auctionID, loadID: Self.loadID, event: try XCTUnwrap(Self.metricsEvents.first))
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        let expectedJSON = Dictionary.merge(Self.auctionIDJSON, Self.singleItemMetricsEventsJSON)
        XCTAssertEqual(request.eventType, .show)
        XCTAssertEqual(try request.url, TestURL.show)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, expectedJSON)
    }

    func testClick() throws {
        let request = MetricsHTTPRequest.click(auctionID: Self.auctionID, loadID: Self.loadID)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.eventType, .click)
        XCTAssertEqual(try request.url, TestURL.click)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, Self.auctionIDJSON)
    }

    func testExpiration() throws {
        let request = MetricsHTTPRequest.expiration(auctionID: Self.auctionID, loadID: Self.loadID)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.eventType, .expiration)
        XCTAssertEqual(try request.url, TestURL.expiration)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, Self.auctionIDJSON)
    }

    func testHeliumImpressionEvent() throws {
        let request = MetricsHTTPRequest.heliumImpression(auctionID: Self.auctionID, loadID: Self.loadID)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.eventType, .heliumImpression)
        XCTAssertEqual(try request.url, TestURL.heliumImpression)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, Self.auctionIDJSON)
    }

    func testPartnerImpressionEvent() throws {
        let request = MetricsHTTPRequest.partnerImpression(auctionID: Self.auctionID, loadID: Self.loadID)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.eventType, .partnerImpression)
        XCTAssertEqual(try request.url, TestURL.partnerImpression)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, Self.auctionIDJSON)
    }

    func testRewardEvent() throws {
        let request = MetricsHTTPRequest.reward(auctionID: Self.auctionID, loadID: Self.loadID)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.eventType, .reward)
        XCTAssertEqual(try request.url, TestURL.reward)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, Self.auctionIDJSON)
    }
}
