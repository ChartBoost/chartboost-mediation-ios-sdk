// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class DispatchTaskMock: Mock<DispatchTaskMock.Method>, DispatchTask {
    
    enum Method {
        case cancel
        case pause
        case resume
    }
        
    var state: DispatchTaskState = .active
    var remainingTime: TimeInterval = 0
    
    func cancel() {
        record(.cancel)
    }
    
    func pause() {
        record(.pause)
    }
    
    func resume() {
        record(.resume)
    }
}
