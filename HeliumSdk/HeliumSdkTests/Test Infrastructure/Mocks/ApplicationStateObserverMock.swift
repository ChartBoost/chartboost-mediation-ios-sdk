// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class ApplicationStateObserverMock: Mock<ApplicationStateObserverMock.Method>, ApplicationActivationObserver, ApplicationInactivationObserver, ApplicationTerminationObserver {
    
    enum Method {
        case applicationDidBecomeActive
        case applicationWillBecomeInactive
        case applicationWillTerminate
    }
        
    func applicationDidBecomeActive() {
        record(.applicationDidBecomeActive)
    }
    
    func applicationWillBecomeInactive() {
        record(.applicationWillBecomeInactive)
    }
    
    func applicationWillTerminate() {
        record(.applicationWillTerminate)
    }
}

class ApplicationActivationInactivationObserverMock: Mock<ApplicationActivationInactivationObserverMock.Method>, ApplicationActivationObserver, ApplicationInactivationObserver {
    
    enum Method {
        case applicationDidBecomeActive
        case applicationWillBecomeInactive
    }
        
    func applicationDidBecomeActive() {
        record(.applicationDidBecomeActive)
    }
    
    func applicationWillBecomeInactive() {
        record(.applicationWillBecomeInactive)
    }
}

class ApplicationTerminationObserverMock: Mock<ApplicationTerminationObserverMock.Method>, ApplicationTerminationObserver {
    
    enum Method {
        case applicationWillTerminate
    }
        
    func applicationWillTerminate() {
        record(.applicationWillTerminate)
    }
}
