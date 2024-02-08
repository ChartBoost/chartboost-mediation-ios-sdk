// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class BackgroundTimeMonitorOperationTests: ChartboostMediationTestCase {

    let monitor = BackgroundTimeMonitor()

    override func setUp() {
        super.setUp()
        dependenciesContainer.application = UIApplication.shared
    }

    func testUneventfulMonitoringMonitoring() {
        let operation = monitor.startMonitoringOperation()
        XCTAssertEqual(0, operation.backgroundTimeUntilNow())

        wait(duration: TimeInterval.random(in: 0.1...1.0))
        XCTAssertEqual(0, operation.backgroundTimeUntilNow())
    }

    func testEventfulMonitoring() {
        let operation = monitor.startMonitoringOperation()
        wait(duration: TimeInterval.random(in: 0.1...1.0))

        XCTAssertEqual(0, operation.backgroundTimeUntilNow())

        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        wait(duration: TimeInterval.random(in: 0.1...1.0))
        let backgroundTime1 = operation.backgroundTimeUntilNow()
        XCTAssertTrue(backgroundTime1 >= 0.1)
        XCTAssertTrue(backgroundTime1 <= 1.0)

        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        wait(duration: TimeInterval.random(in: 0.1...1.0))
        let backgroundTime2 = operation.backgroundTimeUntilNow()
        XCTAssertTrue(backgroundTime2 >= 0.1)
        XCTAssertTrue(backgroundTime2 <= 1.0)

        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        wait(duration: TimeInterval.random(in: 0.1...1.0))
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        let backgroundTime3 = operation.backgroundTimeUntilNow()
        XCTAssertTrue(backgroundTime3 >= 0.2)
        XCTAssertTrue(backgroundTime3 <= 2.0)

        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        wait(duration: TimeInterval.random(in: 0.1...1.0))
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        wait(duration: TimeInterval.random(in: 0.1...1.0))
        let backgroundTime4 = operation.backgroundTimeUntilNow()
        XCTAssertTrue(backgroundTime4 >= 0.3)
        XCTAssertTrue(backgroundTime4 <= 3.0)
    }
}
