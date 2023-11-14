// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class GCDTaskDispatcherTests: ChartboostMediationTestCase {

    let dispatcher = GCDTaskDispatcher(backgroundQueue: .init(label: "test_serial_queue"))
    
    // MARK: - Sync
    
    func testSyncOnMainQueue() {
        let expectation = self.expectation(description: "")
        DispatchQueue.global().async { [self] in
            var executed = false
            dispatcher.sync(on: .main) {
                XCTAssertTrue(Thread.isMainThread)
                executed = true
            }
            XCTAssertTrue(executed)    // will fail if previous block was not executed synchronously
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testSyncOnBackgroundQueue() {
        var executed = false
        dispatcher.sync(on: .background) {
            XCTAssertTrue(Thread.isMainThread)
            executed = true
        }
        XCTAssertTrue(executed)    // will fail if previous block was not executed synchronously
    }
    
    // MARK: - Async
    
    func testAsyncOnMainQueueFromMainQueue() {
        let expectation = self.expectation(description: "")
        var executed = false
        dispatcher.async(on: .main) {
            XCTAssertTrue(Thread.isMainThread)
            executed = true
            expectation.fulfill()
        }
        XCTAssertFalse(executed)   // will fail if previous block was not executed asynchronously
        waitForExpectations(timeout: 10)
    }
    
    func testAsyncOnMainQueueFromBackgroundQueue() {
        let expectation = self.expectation(description: "")
        var executed = false
        DispatchQueue.global().async { [self] in
            dispatcher.async(on: .main) {
                executed = true
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
            XCTAssertFalse(executed)   // will fail if previous block was not executed asynchronously
        }
        waitForExpectations(timeout: 10)
    }
    
    func testAsyncOnBackgroundQueueFromMainQueue() {
        let expectation = self.expectation(description: "")
        dispatcher.async(on: .background) {
            XCTAssertFalse(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testAsyncOnBackgroundQueueFromBackgroundQueue() {
        let expectation = self.expectation(description: "")
        DispatchQueue.global().async { [self] in
            dispatcher.async(on: .background) {
                XCTAssertFalse(Thread.isMainThread)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
    
    // MARK: - Delay
    
    func testAsyncAfterDelay() {
        let expectation = self.expectation(description: "")
        let startDate = Date()
        dispatcher.async(on: .main, after: 1) {
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertGreaterThanOrEqual(abs(startDate.timeIntervalSinceNow), 0.9)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testAsyncWithDelayOnMainQueue() {
        let expectation = self.expectation(description: "")
        let startDate = Date()
        let task = dispatcher.async(on: .main, delay: 1) {
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertGreaterThanOrEqual(abs(startDate.timeIntervalSinceNow), 0.9)
            expectation.fulfill()
        }
        XCTAssertEqual(task.state, .active)
        XCTAssertLessThanOrEqual(task.remainingTime, 1)
        waitForExpectations(timeout: 10)
        XCTAssertEqual(task.state, .complete)
        XCTAssertLessThanOrEqual(task.remainingTime, 0)
    }
    
    func testAsyncWithDelayOnBackgroundQueue() {
        let expectation = self.expectation(description: "")
        let startDate = Date()
        let task = dispatcher.async(on: .background, delay: 1) {
            XCTAssertFalse(Thread.isMainThread)
            XCTAssertGreaterThanOrEqual(abs(startDate.timeIntervalSinceNow), 0.9)
            expectation.fulfill()
        }
        XCTAssertEqual(task.state, .active)
        XCTAssertLessThanOrEqual(task.remainingTime, 1)
        waitForExpectations(timeout: 10)
        XCTAssertEqual(task.state, .complete)
        XCTAssertLessThanOrEqual(task.remainingTime, 0)
    }
    
    // MARK: - Repeat
    
    func testAsyncWithRepeatOnMainQueue() {
        let expectation = self.expectation(description: "")
        var count = 0
        let startDate = Date()
        let task = dispatcher.async(on: .main, delay: 0.5, repeat: true) {
            count += 1
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertGreaterThanOrEqual(abs(startDate.timeIntervalSinceNow), 0.4 * Double(count))
            if count == 3 {
                expectation.fulfill()
            }
        }
        XCTAssertEqual(task.state, .active)
        XCTAssertLessThanOrEqual(task.remainingTime, 0.5)
        waitForExpectations(timeout: 10)
        XCTAssertEqual(task.state, .active) // still going
    }
    
    func testAsyncWithRepeatOnBackgroundQueue() {
        let expectation = self.expectation(description: "")
        var count = 0
        let startDate = Date()
        let task = dispatcher.async(on: .background, delay: 0.5, repeat: true) {
            count += 1
            XCTAssertFalse(Thread.isMainThread)
            XCTAssertGreaterThanOrEqual(abs(startDate.timeIntervalSinceNow), 0.4 * Double(count))
            if count == 3 {
                expectation.fulfill()
            }
        }
        XCTAssertEqual(task.state, .active)
        XCTAssertLessThanOrEqual(task.remainingTime, 0.5)
        waitForExpectations(timeout: 10)
        XCTAssertEqual(task.state, .active) // still going
    }
}
