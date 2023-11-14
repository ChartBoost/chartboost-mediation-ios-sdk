// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A result returned by Chartboost Mediation at the end of an ad show operation.
@objc
public class ChartboostMediationAdShowResult: NSObject {
    
    /// An error if the ad failed to show, `nil` otherwise.
    @objc public let error: ChartboostMediationError?
    
    /// Metrics data about the show operation.
    @objc public let metrics: [String: Any]?
    
    init(error: ChartboostMediationError?, metrics: [String : Any]?) {
        self.error = error
        self.metrics = metrics
    }
}
