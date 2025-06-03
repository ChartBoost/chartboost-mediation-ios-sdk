// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class ApplicationTests: ChartboostMediationTestCase {
    
    let application: Application = UIApplication.shared
    
    func testAddApplicationStateObserver() {
        let observer = ApplicationStateObserverMock()
        application.addObserver(observer)
        
        XCTAssertNoMethodCalls(observer)
        
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        
        XCTAssertMethodCalls(observer, .applicationDidBecomeActive)
        
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        
        XCTAssertMethodCalls(observer, .applicationWillBecomeInactive)
        
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        
        XCTAssertMethodCalls(observer, .applicationDidBecomeActive)
        
        NotificationCenter.default.post(name: UIApplication.willTerminateNotification, object: nil)
        
        XCTAssertMethodCalls(observer, .applicationWillTerminate)

        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        XCTAssertMethodCalls(observer, .applicationWillEnterForeground)

        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        XCTAssertMethodCalls(observer, .applicationDidEnterBackground)
    }

    func testAddApplicationStateObserverTwice() {
        let observer1 = ApplicationStateObserverMock()
        application.addObserver(observer1)
        
        XCTAssertEqual(observer1.recordedMethods.count, 0)
        
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        
        XCTAssertMethodCalls(observer1, .applicationDidBecomeActive)
        
        let observer2 = ApplicationStateObserverMock()
        application.addObserver(observer2)
        
        XCTAssertNoMethodCalls(observer1)
        XCTAssertNoMethodCalls(observer2)
        
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        
        XCTAssertMethodCalls(observer1, .applicationDidBecomeActive)
        XCTAssertMethodCalls(observer2, .applicationDidBecomeActive)
        
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        
        XCTAssertMethodCalls(observer1, .applicationWillBecomeInactive)
        XCTAssertMethodCalls(observer2, .applicationWillBecomeInactive)
    }
    
    func testAddApplicationActivationAndInactivationObserver() {
        let observer = ApplicationActivationInactivationObserverMock()
        application.addObserver(observer)
        
        XCTAssertNoMethodCalls(observer)
        
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        
        XCTAssertMethodCalls(observer, .applicationDidBecomeActive)
        
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        
        XCTAssertMethodCalls(observer, .applicationWillBecomeInactive)
        
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        
        XCTAssertMethodCalls(observer, .applicationDidBecomeActive)
        
        NotificationCenter.default.post(name: UIApplication.willTerminateNotification, object: nil)
        
        XCTAssertNoMethodCalls(observer)
    }
    
    func testAddApplicationTerminationObserver() {
        let observer = ApplicationTerminationObserverMock()
        application.addObserver(observer)
        
        XCTAssertNoMethodCalls(observer)
        
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        XCTAssertNoMethodCalls(observer)
        
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        
        XCTAssertNoMethodCalls(observer)
        
        NotificationCenter.default.post(name: UIApplication.willTerminateNotification, object: nil)
        
        XCTAssertMethodCalls(observer, .applicationWillTerminate)
    }
}
