// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class RewardedCallbackHTTPRequestTests: HeliumTestCase {

    enum URLPathParameter {
        static let revenue = "revenue=%25%25AD_REVENUE%25%25"
        static let cpm = "cpm=%25%25CPM_PRICE%25%25"
        static let networkName = "network=%25%25NETWORK_NAME%25%25"
        static let customData = "data=%25%25CUSTOM_DATA%25%25"
        static let timestampe = "imp_ts=%25%25SDK_TIMESTAMP%25%25"
        static let all = "\(revenue)&\(cpm)&\(networkName)&\(customData)&\(timestampe)"
    }

    enum KVPair {
        static let revenue = "\"revenue\":%%AD_REVENUE%%,"
        static let cpm = "\"cpm\":%%CPM_PRICE%%,"
        static let networkName = "\"network\":\"%%NETWORK_NAME%%\","
        static let customData = "\"data\":\"%%CUSTOM_DATA%%\","
        static let timestampe = "\"imp_ts\":\"%%SDK_TIMESTAMP%%\","
        static let all = "\(revenue)\(cpm)\(networkName)\(customData)\(timestampe)"
    }

    struct RewardedCallbackTestError: LocalizedError {
        var errorDescription: String?
    }

    static let urlString = "https://myserver.com/some/path"

    /// A format string for the JSON body that takes only one string input (see `KVPair`).
    static let bodyFormatString =
