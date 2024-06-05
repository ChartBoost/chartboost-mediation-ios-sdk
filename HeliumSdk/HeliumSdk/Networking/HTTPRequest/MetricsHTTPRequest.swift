// Copyright 2018-2024 Chartboost, Inc.
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

struct MetricsHTTPRequest: HTTPRequestWithEncodableBody, HTTPRequestWithRawDataResponse {
    struct Body: Encodable {
        let auctionID: AuctionID?
        let metrics: [MetricsEvent]?
        let result: String?
        let error: Error?
        // Only required in `/v2/event/load`.
        let placementType: AdFormat?
        // Only required if `adFormat` is `adaptiveBanner`.
        let size: BackendEncodableSize?
        // The start time, in milliseconds, for an ad load.
        let start: Int?
        // the end time, in milliseconds, for an ad load.
        let end: Int?
        // The amount of time, in milliseconds, the event encompases if an ad load.
        let duration: Int?
        // The amount of time, in milliseconds, the app is backgrounded during an ad load.
        let backgroundDuration: Int?

        init(
            auctionID: AuctionID? = nil,
            metrics: [MetricsEvent]? = nil,
            result: String? = nil,
            error: Error? = nil,
            adFormat: AdFormat? = nil,
            size: BackendEncodableSize? = nil,
            start: Date? = nil,
            end: Date = Date(),
            backgroundDuration: TimeInterval? = nil
        ) {
            self.auctionID = auctionID
            self.metrics = metrics
            self.result = result
            self.error = error
            self.placementType = adFormat

            // Size can be omitted if the format is not `adaptiveBanner`.
            if adFormat == .adaptiveBanner {
                // If size is nil for some reason, we need to send 0s, or else the server will
                // return a 400 error.
                self.size = size ?? CGSize.zero.backendEncodableSize
            } else {
                self.size = nil
            }

            // Start can be omitted if the event type != .load; End and Duration are only applicable if Start is supplied.
            if let start {
                let start = start.unixTimestamp
                self.start = start
                let end = end.unixTimestamp
                self.end = end
                self.duration = end - start
            } else {
                self.start = nil
                self.end = nil
                self.duration = nil
            }

            // Background duration can be ommitted if the event type is != .load
            if let backgroundDuration {
                self.backgroundDuration = Int(backgroundDuration * 1000)
            } else {
                self.backgroundDuration = nil
            }
        }

        struct Error: Encodable {
            let cmCode: String
            let details: Details

            init?(error: ChartboostMediationError?) {
                guard let error else { return nil }
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
            try makeURL(endpoint: eventType.endpoint)
        }
    }

    private init(eventType: MetricsEvent.EventType, loadID: LoadID?, queueID: String? = nil, body: Body) {
        self.eventType = eventType
        self.body = body
        self.customHeaders = [
            HTTP.HeaderKey.loadID.rawValue: loadID,
            HTTP.HeaderKey.queueID.rawValue: queueID,
        ].compactMapValues { $0 }   // Only include headers for non-nil IDs
    }

    static func initialization(events: [MetricsEvent], result: SDKInitResult, error: ChartboostMediationError?) -> Self {
        Self(
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
        Self(eventType: .prebid, loadID: loadID, body: .init(metrics: events))
    }

    static func load(
        auctionID: String,
        loadID: LoadID,
        events: [MetricsEvent],
        error: ChartboostMediationError?,
        adFormat: AdFormat,
        size: CGSize?,
        start: Date,
        end: Date,
        backgroundDuration: TimeInterval?,
        queueID: String? = nil
    ) -> Self {
        Self(
            eventType: .load,
            loadID: loadID,
            queueID: queueID,
            body: .init(
                auctionID: auctionID,
                metrics: events,
                error: .init(error: error),
                adFormat: adFormat,
                size: size?.backendEncodableSize,
                start: start,
                end: end,
                backgroundDuration: backgroundDuration
            )
        )
    }

    static func show(auctionID: String, loadID: LoadID, event: MetricsEvent) -> Self {
        Self(
            eventType: .show,
            loadID: loadID,
            body: .init(
                auctionID: auctionID,
                metrics: [event]
            )
        )
    }

    static func click(auctionID: String, loadID: LoadID) -> Self {
        Self(eventType: .click, loadID: loadID, body: .init(auctionID: auctionID))
    }

    static func expiration(auctionID: String, loadID: LoadID) -> Self {
        Self(eventType: .expiration, loadID: loadID, body: .init(auctionID: auctionID))
    }

    static func mediationImpression(auctionID: String, loadID: LoadID) -> Self {
        Self(eventType: .mediationImpression, loadID: loadID, body: .init(auctionID: auctionID))
    }

    static func partnerImpression(auctionID: String, loadID: LoadID) -> Self {
        Self(eventType: .partnerImpression, loadID: loadID, body: .init(auctionID: auctionID))
    }

    static func reward(auctionID: String, loadID: LoadID) -> Self {
        Self(eventType: .reward, loadID: loadID, body: .init(auctionID: auctionID))
    }
}

extension MetricsEvent.EventType {
    fileprivate var endpoint: BackendAPI.Endpoint {
        switch self {
        case .bannerSize: return .bannerSize
        case .click: return .click
        case .expiration: return .expiration
        case .initialization: return .initialization
        case .load: return .load
        case .mediationImpression: return .mediationImpression
        case .partnerImpression: return .partnerImpression
        case .prebid: return .prebid
        case .reward: return .reward
        case .show: return .show
        case .winner: return .winner
        case .startQueue: return .startQueue
        case .endQueue: return .endQueue
        }
    }
}

extension AdFormat: Encodable {}
