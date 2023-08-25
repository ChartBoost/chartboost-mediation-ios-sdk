// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension ResumableTimer {
    /// Indicates if the timer is active. This will return `false` when the timer is paused.
    public var isCountdownActive: Bool {
        guard case .active = state else { return false }
        return true
    }
}
