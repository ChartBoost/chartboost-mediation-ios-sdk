// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// The result of an ad show operation.
struct AdShowResult {
    /// An error indicating the cause of failure, `nil` if the operation was successful.
    let error: ChartboostMediationError?
    /// Metrics logged for this operation.
    let metrics: RawMetrics?
}
