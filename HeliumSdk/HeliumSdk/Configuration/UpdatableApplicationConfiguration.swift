// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A configuration class whose values can be updated and default to hardcoded values when necessary.
/// Since this is a reference type, one instance of this class can be shared with other components and they will always
/// get the most up-to-date configuration whenever it is updated without having to update their reference to it.
final class UpdatableApplicationConfiguration: ApplicationConfiguration {
    /// Raw configuration values as obtained from the backend.
    /// Note that property names must match the schema keys, except that we use camel case names instead of snake case.
    struct RawValues: Decodable {
        struct Placement: Codable {
            let chartboostPlacement: String
            // a String instead of a Codable enum so we can recover from parsing errors without discarding the whole response
            let format: String
            let autoRefreshRate: TimeInterval?
        }

        let fullscreenLoadTimeout: TimeInterval?
        let bannerLoadTimeout: UInt?
        let showTimeout: UInt?
        let country: String?
        let internalTestId: String?
        let prebidFetchTimeout: UInt?
        let bannerImpressionMinVisibleDips: UInt?   // it's in "dips" but it's OK to just use it as "points"
        let bannerImpressionMinVisibleDurationMs: UInt?
        let bannerSizeEventDelayMs: UInt?
        let visibilityTrackerPollIntervalMs: UInt?
        let visibilityTrackerTraversalLimit: UInt?
        let adapterClasses: [String]?
        let credentials: JSON<[String: [String: Any]]>
        let metricsEvents: [String]?
        let initTimeout: UInt?
        let initMetricsPostTimeout: UInt?
        let placements: [Placement]
        let logLevel: LogLevel?
        // use `String` instead of `PrivacyBanListCandidate` to avoid discarding the whole response when Codable parsing errors happen
        // (unrecognized / misspelled value)
        let privacyBanList: [String]?
    }

    /// Default configuration values to use when a backend value is not available.
    private enum DefaultValues {
        static let fullscreenLoadTimeout: TimeInterval = 30
        static let bannerLoadTimeout: UInt = 15
        static let showTimeout: UInt = 5
        static let prebidFetchTimeout: UInt = 5
        static let bannerImpressionMinVisibleDips: UInt = 1
        static let bannerImpressionMinVisibleDurationMs: UInt = 0
        static let bannerSizeEventDelayMs: UInt = 1000
        static let visibilityTrackerPollIntervalMs: UInt = 100
        static let visibilityTrackerTraversalLimit: UInt = 25
        static let initTimeout: UInt = 1
        static let initMetricsPostTimeout: UInt = 10
        static let bannerAutoRefreshRate: TimeInterval = 30
        static let bannerPenaltyLoadRetryRate: TimeInterval = 240
        static let bannerPenaltyLoadRetryCount: UInt = 4
    }

    static let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase

    /// The current configuration values, obtained either from the backend or from persisted data.
    /// If `nil` the configuration will use default values only.
    private var values: RawValues?

    /// Updates the configuration with a JSON-encoded `RawValues` data.
    func update(with data: Data) throws {
        // Decode the values JSON expecting snake-cased keys to match our camel-cased property names.
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = Self.keyDecodingStrategy
        values = try decoder.decode(RawValues.self, from: data)
    }
}

// MARK: - Protocol Conformances
// Conformances of UpdatableApplicationConfiguration to all configuration protocols defined by SDK components.
// Here we use the raw backend values and/or default values, we massage them a bit to get the types and names
// we want, and use them to fulfill component-specific configuration requirements.

extension UpdatableApplicationConfiguration: PartnerControllerConfiguration {
    var prebidFetchTimeout: TimeInterval {
        TimeInterval(values?.prebidFetchTimeout ?? DefaultValues.prebidFetchTimeout)
    }

    var initMetricsPostTimeout: TimeInterval {
        TimeInterval(values?.initMetricsPostTimeout ?? DefaultValues.initMetricsPostTimeout)
    }
}

extension UpdatableApplicationConfiguration: BidFulfillOperationConfiguration {
    var fullscreenLoadTimeout: TimeInterval {
        values?.fullscreenLoadTimeout ?? DefaultValues.fullscreenLoadTimeout
    }

    var bannerLoadTimeout: TimeInterval {
        TimeInterval(values?.bannerLoadTimeout ?? DefaultValues.bannerLoadTimeout)
    }
}

extension UpdatableApplicationConfiguration: SDKInitializerConfiguration {
    var initTimeout: TimeInterval {
        TimeInterval(values?.initTimeout ?? DefaultValues.initTimeout)
    }

