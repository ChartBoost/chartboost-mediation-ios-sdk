// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol TestModeInfoProviding {
    var isTestModeEnabled: Bool { get }
    var isRateLimitingEnabled: Bool { get }
    var rtbAPIHostOverride: String? { get }
    var sdkAPIHostOverride: String? { get }
}

struct TestModeInfo: TestModeInfoProviding {
    var isTestModeEnabled: Bool { TestModeHelper.isTestModeEnabled }
    var isRateLimitingEnabled: Bool { TestModeHelper.isRateLimitingEnabled }
    var rtbAPIHostOverride: String? { TestModeHelper.rtbAPIHostOverride }
    var sdkAPIHostOverride: String? { TestModeHelper.sdkAPIHostOverride }
}

/// Properties of `TestModeHelper` are for testing purposes only. They are expected to be updated
/// with "reflection", and thus they are `private(set)` and read-only within the SDK.
@objc(CHBHTestModeHelper)
@objcMembers
fileprivate final class TestModeHelper: NSObject {

    private enum Constant {
        /// A dictionary key for `setenv()` and `unsetenv` calls to force test mode on and off.
        /// The override priority is lower than `isTestModeEnabled_isForcedOn`.
        static let envTestModeForcedOnKey = "HELIUM_TEST_MODE"

        /// A dictionary value for `setenv()` calls to force test mode on.
        /// The override priority is lower than `isTestModeEnabled_isForcedOn`.
        static let envTestModeForcedOnValue = "ON"
    }

    /// A `Bool` that indicates whether test mode is enabled.
    /// The value of this property is sent as part of the backend bid requests (/auctions).
    fileprivate static var isTestModeEnabled: Bool {
        if isTestModeEnabled_isForcedOn {
            return true
        }

        // Respect the test mode flag in the environment if it's set. Typically set by UI tests.
        return ProcessInfo.processInfo.environment[Constant.envTestModeForcedOnKey]?.uppercased() == Constant.envTestModeForcedOnValue
    }

    /// Override `isTestModeEnabled`. For testing purposes only. Expected to be performed with reflection.
    private(set) static var isTestModeEnabled_isForcedOn = false

    /// Setting that indicates that rate limiting is enabled. In real life, this will always be
    /// `true`, but it's toggleable for testing purposes.
    private(set) static var isRateLimitingEnabled = true

    /// Override the RTB API host.
    /// The provided string has to include the URL scheme to represent a valid URL.
    private(set) static var rtbAPIHostOverride: String?

    /// Override the SDK API host.
    /// The provided string has to include the URL scheme to represent a valid URL.
    private(set) static var sdkAPIHostOverride: String?
}
