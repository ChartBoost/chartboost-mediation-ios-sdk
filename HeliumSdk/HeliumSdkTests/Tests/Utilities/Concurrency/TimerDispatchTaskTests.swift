// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class TimerDispatchTaskTests: ChartboostMediationTestCase {

    let dispatcher = GCDTaskDispatcher(backgroundQueue: .init(label: "test_serial_queue"))
    
    // MARK: - Cancel
    
    func testCancelTaskOnMainQueue() {
        let expectation = self.expectation(description: "")
        let task = dispatcher.async(on: .main, delay: 0.1) {
            XCTFail("Should not be executed")
        }
        task.cancel()
        
        XCTAssertEqual(task.state, .complete)
        XCTAssertLessThanOrEqual(task.remainingTime, 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()   // we delay the end of the test to assure that the task is not executed
        }
        waitForExpectations(timeout: 10)
    }
    
    func testCancelTaskOnBackgroundQueue() {
        let expectation = self.expectation(description: "")
        let task = dispatcher.async(on: .main, delay: 0.1) {
            XCTFail("Should not be executed")
        }
        DispatchQueue.global().async {
            task.cancel()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()   // we delay the end of the test to assure that the task is not executed
        }
        waitForExpectations(timeout: 10)
        XCTAssertEqual(task.state, .complete)
        XCTAssertLessThanOrEqual(task.remainingTime, 0)
    }
    
    func testCancelTaskTwice() {
        let expectation = self.expectation(description: "")
        let task = dispatcher.async(on: .main, delay: 0.1) {
            XCTFail("Should not be executed")
        }
        task.cancel()
        task.cancel()
        
        XCTAssertEqual(task.state, .complete)
        XCTAssertLessThanOrEqual(task.remainingTime, 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()   // we delay the end of the test to assure that the task is not executed
        }
        waitForExpectations(timeout: 10)
    }
    
    func testCancelRepeatingTask() {
        let expectation = self.expectation(description: "")
        let task = dispatcher.async(on: .main, delay: 0.1, repeat: true) {
            XCTFail("Should not be executed")
        }
        task.cancel()
        
        XCTAssertEqual(task.state, .complete)
        XCTAssertLessThanOrEqual(task.remainingTime, 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()   // we delay the end of the test to assure that the task is not executed
        }
        waitForExpectations(timeout: 10)
    }
    
    func testCancelPausedTask() {
        let expectation = self.expectation(description: "")
        let task = dispatcher.async(on: .main, delay: 0.1) {
            XCTFail("Should not be executed")
        }
        task.pause()
        task.cancel()
        
        XCTAssertEqual(task.state, .complete)
        XCTAssertLessThanOrEqual(task.remainingTime, 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()   // we delay the end of the test to assure that the task is not executed
        }
        waitForExpectations(timeout: 10)
    }
    
    func testImplicitCancelOnTaskDeallocation() {
        let expectation = self.expectation(description: "")
        autoreleasepool {
            var task: DispatchTask? = dispatcher.async(on: .main, delay: 0.1) {
                XCTFail("Should not be executed")
            }
            XCTAssertEqual(task!.state, .active)
            XCTAssertLessThanOrEqual(task!.remainingTime, 0.1)
            task = nil  // by nilling it out the task should not be executed
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()   // we delay the end of the test to assure that the task is not executed
        }
        waitForExpectations(timeout: 10)
    }
    
    // MARK: - Pause & Resume
    
    func testPauseAndResumeTaskOnMainQueue() {
        let executedExpectation = self.expectation(description: "")
        var executed = false
        // dispatch and pause
        let task = dispatcher.async(on: .main, delay: 0.1) {
            executed = true
            executedExpectation.fulfill()
        }
        task.pause()
        
        XCTAssertEqual(task.state, .paused)
        XCTAssertLessThanOrEqual(task.remainingTime, 0.1)
        // assert that task in not executed while paused
        let waitExpectation = self.expectation(description: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(executed)
            waitExpectation.fulfill()   // we delay the end of the test to assure that the task is not executed
        }
        wait(for: [waitExpectation], timeout: 10)
        
        // resume
        task.resume()
        
        XCTAssertEqual(task.state, .active)
        XCTAssertLessThanOrEqual(task.remainingTime, 0.1)
        // assert that task is executed when resumed
        wait(for: [executedExpectation], timeout: 10)
    }
    
    func testPauseAndResumeTaskOnBackgroundQueue() {
        let executedExpectation = self.expectation(description: "")
        var executed = false
        // dispatch and pause
        let task = dispatcher.async(on: .background, delay: 0.1) {
            executed = true
            executedExpectation.fulfill()
        }
        task.pause()
        
        XCTAssertEqual(task.state, .paused)
        XCTAssertLessThanOrEqual(task.remainingTime, 0.1)
        // assert that task in not executed while paused
        let waitExpectation = self.expectation(description: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(executed)
            waitExpectation.fulfill()   // we delay the end of the test to assure that the task is not executed
        }
        wait(for: [waitExpectation], timeout: 10)
        
        // resume
        DispatchQueue.global().async {
            task.resume()
            
            XCTAssertEqual(task.state, .active)
            XCTAssertLessThanOrEqual(task.remainingTime, 0.1)
        }
        // assert that task is executed when resumed
        wait(for: [executedExpectation], timeout: 10)
    }
    
    func testPauseTwiceAndResumeTask() {
        let executedExpectation = self.expectation(description: "")
        var executed = false
        // dispatch and pause
        let task = dispatcher.async(on: .background, delay: 0.1) {
            executed = true
            executedExpectation.fulfill()
        }
        task.pause()
        DispatchQueue.global().async {
            task.pause()
            
            XCTAssertEqual(task.state, .paused)
            XCTAssertLessThanOrEqual(task.remainingTime, 0.1)
        }
        // assert that task in not executed while paused
        let waitExpectation = self.expectation(description: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(executed)
            waitExpectation.fulfill()   // we delay the end of the test to assure that the task is not executed
        }
        wait(for: [waitExpectation], timeout: 10)
        
        // resume
        DispatchQueue.main.async {
            task.resume()
            
            XCTAssertEqual(task.state, .active)
            XCTAssertLessThanOrEqual(task.remainingTime, 0.1)
        }
        // assert that task is executed when resumed
        wait(for: [executedExpectation], timeout: 10)
    }
    
    func testPauseAndResumeTaskMultipleTimes() {
        let executedExpectation = self.expectation(description: "")
        var executed = false
        let delay: TimeInterval = 2
        let errorMargin: TimeInterval = 0.2
        // dispatch
        let startDate = Date()
        let task = dispatcher.async(on: .background, delay: delay) {
            executed = true
            executedExpectation.fulfill()
        }
        
        // pause
        let remainingTime1 = delay - abs(startDate.timeIntervalSinceNow)
        task.pause()
        XCTAssertEqual(task.state, .paused)
        XCTAssertLessThanOrEqual(task.remainingTime, remainingTime1 + errorMargin)
        XCTAssertGreaterThanOrEqual(task.remainingTime, remainingTime1 - errorMargin)
        
        // assert that task in not executed while paused
        let waitExpectation = self.expectation(description: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            XCTAssertFalse(executed)
            waitExpectation.fulfill()   // we delay the end of the test to assure that the task is not executed
        }
        wait(for: [waitExpectation], timeout: 10)
        
        // resume
        let resumeDate = Date()
        task.resume()
        XCTAssertEqual(task.state, .active)
        
        let waitExpectation2 = self.expectation(description: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let remainingTime2 = remainingTime1 - abs(resumeDate.timeIntervalSinceNow)
            task.pause()
            XCTAssertEqual(task.state, .paused)
            XCTAssertLessThanOrEqual(task.remainingTime, remainingTime2 + errorMargin)
            XCTAssertGreaterThanOrEqual(task.remainingTime, remainingTime2 - errorMargin)
            waitExpectation2.fulfill()
        }
        wait(for: [waitExpectation2], timeout: 10)
        
        // assert that task in not executed while paused
        let waitExpectation3 = self.expectation(description: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            XCTAssertFalse(executed)
            waitExpectation3.fulfill()   // we delay the end of the test to assure that the task is not executed
        }
        wait(for: [waitExpectation3], timeout: 10)

        // resume
        task.resume()
        
        // assert that task is finally executed when resumed
        wait(for: [executedExpectation], timeout: 10)
    }
}
