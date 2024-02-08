// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class PartnerControllerConfigurationMock: PartnerControllerConfiguration {
    var prebidFetchTimeout: TimeInterval = 4.2
    var initMetricsPostTimeout: TimeInterval = 5
}
