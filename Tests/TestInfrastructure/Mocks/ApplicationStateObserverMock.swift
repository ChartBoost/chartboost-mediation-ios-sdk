// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

// This mock cannot be auto-generated because it mocks multiple protocols at once.
class ApplicationStateObserverMock: Mock<ApplicationStateObserverMock.Method>, ApplicationActivationObserver, ApplicationInactivationObserver, ApplicationTerminationObserver, ApplicationForegroundObserver, ApplicationBackgroundObserver {
    
    enum Method {
        case applicationWillEnterForeground
        case applicationDidEnterBackground
        case applicationDidBecomeActive
        case applicationWillBecomeInactive
        case applicationWillTerminate
    }
        
    func applicationWillEnterForeground() {
        record(.applicationWillEnterForeground)
    }

    func applicationDidEnterBackground() {
        record(.applicationDidEnterBackground)
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

// This mock cannot be auto-generated because it mocks multiple protocols at once.
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

// This mock could be auto-generated, but we leave it here since the ones before aren't.
class ApplicationTerminationObserverMock: Mock<ApplicationTerminationObserverMock.Method>, ApplicationTerminationObserver {
    
    enum Method {
        case applicationWillTerminate
    }
        
    func applicationWillTerminate() {
        record(.applicationWillTerminate)
    }
}
