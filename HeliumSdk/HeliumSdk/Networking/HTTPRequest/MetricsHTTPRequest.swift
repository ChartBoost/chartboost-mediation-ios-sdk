// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

enum SDKInitResult: String, CaseIterable {

    /// Invalid SDK init hash or app config.
    /// This usually means SDK init was never successful (SDK init hash are app config weren't cached).
    case failure

    /// `/v1/sdk_init` response has valid SDK init hash and code 204 (No Content with empty body).
    /// This typically represents the SDK init success after the first one.
    case successWithCachedConfig = "success_with_cached_config"

    /// `/v1/sdk_init` response is invalid, but a valid SDK init hash and app config data are available in cache.
    /// This means SDK init was successful in a previous launch, but the response for current launch has some issue.
    case successWithCachedConfigAndError = "success_with_cached_config_and_error"

    /// `/v1/sdk_init` response has valid SDK init hash, code 200 (OK), and valid app config JSON body.
    /// This typically represents the first success of SDK init.
    case successWithFetchedConfig = "success_with_fetched_config"
}

/// Spec: go/cm-tracking-events
struct MetricsHTTPRequest: HTTPRequestWithEncodableBody, HTTPRequestWithRawDataResponse {

    struct Body: Encodable {
        let auctionID: AuctionID?
        let metrics: [MetricsEvent]?
        let result: String?
        let error: Error?

        init(
            auctionID: AuctionID? = nil,
            metrics: [MetricsEvent]? = nil,
            result: String? = nil,
            error: Error? = nil
        ) {
            self.auctionID = auctionID
            self.metrics = metrics
            self.result = result
            self.error = error
        }

        struct Error: Encodable {
            let cmCode: String
            let details: Details

            init?(error: ChartboostMediationError?) {
                guard let error = error else { return nil }
                cmCode = error.chartboostMediationCode.string
                details = Details(error: error)
            }

            struct Details: Encodable {
                /// Set a max size because backend can handle about 4MB at most. Base 64 strings have
                /// the same number of characters as the number of bytes.
                /// Note: The length of a base 64 string is always a multiple of 4.
                static let maxBase64StringLength: Int = {
                    let length = Int(3.5 * 1024 * 1024)
                    return length - length % 4 // extra math to make sure the return value is a multiple of 4
                }()

                let type: String?
                let description: String?
                let dataAsString: String?

                init(error: ChartboostMediationError) {
                    type = error.chartboostMediationCode.name
                    description = (error.underlyingError as? NSError)?.description
                    dataAsString = error.data?.base64EncodedString().prefixString(Self.maxBase64StringLength)
                }
            }
        }
    }

    let eventType: MetricsEvent.EventType
    let method = HTTP.Method.post
    let customHeaders: HTTP.Headers
    let body: Body
    let requestKeyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .convertToSnakeCase
    var isSDKInitializationRequired: Bool { eventType != .initialization }

    var url: URL {
        get throws {
            try makeURL(backendAPI: .sdk, path: eventType.urlPath)
        }
    }

    private init(eventType: MetricsEvent.EventType, loadID: LoadID?, body: Body) {
        self.eventType = eventType
        self.body = body
        self.customHeaders = loadID.map { [HTTP.HeaderKey.loadID.rawValue: $0] } ?? [:]
    }

    static func initialization(events: [MetricsEvent], result: SDKInitResult, error: ChartboostMediationError?) -> Self {
        Self.init(
            eventType: .initialization,
            loadID: nil,
            body: .init(
                metrics: events,
                result: result.rawValue,
                error: .init(error: error)
            )
        )
    }

    static func prebid(loadID: LoadID, events: [MetricsEvent]) -> Self {
        Self.init(eventType: .prebid, loadID: loadID, body: .init(metrics: events))
    }
    
    static func load(auctionID: String, loadID: LoadID, events: [MetricsEvent], error: ChartboostMediationError?) -> Self {
        Self.init(
            eventType: .load,
            loadID: loadID,
            body: .init(
                auctionID: auctionID,
                metrics: events,
                error: .init(error: error)
            )
        )
    }

    static func show(auctionID: String, loadID: LoadID, event: MetricsEvent) -> Self {
        Self.init(
            eventType: .show,
            loadID: loadID,
            body: .init(
                auctionID: auctionID,
                metrics: [event]
            )
        )
    }

    static func click(auctionID: String, loadID: LoadID) -> Self {
        Self.init(eventType: .click, loadID: loadID, body: .init(auctionID: auctionID))
    }

    static func expiration(auctionID: String, loadID: LoadID) -> Self {
        Self.init(eventType: .expiration, loadID: loadID, body: .init(auctionID: auctionID))
    }

    static func heliumImpression(auctionID: String, loadID: LoadID) -> Self {
        Self.init(eventType: .heliumImpression, loadID: loadID, body: .init(auctionID: auctionID))
    }

    static func partnerImpression(auctionID: String, loadID: LoadID) -> Self {
        Self.init(eventType: .partnerImpression, loadID: loadID, body: .init(auctionID: auctionID))
    }

    static func reward(auctionID: String, loadID: LoadID) -> Self {
        Self.init(eventType: .reward, loadID: loadID, body: .init(auctionID: auctionID))
    }
}

private extension MetricsEvent.EventType {
    var urlPath: String {
        let eventPath = BackendAPI.Path.SDK.Event.self

        switch self {
        case .click: return eventPath.click
        case .expiration: return eventPath.expiration
        case .initialization: return eventPath.initialization
        case .load: return eventPath.load
        case .prebid: return eventPath.prebid
        case .show: return eventPath.show
        case .heliumImpression: return eventPath.heliumImpression
        case .partnerImpression: return eventPath.partnerImpression
        case .reward: return eventPath.reward
        case .winner: return eventPath.winner
        }
    }
}
