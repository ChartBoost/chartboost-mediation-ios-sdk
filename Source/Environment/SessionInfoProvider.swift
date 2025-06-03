// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK
import Foundation

protocol SessionInfoProviding {
    var elapsedSessionDuration: TimeInterval { get }
    var sessionID: String { get }
}

struct SessionInfoProvider: SessionInfoProviding {
    var sessionID: String {
        ChartboostCore.analyticsEnvironment.appSessionID ?? ""
    }

    var elapsedSessionDuration: TimeInterval {
        ChartboostCore.analyticsEnvironment.appSessionDuration
    }
}
