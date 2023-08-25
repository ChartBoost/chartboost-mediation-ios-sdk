// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class LoadRateLimiterMock: Mock<LoadRateLimiterMock.Method>, LoadRateLimiting {
    
    enum Method {
        case timeUntilNextLoadIsAllowed
        case loadRateLimit
        case setLoadRateLimit
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.timeUntilNextLoadIsAllowed: 0.0,
         .loadRateLimit: 0.0]
    }
    
    func timeUntilNextLoadIsAllowed(placement: String) -> TimeInterval {
        record(.timeUntilNextLoadIsAllowed, parameters: [placement])
    }
    
    func loadRateLimit(placement: String) -> TimeInterval {
        record(.loadRateLimit, parameters: [placement])
    }
    
    func setLoadRateLimit(_ value: TimeInterval, placement: String) {
        record(.setLoadRateLimit, parameters: [value, placement])
    }
}
