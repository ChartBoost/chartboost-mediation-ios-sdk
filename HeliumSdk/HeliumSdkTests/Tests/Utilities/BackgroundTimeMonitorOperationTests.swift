// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class BackgroundTimeMonitorOperationTests: ChartboostMediationTestCase {

    let monitor = BackgroundTimeMonitor()

    /// Error margin used for any time interval comparisons for reliability.
    let errorMargin: TimeInterval = 0.1

    func testUneventfulMonitoringMonitoring() {
        let operation = monitor.startMonitoringOperation()
        XCTAssertEqual(0, operation.backgroundTimeUntilNow())

        wait(duration: TimeInterval.random(in: 0.1...1.0))
        XCTAssertEqual(0, operation.backgroundTimeUntilNow())
    }

    func testEventfulMonitoring() throws {
        let operation = try XCTUnwrap(monitor.startMonitoringOperation() as? BackgroundTimeMonitorOperation)
        wait(duration: TimeInterval.random(in: 0.1...1.0))
        XCTAssertEqual(0, operation.backgroundTimeUntilNow())

        operation.applicationDidEnterBackground()
        let date1 = Date()
        wait(duration: TimeInterval.random(in: 0.1...1.0))
        let backgroundTime1 = operation.backgroundTimeUntilNow()
        XCTAssertGreaterThanOrEqual(backgroundTime1, abs(date1.timeIntervalSinceNow) - errorMargin)
        XCTAssertLessThanOrEqual(backgroundTime1, abs(date1.timeIntervalSinceNow) + errorMargin)

        operation.applicationWillEnterForeground()
        wait(duration: TimeInterval.random(in: 0.1...1.0))
        let backgroundTime2 = operation.backgroundTimeUntilNow()
        XCTAssertGreaterThanOrEqual(backgroundTime1, backgroundTime2 - errorMargin)
        XCTAssertLessThanOrEqual(backgroundTime1, backgroundTime2 + errorMargin)

        operation.applicationDidEnterBackground()
        let date3 = Date()
        wait(duration: TimeInterval.random(in: 0.1...1.0))
        operation.applicationWillEnterForeground()
        let backgroundTime3 = operation.backgroundTimeUntilNow()
        XCTAssertGreaterThanOrEqual(backgroundTime3, backgroundTime2 + abs(date3.timeIntervalSinceNow) - errorMargin)
        XCTAssertLessThanOrEqual(backgroundTime3, backgroundTime2 + abs(date3.timeIntervalSinceNow) + errorMargin)

        operation.applicationDidEnterBackground()
        let date4 = Date()
        wait(duration: TimeInterval.random(in: 0.1...1.0))
        let date5 = Date()
        operation.applicationWillEnterForeground()
        wait(duration: TimeInterval.random(in: 0.1...1.0))
        let backgroundTime4 = operation.backgroundTimeUntilNow()
        XCTAssertGreaterThanOrEqual(backgroundTime4, backgroundTime3 + date5.timeIntervalSince(date4) - errorMargin)
        XCTAssertLessThanOrEqual(backgroundTime4, backgroundTime3 + date5.timeIntervalSince(date4) + errorMargin)
    }
}