"""
{
    %@
    \"hash\":\"999123424212324122324\",
    \"hello\":\"world\",
    \"keyword_A\":\"value_of_keyword_A_set_by_server\",
    \"load_ts\":123232445434
}
"""

    // MARK: - RewardedCallback

    /// Validate that a callback object is created when there minimal information.
    func testMinimalRewardedCallback() throws {
        let dictionary: [String: Any] = [
            "url": Self.urlString
        ]
        let rewardedCallback = try Self.makeRewardedCallback(from: dictionary, adRevenue: nil, cpmPrice: nil)

        XCTAssertNil(rewardedCallback.adRevenue)
        XCTAssertNil(rewardedCallback.cpmPrice)
        XCTAssertEqual(rewardedCallback.partnerIdentifier, Bid.defaultPartnerIdentifierMock)
        XCTAssertEqual(rewardedCallback.urlString, Self.urlString)
        XCTAssertEqual(rewardedCallback.method, .get)
        XCTAssertEqual(rewardedCallback.maxRetries, 2)
        XCTAssertEqual(rewardedCallback.retryDelay, 1)
        XCTAssertNil(rewardedCallback.body)
    }

    /// Validate that no rewarded callback object is created when it is fully specified.
    func testFullySpecifiedRewardedCallback() throws {
        let dictionary: [String: Any] = [
            "url": Self.urlString,
            "method": "POST",
            "max_retries": 5,
            "retry_delay": 10,
            "body": Self.bodyStringWithInput(KVPair.all)
        ]
        let rewardedCallback = try Self.makeRewardedCallback(from: dictionary, adRevenue: 32.1, cpmPrice: 12.3)

        XCTAssertEqual(rewardedCallback.adRevenue, 32.1)
        XCTAssertEqual(rewardedCallback.cpmPrice, 12.3)
        XCTAssertEqual(rewardedCallback.partnerIdentifier, Bid.defaultPartnerIdentifierMock)
        XCTAssertEqual(rewardedCallback.urlString, Self.urlString)
        XCTAssertEqual(rewardedCallback.method, .post)
        XCTAssertEqual(rewardedCallback.maxRetries, 5)
        XCTAssertEqual(rewardedCallback.retryDelay, 10)
        XCTAssertNotNil(rewardedCallback.body)
    }

    // MARK: - RewardedCallbackHTTPRequest

    /// Test the basic properties of a GET `RewardedCallbackHTTPRequest`.
    func testGetRequestBasics() throws {
        let request = try Self.makeRewardedCallbackHTTPRequest(
            from: [
                "url": Self.urlString,
                "body": Self.bodyStringWithInput(""),
                "method": HTTP.Method.get.rawValue,
                "max_retries": 5,
                "retry_delay": 7
            ]
        )
        XCTAssertEqual(request.method, .get)
        XCTAssert(request.url.absoluteString == Self.urlString)
        XCTAssertEqual(request.maxRetries, 5)
        XCTAssertEqual(request.retryDelay, 7)
        XCTAssertNil(request.bodyData)
        XCTAssert(request.customHeaders.isEmpty)
    }

    /// Test the basic properties of a POST `RewardedCallbackHTTPRequest`.
    func testPostRequestBasics() throws {
        let request = try Self.makeRewardedCallbackHTTPRequest(
            from: [
                "url": Self.urlString,
                "body": Self.bodyStringWithInput(""),
                "method": HTTP.Method.post.rawValue,
                "max_retries": 5,
                "retry_delay": 7
            ]
        )
        let bodyString = try request.bodyString
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.url.absoluteString == Self.urlString)
        XCTAssertEqual(request.maxRetries, 5)
        XCTAssertEqual(request.retryDelay, 7)
        XCTAssert(bodyString.contains("\"hash\":\"999123424212324122324\""))
        XCTAssert(bodyString.contains("\"hello\":\"world\""))
        XCTAssert(bodyString.contains("\"keyword_A\":\"value_of_keyword_A_set_by_server"))
        XCTAssert(bodyString.contains("\"load_ts\":123232445434"))
        XCTAssert(request.customHeadersHasPositiveContentLength)
    }

    /// Validates that request generation fails as expected.
    func testRequestGenerationWithInvalidInputs() throws {
        XCTAssertThrowsError(try Self.makeRewardedCallbackHTTPRequest(
            from: [
                "url": "bad URL",
                "method": "POST"
            ]
        ))

        let request = try Self.makeRewardedCallbackHTTPRequest(
            from: [
                "url": Self.urlString,
                "method": "bad method" // default to GET
            ]
        )
        XCTAssertEqual(request.method, .get)
        XCTAssert(request.url.absoluteString == Self.urlString)
        XCTAssert(request.customHeaders.isEmpty)
    }

    /// Validates that a URL request is generated using nil valid data.
    func testRequestGenerationWithValidNilInputs() throws {
        let request = try Self.makeRewardedCallbackHTTPRequest(
            from: [
                "url": "https://myserver.com/some/path?\(URLPathParameter.all)",
                "body": Self.bodyStringWithInput(KVPair.all),
                "method": "POST"
            ],
            adRevenue: nil,
            cpmPrice: nil,
            customData: nil,
            timestampMs: 123
        )
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.url.absoluteString == "https://myserver.com/some/path?revenue=&cpm=&network=some%20partnerIdentifier&data=&imp_ts=123")
        XCTAssertFalse(try request.bodyString.contains("\"revenue\""))
        XCTAssertFalse(try request.bodyString.contains("\"cpm\""))
        XCTAssert(try request.bodyString.contains("\"data\":\"\""))
        XCTAssert(request.customHeadersHasPositiveContentLength)
    }

    /// Validates that a URL request is generated with all accepted inputs together.
    func testRequestGenerationWithAllInputsTogether() throws {
        let request = try Self.makeRewardedCallbackHTTPRequest(
            from: [
                "url": "https://myserver.com/some/path?\(URLPathParameter.all)",
                "body": Self.bodyStringWithInput(KVPair.all),
                "method": "POST"
            ],
            adRevenue: 12.3,
            cpmPrice: 45.6,
            partnerIdentifier: "some network",
            customData: "some custome data",
            timestampMs: 789
        )
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.url.absoluteString == "https://myserver.com/some/path?revenue=12.3&cpm=45.6&network=some%20network&data=some%20custome%20data&imp_ts=789")
        XCTAssert(try request.bodyString.contains("\"revenue\":12.3"))
        XCTAssert(try request.bodyString.contains("\"cpm\":45.6"))
        XCTAssert(try request.bodyString.contains("\"network\":\"some network\""))
        XCTAssert(try request.bodyString.contains("\"data\":\"some custome data\""))
        XCTAssert(try request.bodyString.contains("\"imp_ts\":\"789\""))
        XCTAssert(request.customHeadersHasPositiveContentLength)
    }

    /// Validates that %%AD_REVENUE%% macro replacement occurs in the URL and body.
    func testMacroReplacementAdRevenue() throws {
        let request = try Self.makeRewardedCallbackHTTPRequest(
            from: [
                "url": "https://myserver.com/some/path?\(URLPathParameter.revenue)",
                "body": Self.bodyStringWithInput(KVPair.revenue),
                "method": "POST"
            ],
            adRevenue: 10.99
        )
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.url.absoluteString == "https://myserver.com/some/path?revenue=10.99")
        XCTAssert(try request.bodyString.contains("\"revenue\":10.99"))
        XCTAssert(request.customHeadersHasPositiveContentLength)
    }

    /// Validates that %%AD_REVENUE%% macro replacement occurs in the URL and body when given nil inputs.
    func testMacroReplacementAdRevenueNil() throws {
        let request = try Self.makeRewardedCallbackHTTPRequest(
            from: [
                "url": "https://myserver.com/some/path?\(URLPathParameter.revenue)",
                "body": Self.bodyStringWithInput(KVPair.revenue),
                "method": "POST"
            ],
            adRevenue: nil
        )
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.url.absoluteString == "https://myserver.com/some/path?revenue=")
        XCTAssertFalse(try request.bodyString.contains("\"revenue\""))
        XCTAssert(request.customHeadersHasPositiveContentLength)
    }

    /// Validates that %%CPM_PRICE%% macro replacement occurs in the URL and body.
    func testMacroReplacementCPMPrice() throws {
        let request = try Self.makeRewardedCallbackHTTPRequest(
            from: [
                "url": "https://myserver.com/some/path?\(URLPathParameter.cpm)",
                "body": Self.bodyStringWithInput(KVPair.cpm),
                "method": "POST"
            ],
            cpmPrice: 999.99
        )
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.url.absoluteString == "https://myserver.com/some/path?cpm=999.99")
        XCTAssert(try request.bodyString.contains("\"cpm\":999.99"))
        XCTAssert(request.customHeadersHasPositiveContentLength)
    }

    /// Validates that %%CPM_PRICE%% macro replacement occurs in the URL and body when given nil inputs.
    func testMacroReplacementCPMPriceNil() throws {
        let request = try Self.makeRewardedCallbackHTTPRequest(
            from: [
                "url": "https://myserver.com/some/path?\(URLPathParameter.cpm)",
                "body": Self.bodyStringWithInput(KVPair.cpm),
                "method": "POST"
            ],
            cpmPrice: nil
        )
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.url.absoluteString == "https://myserver.com/some/path?cpm=")
        XCTAssertFalse(try request.bodyString.contains("\"cpm\""))
        XCTAssert(request.customHeadersHasPositiveContentLength)
    }

    /// Validates that %%NETWORK_NAME%% macro replacement occurs in the URL and body.
    func testMacroReplacementNetworkName() throws {
        let request = try Self.makeRewardedCallbackHTTPRequest(
            from: [
                "url": "https://myserver.com/some/path?\(URLPathParameter.networkName)",
                "body": Self.bodyStringWithInput(KVPair.networkName),
                "method": "POST"
            ],
            partnerIdentifier: "some network"
        )
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.url.absoluteString == "https://myserver.com/some/path?network=some%20network")
        XCTAssert(try request.bodyString.contains("\"network\":\"some network\""))
        XCTAssert(request.customHeadersHasPositiveContentLength)
    }

    /// Validates that %%CUSTOM_DATA%% macro replacement occurs in the URL and body.
    func testMacroReplacementCustomData() throws {
        let request = try Self.makeRewardedCallbackHTTPRequest(
            from: [
                "url": "https://myserver.com/some/path?data=%25%25CUSTOM_DATA%25%25",
                "body": Self.bodyStringWithInput(KVPair.customData),
                "method": "POST"
            ],
            customData: "TEST URI ENCODING"
        )
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.url.absoluteString == "https://myserver.com/some/path?data=TEST%20URI%20ENCODING")
        XCTAssert(try request.bodyString.contains("\"data\":\"TEST URI ENCODING\""))
        XCTAssert(request.customHeadersHasPositiveContentLength)
    }

    /// Validates that %%CUSTOM_DATA%% macro replacement occurs in the URL and body when given nil inputs.
    func testMacroReplacementCustomDataNil() throws {
        let request = try Self.makeRewardedCallbackHTTPRequest(
            from: [
                "url": "https://myserver.com/some/path?\(URLPathParameter.customData)",
                "body": Self.bodyStringWithInput(KVPair.customData),
                "method": "POST"
            ],
            customData: nil
        )
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.url.absoluteString == "https://myserver.com/some/path?data=")
        XCTAssert(try request.bodyString.contains("\"data\":\"\""))
        XCTAssert(request.customHeadersHasPositiveContentLength)
    }

    /// Validates that %%SDK_TIMESTAMP%% macro replacement occurs in the URL and body.
    func testMacroReplacementSDKTimestamp() throws {
        let timestampMs = Int(Date().timeIntervalSince1970 * 1000)
        let request = try Self.makeRewardedCallbackHTTPRequest(
            from: [
                "url": "https://myserver.com/some/path?\(URLPathParameter.timestampe)",
                "body": Self.bodyStringWithInput(KVPair.timestampe),
                "method": "POST"
            ],
            timestampMs: timestampMs
        )
        XCTAssertEqual(request.method, .post)
        XCTAssert(request.url.absoluteString == "https://myserver.com/some/path?imp_ts=\(timestampMs)")
        XCTAssert(try request.bodyString.contains("\"imp_ts\":\"\(timestampMs)\""))
        XCTAssert(request.customHeadersHasPositiveContentLength)
    }
}

