// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Application-specific configuration flags for the Helium SDK.
protocol ApplicationConfiguration {
    /// Updates the configuration with a JSON-encoded `RawValues` data, and persists the data so it is available
    /// right away on the next session.
    func update(with data: Data) throws
}

/// An aggregation of all the configuration protocols defined by SDK components.
typealias AllConfigurations =
    ApplicationConfiguration
    & VisibilityTrackerConfiguration
    & SDKInitializerConfiguration
    & BidFulfillOperationConfiguration
    & AdControllerConfiguration
    & PartnerControllerConfiguration
    & MetricsEventLoggerConfiguration
    & ConsoleLoggerConfiguration
    & PrivacyConfiguration
