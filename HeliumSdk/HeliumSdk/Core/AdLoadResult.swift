// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// The result of an ad load operation.
struct AdLoadResult {
    /// The result containing either the ad or an error.
    let result: Result<LoadedAd, ChartboostMediationError>
    /// Metrics logged for this operation.
    let metrics: RawMetrics?
}
