// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class BannerControllerConfigurationMock: Mock<BannerControllerConfigurationMock.Method>, BannerControllerConfiguration {
    
    enum Method {
        case autoRefreshRate
        case normalLoadRetryRate
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.autoRefreshRate: 35.0,
         .normalLoadRetryRate: 23.0]
    }
    
    func autoRefreshRate(forPlacement placement: String) -> TimeInterval {
        record(.autoRefreshRate, parameters: [placement])
    }
    
    func normalLoadRetryRate(forPlacement placement: String) -> TimeInterval {
        record(.normalLoadRetryRate, parameters: [placement])
    }
    
    var penaltyLoadRetryRate: TimeInterval = 14.5
    
    var penaltyLoadRetryCount: UInt = 3

    var bannerSizeEventDelay: TimeInterval = 1
}
