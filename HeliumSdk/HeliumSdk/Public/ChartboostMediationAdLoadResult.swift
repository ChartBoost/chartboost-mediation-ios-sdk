// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A result returned by Chartboost Mediation at the end of an ad load operation.
@objc
public class ChartboostMediationAdLoadResult: NSObject {
    /// An error if the ad failed to load, `nil` otherwise.
    @objc public let error: ChartboostMediationError?

    /// A unique identifier for the ad load. It can be ignored in most SDK integrations.
    @objc public let loadID: String

    /// Metrics data about the load operation.
    @objc public let metrics: [String: Any]?

    init(error: ChartboostMediationError?, loadID: String, metrics: [String: Any]?) {
        self.error = error
        self.loadID = loadID
        self.metrics = metrics
    }
}
