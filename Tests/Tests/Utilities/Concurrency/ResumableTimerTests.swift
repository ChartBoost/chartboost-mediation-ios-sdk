// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class ResumableTimerTests: ChartboostMediationTestCase {
    // MARK: - Test Setup
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Make sure the shared timer is nil'd out
        Self._testMainThreadDeadlockingSharedTimer = nil
    }
    
    // MARK: - Invalidation
    
    /// Tests that the timer does nothing when invalidating after the timer has fired.
    func testInvalidateAfterComplete() throws {
        // Preconditions
        let interval: TimeInterval = 0.05
        let timerExpectation = expectation(description: "Timer fired")
        
        // Create timer and start
        let timer = ResumableTimer(interval: interval) { _ in
            timerExpectation.fulfill()
        }
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .ready = timer.state else {
            XCTFail("Timer state not ready")
            return
        }
        
        // Start the timer.
        timer.scheduleNow()
        XCTAssertTrue(timer.isValid)
        XCTAssertTrue(timer.isCountdownActive)
        guard case .active = timer.state else {
            XCTFail("Timer state not active")
            return
        }
        
        // Wait for timer to fire.
        wait(for: [timerExpectation], timeout: 1)
        
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
        
        // Invalidate
        timer.invalidate()
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
    }
    
    /// Tests that the timer will no longer fire when invalidated in a paused state.
    func testInvalidateAfterPausing() throws {
        // Preconditions
        let interval: TimeInterval = 0.5
        
        // Setup expectation that the timer should not be fired
        // when invalidated.
        let timerExpectation = expectation(description: "Timer fired")
        timerExpectation.isInverted = true
        
        // Create timer and start
        let timer = ResumableTimer(interval: interval) { _ in
            timerExpectation.fulfill()
        }
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .ready = timer.state else {
            XCTFail("Timer state not ready")
            return
        }
        
        // Start the timer.
        timer.scheduleNow()
        XCTAssertTrue(timer.isValid)
        XCTAssertTrue(timer.isCountdownActive)
        guard case .active = timer.state else {
            XCTFail("Timer state not active")
            return
        }
        
        // Pause the timer.
        timer.pause()
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .paused(_) = timer.state else {
            XCTFail("Timer state not paused")
            return
        }
        
        // Invalidate
        timer.invalidate()
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
        
        // Wait for timer to not fire.
        wait(for: [timerExpectation], timeout: 1)
        
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
    }
    
    /// Tests that the timer stops and does not fire the callback when invalidated after starting.
    func testInvalidationWhileActive() throws {
        // Preconditions
        let interval: TimeInterval = 2
        
        // Setup expectation that the timer should not be fired
        // when invalidated.
        let timerExpectation = expectation(description: "Timer fired")
        timerExpectation.isInverted = true
        
        // Create timer and start
        let timer = ResumableTimer(interval: interval) { _ in
            timerExpectation.fulfill()
        }
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .ready = timer.state else {
            XCTFail("Timer state not ready")
            return
        }
        
        // Start the timer.
        timer.scheduleNow()
        XCTAssertTrue(timer.isValid)
        XCTAssertTrue(timer.isCountdownActive)
        guard case .active = timer.state else {
            XCTFail("Timer state not active")
            return
        }
        
        // Invalidate after 1 second
        let deadline = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            timer.invalidate()
            XCTAssertFalse(timer.isValid)
            XCTAssertFalse(timer.isCountdownActive)
            guard case .complete = timer.state else {
                XCTFail("Timer state not complete")
                return
            }
        }
        
        wait(for: [timerExpectation], timeout: interval * 2)
        
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
    }
    
    /// Test pausing before starting the timer.
    func testPauseAfterInvalidate() throws {
        // Create timer and start
        let timer = ResumableTimer(interval: 0.05) { _ in
            // Nothing to do
        }
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .ready = timer.state else {
            XCTFail("Timer state not ready")
            return
        }
        
        // Immediate invalidate
        timer.invalidate()
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
        
        // Restarting an invalid timer should do nothing
        timer.pause()
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
    }
    
    /// Tests starting the timer after invalidation.
    func testStartAfterInvalidate() throws {
        // Create timer and start
        let timer = ResumableTimer(interval: 0.05) { _ in
            // Nothing to do
        }
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .ready = timer.state else {
            XCTFail("Timer state not ready")
            return
        }
        
        // Immediate invalidate
        timer.invalidate()
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
        
        // Restarting an invalid timer should do nothing
        timer.scheduleNow()
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
    }
    
    // MARK: - Time Interval
    
    /// A negative timer interval should choose a nonnegative interval of 0.1ms instead.
    func testNegativeInterval() throws {
        // Preconditions
        let interval: TimeInterval = -10
        let timerExpectation = expectation(description: "Timer fired")
        
        // Create timer and start
        let timer = ResumableTimer(interval: interval, repeats: false) { _ in
            timerExpectation.fulfill()
        }
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .ready = timer.state else {
            XCTFail("Timer state not ready")
            return
        }
        
        timer.scheduleNow()
        XCTAssertTrue(timer.isCountdownActive)
        guard case .active = timer.state else {
            XCTFail("Timer state not active")
            return
        }
        
        wait(for: [timerExpectation], timeout: 1)
        
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
    }
    
    /// Normal use case of a positive timer interval.
    func testPositiveInterval() throws {
        // Preconditions
        let interval: TimeInterval = 2.2
        let timerExpectation = expectation(description: "Timer fired")
        
        // Create timer and start
        let timer = ResumableTimer(interval: interval) { _ in
            timerExpectation.fulfill()
        }
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .ready = timer.state else {
            XCTFail("Timer state not ready")
            return
        }
        
        timer.scheduleNow()
        XCTAssertTrue(timer.isCountdownActive)
        guard case .active = timer.state else {
            XCTFail("Timer state not active")
            return
        }
        
        wait(for: [timerExpectation], timeout: 3)
        
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
    }
    
    /// A zero timer interval should choose a nonnegative interval of 0.1ms instead.
    func testZeroInterval() throws {
        // Preconditions
        let interval: TimeInterval = 0
        let timerExpectation = expectation(description: "Timer fired")
        
        // Create timer and start
        let timer = ResumableTimer(interval: interval) { _ in
            timerExpectation.fulfill()
        }
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .ready = timer.state else {
            XCTFail("Timer state not ready")
            return
        }
        
        timer.scheduleNow()
        XCTAssertTrue(timer.isCountdownActive)
        guard case .active = timer.state else {
            XCTFail("Timer state not active")
            return
        }
        
        wait(for: [timerExpectation], timeout: 1)
        
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
    }
    
    // MARK: - Repeating
    
    /// Normal use case of a positive timer interval.
    func testRepeatingSuccess() throws {
        // Preconditions
        let interval: TimeInterval = 0.5
        let timerExpectation = expectation(description: "Timer fired")
        timerExpectation.expectedFulfillmentCount = 3
        
        // Create timer and start
        // There should be 3 triggers within the expectation limit.
        // start + 0.5, +0.5, and +0.5
        let timer = ResumableTimer(interval: interval, repeats: true) { _ in
            timerExpectation.fulfill()
        }
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .ready = timer.state else {
            XCTFail("Timer state not ready")
            return
        }
        
        timer.scheduleNow()
        XCTAssertTrue(timer.isCountdownActive)
        guard case .active = timer.state else {
            XCTFail("Timer state not active")
            return
        }
        
        wait(for: [timerExpectation], timeout: 2)
        
        XCTAssertTrue(timer.isValid)
        XCTAssertTrue(timer.isCountdownActive)
        guard case .active = timer.state else {
            XCTFail("Timer state not active")
            return
        }
        
        // Invalidate the timer
        timer.invalidate()
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
    }
    
    // MARK: - Pause and Resume
    
    /// Tests that pause stops the timer and the correct remaining time is present.
    func testPause() throws {
        // Preconditions
        let interval: TimeInterval = 4
        let halfInterval: TimeInterval = interval / 2
        let pauseExpectation = expectation(description: "Pause fired")
        
        // Create timer
        let timer = ResumableTimer(interval: interval) { _ in
            // no-op
        }
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .ready = timer.state else {
            XCTFail("Timer state not ready")
            return
        }
        
        // Start the timer.
        timer.scheduleNow()
        XCTAssertTrue(timer.isValid)
        XCTAssertTrue(timer.isCountdownActive)
        guard case .active = timer.state else {
            XCTFail("Timer state not active")
            return
        }
                
        // After `halfInterval` seconds have elapsed, pause the timer.
        let deadline = DispatchTime.now() + .seconds(Int(halfInterval))
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            timer.pause()
            XCTAssertTrue(timer.isValid)
            XCTAssertFalse(timer.isCountdownActive)
            guard case .paused(let remainingTime) = timer.state else {
                XCTFail("Timer state not paused")
                return
            }
            
            // There should be about half of the interval remaining.
            let roundedRemainingTime = Int(round(remainingTime))
            let expectedRemainingTime = Int(halfInterval)
            XCTAssertEqual(roundedRemainingTime, expectedRemainingTime)
            
            pauseExpectation.fulfill()
        }
        
        // Wait for pause to occur at the half duration mark.
        wait(for: [pauseExpectation], timeout: interval)
        
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .paused(_) = timer.state else {
            XCTFail("Timer state not paused")
            return
        }
    }
    
    /// Test pausing before starting the timer.
    func testPauseBeforeStarting() throws {
        // Preconditions
        let interval: TimeInterval = 0.5
        let timerExpectation = expectation(description: "Timer fired")
        
        // Create timer
        let timer = ResumableTimer(interval: interval, repeats: false) { _ in
            timerExpectation.fulfill()
        }
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .ready = timer.state else {
            XCTFail("Timer state not ready")
            return
        }
        
        // Pause and verify nothing changed since the timer was never started.
        timer.pause()
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .ready = timer.state else {
            XCTFail("Timer state not ready")
            return
        }
        
        // Start the timer and verify it started up correctly.
        timer.scheduleNow()
        XCTAssertTrue(timer.isValid)
        XCTAssertTrue(timer.isCountdownActive)
        guard case .active = timer.state else {
            XCTFail("Timer state not active")
            return
        }
        
        wait(for: [timerExpectation], timeout: 5)
        
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
    }
    
    /// Tests that pausing additional times while paused does nothing.
    func testPauseWhenAlreadyPaused() throws {
        // Preconditions
        let interval: TimeInterval = 0.5
        let timerExpectation = expectation(description: "Timer fired")
        timerExpectation.isInverted = true
        
        // Create timer
        let timer = ResumableTimer(interval: interval, repeats: false) { _ in
            timerExpectation.fulfill()
        }
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .ready = timer.state else {
            XCTFail("Timer state not ready")
            return
        }
        
        // Start the timer and verify it started up correctly.
        timer.scheduleNow()
        XCTAssertTrue(timer.isValid)
        XCTAssertTrue(timer.isCountdownActive)
        guard case .active = timer.state else {
            XCTFail("Timer state not active")
            return
        }
        
        // Pause and verify state is paused
        timer.pause()
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .paused(_) = timer.state else {
            XCTFail("Timer state not paused")
            return
        }
        
        // Pause again, and nothing should change.
        timer.pause()
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .paused(_) = timer.state else {
            XCTFail("Timer state not paused")
            return
        }
        
        // Expect the timer to never fire.
        wait(for: [timerExpectation], timeout: 5)
    }
    
    /// Tests that resuming the timer after a pause will continue with the time remaining rather than starting a new timer.
    func testResumeAfterPause() throws {
        // Preconditions
        let interval: TimeInterval = 4
        let halfInterval: TimeInterval = interval / 2
        let timerExpectation = expectation(description: "Timer fired")
        
        // Create timer
        let timer = ResumableTimer(interval: interval) { _ in
            timerExpectation.fulfill()
        }
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .ready = timer.state else {
            XCTFail("Timer state not ready")
            return
        }
        
        // Start the timer.
        timer.scheduleNow()
        XCTAssertTrue(timer.isValid)
        XCTAssertTrue(timer.isCountdownActive)
        guard case .active = timer.state else {
            XCTFail("Timer state not active")
            return
        }
                
        // After `halfInterval` seconds have elapsed, pause the timer.
        let deadline = DispatchTime.now() + .seconds(Int(halfInterval))
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            timer.pause()
            XCTAssertTrue(timer.isValid)
            XCTAssertFalse(timer.isCountdownActive)
            guard case .paused(_) = timer.state else {
                XCTFail("Timer state not paused")
                return
            }
            
            // After `halfInterval` seconds of being paused, resume the timer,
            // which should have `halfInterval` seconds remaining.
            DispatchQueue.main.asyncAfter(deadline: deadline) {
                timer.scheduleNow()
                XCTAssertTrue(timer.isValid)
                XCTAssertTrue(timer.isCountdownActive)
                guard case .active = timer.state else {
                    XCTFail("Timer state not active")
                    return
                }
            }
        }
        
        // Wait for timer duration + pause time + some tolerance.
        // In the event that the old behavior where the timer starts
        // fresh on resume, that time will exceed the wait time by
        // `halfInterval`.
        let tolerance: TimeInterval = 0.5;
        let expectedTotalTimeInterval = interval + halfInterval + tolerance
        wait(for: [timerExpectation], timeout: expectedTotalTimeInterval)
        
        XCTAssertFalse(timer.isValid)
        XCTAssertFalse(timer.isCountdownActive)
        guard case .complete = timer.state else {
            XCTFail("Timer state not complete")
            return
        }
    }
    
    // MARK: - Threading (Basic)
    
    /// Tests  background initialization and scheduling.
    func testBackgroundThreadInitialization() throws {
        // Preconditions
        let interval: TimeInterval = 0.5
        let timerExpectation = expectation(description: "Timer fired")
        let threadExpectation = expectation(description: "Background thread finished execution")
        
        // Perform the rest of the test on a non-main thread.
        DispatchQueue.global().async {
            // Create timer
            let timer = ResumableTimer(interval: interval) { _ in
                timerExpectation.fulfill()
            }
            XCTAssertNotNil(timer)
            XCTAssertTrue(timer.isValid)
            XCTAssertFalse(timer.isCountdownActive)
            guard case .ready = timer.state else {
                XCTFail("Timer state not ready")
                return
            }
            
            // Start the timer and verify it started up correctly.
            timer.scheduleNow()
            XCTAssertTrue(timer.isValid)
            XCTAssertTrue(timer.isCountdownActive)
            guard case .active = timer.state else {
                XCTFail("Timer state not active")
                return
            }
            
            // Wait for the timer to successfully fire
            self.wait(for: [timerExpectation], timeout: 2)
            
            // Notify the test that the background thread has completed.
            threadExpectation.fulfill()
        }
        
        wait(for: [threadExpectation], timeout: 5)
    }
    
    // MARK: - Threading (Stress)
    
    /// Given a seed number, randomly selects a `DispatchQueue` for testing.
    /// - Parameter seed: Random seed.
    /// - Returns: A random `DispatchQueue` for testing.
    fileprivate func randomQueue(seed: UInt32) -> DispatchQueue {
        switch arc4random_uniform(seed) % 6 {
        case 0: return DispatchQueue.main
        case 1: return DispatchQueue.global(qos: .userInteractive)
        case 2: return DispatchQueue.global(qos: .userInitiated)
        case 3: return DispatchQueue.global(qos: .default)
        case 4: return DispatchQueue.global(qos: .utility)
        default: return DispatchQueue.global(qos: .background)
        }
    }
    
    /// Validates that the timer functions in a thread-safe manner.
    func testBackgroundMultithreading() throws {
        // Preconditions
        let backgroundQueue: DispatchQueue = DispatchQueue.global(qos: .userInteractive)
        let numberOfTimers: Int = 10000
        var timers: [ResumableTimer] = []
        
        // Configure test expectation
        let timerExpectation = expectation(description: "All timers fired")
        timerExpectation.expectedFulfillmentCount = numberOfTimers
        
        // Generate `numberOfTimers` of timers that are scheduled at random intervals.
        for _ in 0 ..< numberOfTimers {
            // Generate a random interval
            let randomInterval = TimeInterval(arc4random_uniform(20))
            
            // Create timer
            let timer = ResumableTimer(interval: randomInterval) { (resumableTimer) in
                timerExpectation.fulfill()
                resumableTimer.invalidate()
            }
            
            // Add the timer to `timers` so that the reference is captured.
            timers.append(timer)
        } // End for
        
        // Dispatch the scheduling.
        timers.forEach { (timer) in
            backgroundQueue.async {
                timer.scheduleNow()
            }
        }
        
        // The `for` loop might take a while if there are a large number of loops on slow machines, so
        // use a long timeout and rely on the `endingTimer` to fulfill the test expectation early. On
        // faster machines with 10000 loops, this test case takes about 0.25 second.
        wait(for: [timerExpectation], timeout: 60)
    }
    
    // Generates a shared test timer for the `testMainThreadDeadlocking()` unit test.
    // The `testMainThreadDeadlockingSharedTimer` and `_testMainThreadDeadlockingSharedTimer` static variables are in the scope
    // of the class so that `setup` can clear them out on every test run.
    fileprivate static var _testMainThreadDeadlockingSharedTimer: ResumableTimer? = nil
    fileprivate static var testMainThreadDeadlockingSharedTimer: ResumableTimer {
        // Give back the already created shared timer.
        if let staticTimer = _testMainThreadDeadlockingSharedTimer {
            return staticTimer
        }
        
        // Otherwise create a new timer
        _testMainThreadDeadlockingSharedTimer = ResumableTimer(interval: 0.05) { _ in
            // no-op
        }
        return _testMainThreadDeadlockingSharedTimer!
    }
    
    /// Tests that `ResumableTimer` will not deadlock the main thread.
    func testMainThreadDeadlocking() throws {
        // Configure test expectation
        let timerExpectation = expectation(description: "All timers fired")
        timerExpectation.expectedFulfillmentCount = 2
        
        // Main thread access of shared timer
        DispatchQueue.main.async {
            let mainTimer = Self.testMainThreadDeadlockingSharedTimer
            XCTAssertTrue(mainTimer.isValid)
            
            timerExpectation.fulfill()
        }
        
        DispatchQueue.global(qos: .default).async {
            let threadTimer = Self.testMainThreadDeadlockingSharedTimer
            XCTAssertTrue(threadTimer.isValid)
            
            threadTimer.scheduleNow()
            timerExpectation.fulfill()
        }
        
        wait(for: [timerExpectation], timeout: 5)
    }
    
    /// Test thread safety of `ResumableTimer`. The original `MPTimer` wasn't thread safe in the past, and `scheduleNow` might
    /// crash if the internal `Timer` is set to `nil` by `invalidate` before `scheduleNow` completes.
    /// With the thread safety update in ADF-4128, `MPTimer` should not crash for any call sequence.
    func testMultiThreadSchedulingAndInvalidation() throws {
        // Preconditions
        let interval: TimeInterval = 0.05
        let numberOfTimers: Int = 10000
        let randomNumberUpperBound: UInt32 = 100
        var timers: [ResumableTimer] = []
        
        // Generate `numberOfTimers` of timers.
        for _ in 0 ..< numberOfTimers {
            // Create timer
            let timer = ResumableTimer(interval: interval) { _ in
                // no-op
            }
            
            // Add the timer to `timers` so that the reference is captured.
            timers.append(timer)
        } // End for
        
        // Perform random scheduling and invalidation stress testing.
        timers.forEach { (timer) in
            // Select random queues.
            let schedulingQueue = randomQueue(seed: randomNumberUpperBound)
            let invalidationQueue = randomQueue(seed: randomNumberUpperBound)
            
            // Call `scheduleNow()` before `invalidate()`
            if arc4random_uniform(randomNumberUpperBound) % 2 == 0 {
                schedulingQueue.async { timer.scheduleNow() }
                invalidationQueue.async { timer.invalidate() }
            }
            // Call `invalidate()` before `scheduleNow()`
            else {
                invalidationQueue.async { timer.invalidate() }
                schedulingQueue.async { timer.scheduleNow() }
            }
        } // End for
        
        // The last timer is for fulfilling the test expectation and finishing this test - previous timers
        // are randomly invalidated and we cannot rely on them for fulfilling the test expection.
        // Create an expectation waiting for the expected number of expectation triggers to fire.
        let timerExpectation = expectation(description: "Timer fired")
        
        // Create the ending timer
        let endingTimer = ResumableTimer(interval: interval) { _ in
            timerExpectation.fulfill()
        }
        
        DispatchQueue.main.async {
            endingTimer.scheduleNow()
        }

        // The `for` loop might take a while if there are a large number of loops on slow machines, so
        // use a long timeout and rely on the `endingTimer` to fulfill the test expectation early. On
        // faster machines with 10000 loops, this test case takes about 0.25 second.
        wait(for: [timerExpectation], timeout: 60)
    }
}
