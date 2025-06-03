// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Application-specific configuration flags for the Chartboost Mediation SDK.
protocol ApplicationConfiguration {
    /// Updates the configuration with a JSON-encoded `RawValues` data, and persists the data so it is available
    /// right away on the next session.
    func update(with data: Data) throws
}
