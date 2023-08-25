// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class MetricsHTTPRequestTests: HeliumTestCase {

    private enum TestURL {
        static let initialization = URL(string: "https://helium-sdk.chartboost.com/v1/event/initialization")!
        static let prebid = URL(string: "https://helium-sdk.chartboost.com/v1/event/prebid")!
        static let load = URL(string: "https://helium-sdk.chartboost.com/v1/event/load")!
        static let show = URL(string: "https://helium-sdk.chartboost.com/v1/event/show")!
        static let click = URL(string: "https://helium-sdk.chartboost.com/v2/event/click")!
        static let expiration = URL(string: "https://helium-sdk.chartboost.com/v1/event/expiration")!
        static let heliumImpression = URL(string: "https://helium-sdk.chartboost.com/v1/event/helium_impression")!
        static let partnerImpression = URL(string: "https://helium-sdk.chartboost.com/v1/event/partner_impression")!
        static let reward = URL(string: "https://helium-sdk.chartboost.com/v2/event/reward")!
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
        let request = MetricsHTTPRequest.load(auctionID: Self.auctionID, loadID: Self.loadID, events: [], error: nil)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        XCTAssertEqual(request.eventType, .load)
        XCTAssertEqual(try request.url, TestURL.load)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, Dictionary.merge(Self.auctionIDJSON, Self.emptyMetricsEventsJSON))
    }

    func testLoad() throws {
        let request = MetricsHTTPRequest.load(auctionID: Self.auctionID, loadID: Self.loadID, events: Self.metricsEvents, error: nil)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        let expectedJSON = Dictionary.merge(Self.auctionIDJSON, Self.metricsEventsJSON)
        XCTAssertEqual(request.eventType, .load)
        XCTAssertEqual(try request.url, TestURL.load)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, expectedJSON)
    }
    
    func testLoadWithError() throws {
        let request = MetricsHTTPRequest.load(auctionID: Self.auctionID, loadID: Self.loadID, events: Self.metricsEvents, error: Self.nestedCMError)
        let json = try JSONSerialization.jsonDictionary(with: request.bodyData)
        let expectedJSON = Dictionary.merge(Self.auctionIDJSON, Self.metricsEventsJSON, Self.nestedCMErrorJSON)
        XCTAssertEqual(request.eventType, .load)
        XCTAssertEqual(try request.url, TestURL.load)
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.isSDKInitializationRequired)
        XCTAssertAnyEqual(request.customHeaders, Self.loadIDJSON)
        XCTAssertAnyEqual(json, expectedJSON)
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
