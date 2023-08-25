// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class VisibilityTrackerMock: Mock<VisibilityTrackerMock.Method>, VisibilityTracker {
    
    enum Method {
        case startTracking
        case stopTracking
    }
    
    var lastCompletion: (() -> Void)?

    var isTracking = false
    
    func startTracking(_ view: UIView, completion: @escaping () -> Void) {
        record(.startTracking, parameters: [view, completion])
        lastCompletion = completion
    }
    
    func stopTracking() {
        record(.stopTracking, parameters: [])
    }
}