// MARK: - Helpers

private extension RewardedCallbackHTTPRequestTests {

    /// Expected input is one or more escaped JSON KV pair. See `KVPair`.
    static func bodyStringWithInput(_ input: String) -> String {
        String(format: Self.bodyFormatString, input)
    }

    static func makeRewardedCallback(
        from dictionary: [String: Any],
        adRevenue: Double? = nil,
        cpmPrice: Double? = nil,
        partnerIdentifier: PartnerIdentifier = Bid.defaultPartnerIdentifierMock
    ) throws -> RewardedCallback {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let decoder = JSONDecoder()
        let rewardedCallbackData = try decoder.decode(RewardedCallbackData.self, from: data)
        let bid = Bid.makeMock(
            adRevenue: adRevenue,
            cpmPrice: cpmPrice,
            partnerIdentifier: partnerIdentifier,
            rewardedCallbackData: rewardedCallbackData
        )
        let rewardedCallback = bid.rewardedCallback
        guard let rewardedCallback = rewardedCallback else {
            throw RewardedCallbackTestError(errorDescription: "Failed to create `RewardedCallback`.")
        }
        return rewardedCallback
    }

    static func makeRewardedCallbackHTTPRequest(
        from dictionary: [String: Any],
        adRevenue: Double? = nil,
        cpmPrice: Double? = nil,
        partnerIdentifier: PartnerIdentifier = Bid.defaultPartnerIdentifierMock,
        customData: String? = nil,
        timestampMs: Int = Int(Date().timeIntervalSince1970 * 1000)
    ) throws -> RewardedCallbackHTTPRequest {
        let rewardedCallback = try makeRewardedCallback(
            from: dictionary,
            adRevenue: adRevenue,
            cpmPrice: cpmPrice,
            partnerIdentifier: partnerIdentifier
        )
        guard let request = RewardedCallbackHTTPRequest(
            rewardedCallback: rewardedCallback,
            customData: customData,
            timestampMs: timestampMs
        ) else {
            throw RewardedCallbackTestError(errorDescription: "Failed to create `RewardedCallbackHTTPRequest`.")
        }
        return request
    }
}

private extension RewardedCallbackHTTPRequest {
    var bodyString: String {
        get throws {
            try XCTUnwrap(String(data: try XCTUnwrap(bodyData), encoding: .utf8))
        }
    }

    var customHeadersHasPositiveContentLength: Bool {
        guard
            let contentLengthString = customHeaders[HTTP.HeaderKey.contentLength.rawValue],
            let contentLength = Int(contentLengthString),
            contentLength > 0
        else {
            return false
        }
        return true
    }
}
