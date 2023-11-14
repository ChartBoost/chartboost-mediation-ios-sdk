// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

struct VisibilityTrackerConfigurationMock: VisibilityTrackerConfiguration {
    var minimumVisibleSeconds: TimeInterval = 2.405
    var minimumVisiblePoints: CGFloat = 5
    var pollInterval: TimeInterval = 0.1
    var traversalLimit: UInt = 25
}
