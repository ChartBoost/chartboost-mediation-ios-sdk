// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol TestModeInfoProviding: AnyObject {
    /// A `Bool` that indicates whether test mode is enabled.
    /// Users can set this to `true` via the public `isTestModeEnabled` API.
    /// or via runtime environment which is useful for UI tests.
    /// The value of this property is sent as part of the backend bid requests (/auctions).
    var isTestModeEnabled: Bool { get set }

    /// A `Bool` that indicates whether rate limiting is enabled.
    /// In real life, this will always be `true`, but it's toggleable for testing purposes.
    var isRateLimitingEnabled: Bool { get }

    /// Override the SDK API host.
    /// The provided string should not include the URL scheme.
    /// Example: "subdomain.chartboost.com", "localhost"
    var sdkAPIHostOverride: String? { get }

    /// Override the setting for how long ads can be stored in the queue before expiring.
    var fullscreenAdQueueTTL: TimeInterval? { get }

    /// Override the setting for the maximum allowed queue size.
    var fullscreenAdQueueMaxSize: Int? { get }

    /// Override the setting for all placement's queue sizes.
    /// This is not quite the same as the "default queue size" setting that it overrides
    var fullscreenAdQueueRequestedSize: Int? { get }
}

final class TestModeInfo: TestModeInfoProviding {
    /// Keys for the `setenv()` and `unsetenv` calls.
    /// - Warning: Inform other teams when updating this, otherwise Unity Canary and automation test cases might break.
    private enum EnvKey {
        /// Provide "OFF" to override the default "ON" state for rate limiting.
        /// - Note: If other values are provided, fall back to the default enabled state.
        static let rateLimitingOverride = "CB_MEDIATION_RATE_LIMITING_OVERRIDE"

        /// Provide any string that represents a URL host such as `"mediation-sdk.chartboost.com"`.
        /// If `nil`, fall back to the original URL host.
        static let sdkAPIHostOverride = "CB_MEDIATION_SDK_API_HOST_OVERRIDE"

        /// Provide a string representation of a TimeInterval
        static let fullscreenAdQueueAdTTL = "CB_MEDIATION_QUEUE_AD_TTL"

        /// Provide a string representation of an Int
        static let fullscreenAdQueueMaxSize = "CB_MEDIATION_QUEUE_MAX_SIZE"

        /// Provide a string representation of an Int
        static let fullscreenAdQueueRequestedSize = "CB_MEDIATION_REQUESTED_SIZE"
    }

    /// Values for the `setenv()` and `unsetenv` calls.
    /// - Warning: Inform other teams when updating this, otherwise Unity Canary and automation test cases might break.
    private enum EnvValue {
        static let on = "ON"
        static let off = "OFF"
    }

    var isTestModeEnabled = false

    var isRateLimitingEnabled: Bool {
        ProcessInfo.processInfo.environment[EnvKey.rateLimitingOverride]?.uppercased() != EnvValue.off
    }

    var sdkAPIHostOverride: String? {
        ProcessInfo.processInfo.environment[EnvKey.sdkAPIHostOverride]
    }

    // MARK: FullscreenAdQueue test settings

    var fullscreenAdQueueTTL: TimeInterval? {
        // Use flatMap to only attempt a cast to TimeInterval if EnvKey.fullscreenAdQueueTTL exists.
        ProcessInfo.processInfo.environment[EnvKey.fullscreenAdQueueAdTTL].flatMap { TimeInterval($0) }
    }

    var fullscreenAdQueueMaxSize: Int? {
        // Use flatMap to only attempt a cast to Int if EnvKey.fullscreenAdQueueMaxSize exists.
        ProcessInfo.processInfo.environment[EnvKey.fullscreenAdQueueMaxSize].flatMap { Int($0) }
    }

    var fullscreenAdQueueRequestedSize: Int? {
        // Use flatMap to only attempt a cast to Int if EnvKey.fullscreenAdQueueRequestedSize exists.
        ProcessInfo.processInfo.environment[EnvKey.fullscreenAdQueueRequestedSize].flatMap { Int($0) }
    }
}
