// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class BidFulfillOperationConfigurationMock: BidFulfillOperationConfiguration {
    var fullscreenLoadTimeout: TimeInterval = 23
    var bannerLoadTimeout: TimeInterval = 12
}
