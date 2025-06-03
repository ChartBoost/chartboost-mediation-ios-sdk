// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A result returned by Chartboost Mediation at the end of an ad load operation.
@objc(CBMAdLoadResult)
public class AdLoadResult: NSObject {
    /// An error if the ad failed to load, `nil` otherwise.
    @objc public let error: ChartboostMediationError?

    /// A unique identifier for the ad load. It can be ignored in most SDK integrations.
    @objc public let loadID: String

    /// Metrics data about the load operation.
    @objc public let metrics: [String: Any]?

    /// Information about the winning bid.
    @objc public var winningBidInfo: [String: Any]?

    init(error: ChartboostMediationError?, loadID: String, metrics: [String: Any]?, winningBidInfo: [String: Any]?) {
        self.error = error
        self.loadID = loadID
        self.metrics = metrics
        self.winningBidInfo = winningBidInfo
    }
}
