// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class BackgroundTimeMonitorOperatorMock: Mock<BackgroundTimeMonitorOperatorMock.Method>, BackgroundTimeMonitorOperator {

    enum Method {
        case backgroundTimeUntilNow
    }

    var backgroundTime: TimeInterval = 0

    func backgroundTimeUntilNow() -> TimeInterval {
        record(.backgroundTimeUntilNow)
        return backgroundTime
    }
}