    var partnerAdapterClassNames: Set<String> {
        Set(values?.adapterClasses ?? [])
    }

    var partnerCredentials: [PartnerIdentifier: [String: Any]] {
        (values?.credentials.value ?? [:])
        // TODO: Remove this reference adapter hack in HB-4504
            .merging(["reference": [:]], uniquingKeysWith: { first, _ in first })
    }
}

extension UpdatableApplicationConfiguration: VisibilityTrackerConfiguration {
    var minimumVisiblePoints: CGFloat {
        CGFloat(values?.bannerImpressionMinVisibleDips ?? DefaultValues.bannerImpressionMinVisibleDips)
    }

    var pollInterval: TimeInterval {
        TimeInterval(values?.visibilityTrackerPollIntervalMs ?? DefaultValues.visibilityTrackerPollIntervalMs) / 1000
    }

    var minimumVisibleSeconds: TimeInterval {
        TimeInterval(values?.bannerImpressionMinVisibleDurationMs ?? DefaultValues.bannerImpressionMinVisibleDurationMs) / 1000
    }

    var traversalLimit: UInt {
        values?.visibilityTrackerTraversalLimit ?? DefaultValues.visibilityTrackerTraversalLimit
    }
}

extension UpdatableApplicationConfiguration: AdControllerConfiguration {
    var showTimeout: TimeInterval {
        TimeInterval(values?.showTimeout ?? DefaultValues.showTimeout)
    }
}

extension UpdatableApplicationConfiguration: MetricsEventLoggerConfiguration {
    var filter: [MetricsEvent.EventType] {
        values?.metricsEvents?.compactMap { MetricsEvent.EventType(rawValue: $0) } ?? MetricsEvent.EventType.allCases
    }

    var country: String? {
        values?.country
    }

    var testIdentifier: String? {
        values?.internalTestId
    }
}

extension UpdatableApplicationConfiguration: FullscreenAdLoaderConfiguration {
    func adFormat(forPlacement placement: String) -> AdFormat? {
        // Fail early if there is no placement info in the configuration
        guard let placement = values?.placements.first(where: { $0.chartboostPlacement == placement }) else {
            return nil
        }
        // Manually decode the ad format.
        // We don't use a Decodable type for Placement.format so the config response can be decoded even if backend starts
        // sending a new format value (intentionally or by mistake).
        if let format = AdFormat(rawValue: placement.format) {
            return format
        } else {
            logger.warning("Found unknown ad format '\(placement.format)'")
            return nil
        }
    }
}

extension UpdatableApplicationConfiguration: BannerControllerConfiguration {
    func autoRefreshRate(forPlacement placement: String) -> TimeInterval {
        // Fail early if there is no placement info in the configuration
        guard let placement = values?.placements.first(where: { $0.chartboostPlacement == placement }) else {
            return 0
        }
        // Use default value if none is provided
        guard let autoRefreshRate = placement.autoRefreshRate else {
            return DefaultValues.bannerAutoRefreshRate
        }
        // Sanitize value
        if autoRefreshRate < 10 {
            return 0    // Disable autorefresh if rate is too low
        } else if autoRefreshRate > 240 {
            return 240  // Limit rate to a maximum
        } else {
            return autoRefreshRate  // Use the value as it is
        }
    }

    func normalLoadRetryRate(forPlacement placement: String) -> TimeInterval {
        let rate = autoRefreshRate(forPlacement: placement)
        // In practice we never use the default value, because we don't retry banner loads if autorefresh is disabled.
        // This is just a safeguard.
        return rate < 10 ? DefaultValues.bannerAutoRefreshRate : rate
    }

    var penaltyLoadRetryRate: TimeInterval {
        DefaultValues.bannerPenaltyLoadRetryRate
    }

    var penaltyLoadRetryCount: UInt {
        DefaultValues.bannerPenaltyLoadRetryCount
    }

    var bannerSizeEventDelay: TimeInterval {
        TimeInterval(values?.bannerSizeEventDelayMs ?? DefaultValues.bannerSizeEventDelayMs) / 1000
    }
}

extension UpdatableApplicationConfiguration: ConsoleLoggerConfiguration {
    var logLevel: LogLevel? {
        values?.logLevel
    }
}

extension UpdatableApplicationConfiguration: PrivacyConfiguration {
    var privacyBanList: [PrivacyBanListCandidate] {
        (values?.privacyBanList ?? []).compactMap { .init(rawValue: $0) }
    }
}
