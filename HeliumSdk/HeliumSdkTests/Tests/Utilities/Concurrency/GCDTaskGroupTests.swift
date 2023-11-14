// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class GCDTaskGroupTests: ChartboostMediationTestCase {

    /// Validates that the completion handler is executed immediately if onAllFinished is called when no tasks were added.
    func testOnAllFinishedExecutedImmediatelyIfCalledBeforeAnyTaskAdded() {
        let group = GCDTaskGroup(queue: .main)
        
        // Execute onAllFinish without adding tasks
        let expectation = expectation(description: "")
        group.onAllFinished(timeout: 10) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    /// Validates that the completion handler is executed immediately if onAllFinished is called after all added tasks were completed.
    func testOnAllFinishedExecutedImmediatelyIfCalledAfterAllTasksAreCompleted() {
        let group = GCDTaskGroup(queue: .main)
        
        // Add two tasks that finish immediately
        group.add { finished in
            finished()
        }
        
        group.add { finished in
            finished()
        }
        
        // Execute onAllFinish should still finish immediately since all tasks finished
        let expectation = expectation(description: "")
        group.onAllFinished(timeout: 10) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    /// Validates that the completion handler is executed after all tasks are finished even if some tasks are added after onAllFinished is called.
    func testOnAllFinishedWaitsUntilAllTasksAreCompletedIfNewTasksAreAddedAfterwards() {
        let group = GCDTaskGroup(queue: .main)
        var allFinished = false
        
        // Add two tasks that finish immediately
        group.add { finished in
            finished()
        }
        
        group.add { finished in
            finished()
        }
        
        // Add a third task that does not finish yet
        var thirdTaskFinished: () -> Void = {}
        group.add { finished in
            thirdTaskFinished = finished
        }
        
        // Execute onAllFinish should not finish until that third task finishes
        let finishExpectation = expectation(description: "")
        group.onAllFinished(timeout: 10) {
            allFinished = true
            finishExpectation.fulfill()
        }
        
        // We make sure that onAllFinish completion is not called
        let waitExpectation = expectation(description: "wait for 0.5 secs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            waitExpectation.fulfill()
        }
        wait(for: [waitExpectation], timeout: 5)
        XCTAssertFalse(allFinished)
        
        // We finish the third task
        thirdTaskFinished()
        
        // Now the onAllFinish completion should have been called
        wait(for: [finishExpectation], timeout: 5)
        XCTAssertTrue(allFinished)
    }
    
    /// Validates that the completion handler is executed after all tasks are finished when they are added before the `onAllFinished()` call.
    func testOnAllFinishedWaitsUntilAllTasksAreCompleted() {
        let group = GCDTaskGroup(queue: .main)
        var allFinished = false
        var taskCount = 0
        var taskFinished1: () -> Void = {}
        var taskFinished2: () -> Void = {}
        var taskFinished3: () -> Void = {}
        
        // Add three tasks that do not finish yet
        group.add { finished in
            taskCount += 1
            taskFinished1 = finished
        }
        
        group.add { finished in
            taskCount += 1
            taskFinished2 = finished
        }
        
        group.add { finished in
            taskCount += 1
            taskFinished3 = finished
        }
        
        // Execute onAllFinish should not finish until all tasks finish
        let finishExpectation = expectation(description: "")
        group.onAllFinished(timeout: 10) {
            allFinished = true
            finishExpectation.fulfill()
        }
        
        // We make sure that onAllFinish completion is not called
        let waitExpectation = expectation(description: "wait for 0.5 secs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            waitExpectation.fulfill()
        }
        wait(for: [waitExpectation], timeout: 5)
        XCTAssertFalse(allFinished)
        
        // We finish the second task
        taskFinished2()
        
        // We make sure that onAllFinish completion is not called
        let waitExpectation2 = expectation(description: "wait for 0.5 secs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            waitExpectation2.fulfill()
        }
        wait(for: [waitExpectation2], timeout: 5)
        XCTAssertFalse(allFinished)

        // We finish the first task
        taskFinished1()
        
        // We make sure that onAllFinish completion is not called
        let waitExpectation3 = expectation(description: "wait for 0.5 secs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            waitExpectation3.fulfill()
        }
        wait(for: [waitExpectation3], timeout: 5)
        XCTAssertFalse(allFinished)
        
        // We finish the third task
        taskFinished3()
        
        // Now the onAllFinish completion should have been called
        wait(for: [finishExpectation], timeout: 5)
        XCTAssertTrue(allFinished)
        XCTAssertEqual(taskCount, 3)
    }
    
    /// Validates that the completion handler is executed after the timeout interval if not all tasks are finished on time, and that when those tasks finish the completion is not called again.
    func testOnAllFinishedIsCalledAfterTimeoutIfTasksDontFinishOnTime() {
        let group = GCDTaskGroup(queue: .main)
        var allFinished = false
        var taskCount = 0
        var taskFinished1: () -> Void = {}
        var taskFinished2: () -> Void = {}
        var taskFinished3: () -> Void = {}
        
        // Add three tasks that do not finish yet
        group.add { finished in
            taskCount += 1
            taskFinished1 = finished
        }
        
        group.add { finished in
            taskCount += 1
            taskFinished2 = finished
        }
        
        group.add { finished in
            taskCount += 1
            taskFinished3 = finished
        }
        
        // We finish the third task
        taskFinished3()
        
        // Execute onAllFinish should not finish until all tasks finish
        let finishExpectation = expectation(description: "")
        group.onAllFinished(timeout: 1) {
            allFinished = true
            finishExpectation.fulfill()
        }
        
        // We finish the second task
        taskFinished1()
        
        // We wait so the timeout fires
        wait(for: [finishExpectation], timeout: 2)
        XCTAssertTrue(allFinished)
        XCTAssertEqual(taskCount, 3)
        allFinished = false

        // We finish the second task
        taskFinished2()
        
        // We make sure that onAllFinish completion is not called again
        let waitExpectation2 = expectation(description: "wait for 0.5 secs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            waitExpectation2.fulfill()
        }
        wait(for: [waitExpectation2], timeout: 5)
        XCTAssertFalse(allFinished)
    }
    
    /// Validates that the completion handler is executed after one task is finished when added before the `onAllFinished()` call.
    func testOnAllFinishedWaitsUntilOneSingleAddedTaskIsCompleted() {
        let group = GCDTaskGroup(queue: .main)
        var allFinished = false
        var taskCount = 0
        var taskFinished1: () -> Void = {}
        
        // Add three tasks that do not finish yet
        group.add { finished in
            taskCount += 1
            taskFinished1 = finished
        }
        
        // Execute onAllFinish should not finish until all tasks finish
        let finishExpectation = expectation(description: "")
        group.onAllFinished(timeout: 10) {
            allFinished = true
            finishExpectation.fulfill()
        }
        
        // We make sure that onAllFinish completion is not called
        let waitExpectation = expectation(description: "wait for 0.5 secs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            waitExpectation.fulfill()
        }
        wait(for: [waitExpectation], timeout: 5)
        XCTAssertFalse(allFinished)
        
        // We finish the task
        taskFinished1()
        
        // Now the onAllFinish completion should have been called
        wait(for: [finishExpectation], timeout: 5)
        XCTAssertTrue(allFinished)
        XCTAssertEqual(taskCount, 1)
    }
}
