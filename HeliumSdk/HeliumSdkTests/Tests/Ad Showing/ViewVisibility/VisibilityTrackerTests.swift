// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class VisibilityTrackerTests: HeliumTestCase {
    typealias Configuration = VisibilityTrackerConfigurationMock

    // MARK: - Test Constants
    
    private struct Constants {
        /// Default view frame size used for testing.
        static let defaultFrameSize = CGSize(width: 320, height: 50)
        
        /// A short impression time so that the timer only takes one tick to fire.
        static let shortImpressionTime: TimeInterval = 0.05
        
        /// A long impression time so that the timer takes several ticks to fire.
        static let longImpressionTime: TimeInterval = 0.25
        
        /// A delay time that can be used to perform actions before timers for `longImpressionTime` fire,
        /// but after one tick of the ad impression timer.
        static let longDelay: TimeInterval = 0.15
        
        /// Timeout for most tests.
        static let timeout: TimeInterval = 0.5

    }
    
    // MARK: - Test Properties
    
    /// Mock `UIApplication` information provider.
    var app = ApplicationMock()
    
    /// Superview meant to contain `view`.
    var superview = UIView()
    
    /// View to track
    var view = UIView()
    
    /// Window attached to `superview`.
    var window = UIWindow()
    
    // MARK: - Test Setup
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Reset test state.
        app.state = .active
        
        // Default frame to use for all testing views.
        let defaultFrame = CGRect(origin: .zero, size: Constants.defaultFrameSize)
        
        // Hide the window by default.
        window = UIWindow(frame: defaultFrame)
        window.isHidden = false
        
        // Generate the super view.
        superview = UIView(frame: defaultFrame)
        window.addSubview(superview)
        
        // Generate the view.
        view = UIView(frame: defaultFrame)
        superview.addSubview(view)
    }
    
    // MARK: - Tracking Tests
    
    /// Validates tracker fires normally when view is visible under the conditions:
    /// - 1 pixel on screen
    /// - More than `Constants.shortImpressionTime` seconds visible
    func testTrackingFires() {
        let timerExpectation = expectation(description: "Wait for VisibilityTracker to fire")
        let configuration = Configuration(minimumVisibleSeconds: Constants.shortImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer.startTracking(view) {
            timerExpectation.fulfill()
        }
        
        waitForExpectations(timeout: Constants.timeout) { (error) in
            XCTAssertNil(error)
        }
    }
    
    /// Validates tracker fires normally when view is visible under the conditions:
    /// - 1 pixel on screen
    /// - More than 0 seconds visible
    func testZeroImpressionTimeFires() {
        let timerExpectation = expectation(description: "Wait for VisibilityTracker to fire")
        let configuration = Configuration(minimumVisibleSeconds: 0, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        // Since the minimum time to fire is 0.1 seconds, an impression time
        // of 0 should still fire.
        timer.startTracking(view) {
            timerExpectation.fulfill()
        }
        
        waitForExpectations(timeout: Constants.timeout) { (error) in
            XCTAssertNil(error)
        }
    }
    
    /// Validates tracker fires normally when view is visible under the conditions:
    /// - 1 pixel on screen
    /// - A negative minimum seconds is specified.
    func testNegativeImpressionTimeFires() {
        let timerExpectation = expectation(description: "Wait for VisibilityTracker to fire")
        let configuration = VisibilityTrackerConfigurationMock(minimumVisibleSeconds: -1000, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer.startTracking(view) {
            timerExpectation.fulfill()
        }
        
        waitForExpectations(timeout: Constants.timeout) { (error) in
            XCTAssertNil(error)
        }
    }
    
    /// Validates tracker does not fire when under the conditions:
    /// - 1 pixel on screen
    /// - More than `Constants.shortImpressionTime` seconds visible
    /// - `view` is hidden
    func testTrackingDoesNotFireWhenViewNotVisible() {
        // Preconditions
        view.isHidden = true
        
        // Expecting no fulfillment
        let timerExpectation = expectation(description: "VisibilityTracker should not fire")
        timerExpectation.isInverted = true
        
        let configuration = Configuration(minimumVisibleSeconds: Constants.shortImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer.startTracking(view) {
            timerExpectation.fulfill()
        }
        
        waitForExpectations(timeout: Constants.timeout) { (error) in
            XCTAssertNil(error)
        }
    }

    /// Validates tracker does not fire when under the conditions:
    /// - 1 pixel on screen
    /// - More than `Constants.shortImpressionTime` seconds visible
    /// - App is inactive
    func testDoesNotTrackIfAppIsNotActive() {
        // Preconditions
        app.state = .inactive
        
        // Expecting no fulfillment
        let timerExpectation = expectation(description: "VisibilityTracker should not fire")
        timerExpectation.isInverted = true
        
        let configuration = Configuration(minimumVisibleSeconds: Constants.shortImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer.startTracking(view) {
            timerExpectation.fulfill()
        }
        
        waitForExpectations(timeout: Constants.timeout) { (error) in
            XCTAssertNil(error)
        }
    }
    
    /// Validates tracker does not fire when under the conditions:
    /// - 1 pixel on screen
    /// - More than `Constants.shortImpressionTime` seconds visible
    /// - App is backgrounded
    func testDoesNotTrackIfAppIsBackgrounded() {
        // Preconditions
        app.state = .background
        
        // Expecting no fulfillment
        let timerExpectation = expectation(description: "VisibilityTracker should not fire")
        timerExpectation.isInverted = true
        
        let configuration = Configuration(minimumVisibleSeconds: Constants.shortImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer.startTracking(view) {
            timerExpectation.fulfill()
        }
        
        waitForExpectations(timeout: Constants.timeout) { (error) in
            XCTAssertNil(error)
        }
    }
    
    /// Validates tracker does not fire prematurely fire.
    func testDoesNotFireBeforeImpressionTime() {
        // Expecting no fulfillment from the long delay
        let doesNotTrackExpectation = expectation(description: "VisibilityTracker should not fire")
        doesNotTrackExpectation.isInverted = true
        
        // Expectation fullfilment when the tracker has fired after waiting for longer than `Constants.longImpressionTime`
        let trackExpectation = expectation(description: "Wait for VisibilityTracker tick to fire")
        
        // Make sure the impression time takes several ticks of the underlying timer.
        let configuration = Configuration(minimumVisibleSeconds: Constants.longImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer.startTracking(view) {
            doesNotTrackExpectation.fulfill()
            trackExpectation.fulfill()
        }
        
        // After this timeout, the underlying timer should have fired once,
        // but since this is shorter than the impression time, the impression
        // should not have fired yet.
        wait(for: [doesNotTrackExpectation], timeout: Constants.longDelay)
        
        // But then the impression should track after a bit longer.
        wait(for: [trackExpectation], timeout: Constants.timeout)
    }
    
    /// Validates tracker does not fire when `nil`-d out.
    func testDoesNotFireWhenSetToNil() {
        // Expecting no fulfillment
        let timerExpectation = expectation(description: "VisibilityTracker should not fire")
        timerExpectation.isInverted = true
        
        // Make sure the impression time takes several ticks of the underlying timer.
        let configuration = Configuration(minimumVisibleSeconds: Constants.longImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        var timer: VisibilityTracker? = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer?.startTracking(view) {
            timerExpectation.fulfill()
        }
        
        // `nil` out the timer after a delay should dealloc it, which
        // should invalidate the underlying timer.
        let milliseconds = Int(Constants.longDelay * 1000)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(milliseconds)) {
            timer = nil
        }
        
        waitForExpectations(timeout: Constants.timeout) { (error) in
            XCTAssertNil(error)
        }
    }
    
    /// Validates tracker does not fire when the tracked view is `nil`-d out.
    func testDoesNotFireWhenViewBecomesNil() {
        let timerExpectation = expectation(description: "VisibilityTracker should not fire")
        timerExpectation.isInverted = true
        
        // Make sure the impression time takes several ticks of the underlying timer.
        let configuration = Configuration(minimumVisibleSeconds: Constants.longImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        var testView: UIView? = UIView(frame: CGRect(origin: .zero, size: Constants.defaultFrameSize))
        timer.startTracking(testView!) {
            timerExpectation.fulfill()
        }
        
        // Nilling out the view after a delay should dealloc it, which
        // should invalidate the underlying timer.
        let milliseconds = Int(Constants.longDelay * 1000)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(milliseconds)) {
            testView = nil
        }
        
        waitForExpectations(timeout: Constants.timeout) { (error) in
            XCTAssertNil(error)
        }
    }
    
    /// Validates tracker does not track when the tracked view's visibility changes to hidden.
    func testDoesNotTrackWhenViewIsNoLongerVisible() {
        let timerExpectation = expectation(description: "VisibilityTracker should not fire")
        timerExpectation.isInverted = true
        
        // Make sure the impression time takes several ticks of the underlying timer.
        let configuration = Configuration(minimumVisibleSeconds: Constants.longImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer.startTracking(view) {
            timerExpectation.fulfill()
        }
        
        // The tracker should stop tracking if the view is no longer visible.
        let milliseconds = Int(Constants.longDelay * 1000)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(milliseconds)) {
            self.view.isHidden = true
        }
        
        waitForExpectations(timeout: Constants.timeout) { (error) in
            XCTAssertNil(error)
        }
    }
    
    /// Validates tracker resumes tracking when view becomes visible.
    func testTracksWhenViewBecomesVisible() {
        // Preconditions
        view.isHidden = true
        
        // Expecting no fulfillment from the long delay
        let doesNotTrackExpectation = expectation(description: "VisibilityTracker should not fire")
        doesNotTrackExpectation.isInverted = true
        
        // Expectation fullfilment when the tracker has fired after waiting for longer than `Constants.shortImpressionTime`
        let trackExpectation = expectation(description: "Wait for VisibilityTracker tick to fire")
        
        // Make sure the impression time takes several ticks of the underlying timer.
        let configuration = Configuration(minimumVisibleSeconds: Constants.shortImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer.startTracking(view) {
            doesNotTrackExpectation.fulfill()
            trackExpectation.fulfill()
        }
        
        // Since the view is not visible, it should not have tracked by
        // this point.
        wait(for: [doesNotTrackExpectation], timeout: Constants.timeout)

        // Make the view visible, and it should track.
        view.isHidden = false
        wait(for: [trackExpectation], timeout: Constants.timeout)
    }
    
    /// Validates tracking stops when the app is no longer active.
    func testDoesNotTrackWhenAppIsNoLongerActive() {
        // Expecting no fulfillment
        let timerExpectation = expectation(description: "VisibilityTracker should not fire")
        timerExpectation.isInverted = true
        
        // Make sure the impression time takes several ticks of the underlying timer.
        let configuration = Configuration(minimumVisibleSeconds: Constants.longImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer.startTracking(view) {
            timerExpectation.fulfill()
        }
        
        // The tracker should not track if the app is no longer active.
        let milliseconds = Int(Constants.longDelay * 1000)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(milliseconds)) {
            self.app.state = .inactive
        }
        
        waitForExpectations(timeout: Constants.timeout) { (error) in
            XCTAssertNil(error)
        }
    }
    
    /// Validates tracking resumes when the app becomes active.
    func testTracksWhenAppBecomesActive() {
        // Preconditions
        app.state = .inactive
        
        // Expecting no fulfillment from the long delay
        let doesNotTrackExpectation = expectation(description: "VisibilityTracker should not fire")
        doesNotTrackExpectation.isInverted = true
        
        // Expectation fullfilment when the tracker has fired after waiting for longer than `Constants.shortImpressionTime`
        let trackExpectation = expectation(description: "Wait for VisibilityTracker tick to fire")
        
        // Make sure the impression time takes several ticks of the underlying timer.
        let configuration = Configuration(minimumVisibleSeconds: Constants.shortImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer.startTracking(view) {
            doesNotTrackExpectation.fulfill()
            trackExpectation.fulfill()
        }
        
        // Since the app is not active, it should not have tracked by
        // this point.
        wait(for: [doesNotTrackExpectation], timeout: Constants.timeout)

        // Make the app active, and it should track.
        app.state = .active
        wait(for: [trackExpectation], timeout: Constants.timeout)
    }
    
    /// Validates that the tracker only fires once.
    func testOnlyTracksOneTime() {
        // Create an inverted expectation with a fulfillment count of 2,
        // which will fail if the completion block is called more than once.
        let timerExpectation = expectation(description: "VisibilityTracker should fire once")
        timerExpectation.expectedFulfillmentCount = 2
        timerExpectation.isInverted = true
        
        let configuration = Configuration(minimumVisibleSeconds: Constants.shortImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer.startTracking(view) {
            timerExpectation.fulfill()
        }
        
        waitForExpectations(timeout: Constants.timeout) { (error) in
            XCTAssertNil(error)
        }
    }
    
    /// Validates that starting an already started timer has no effect.
    func testDoubleStartTracking() {
        let timerExpectation = expectation(description: "Wait for VisibilityTracker to fire")
        let configuration = Configuration(minimumVisibleSeconds: Constants.shortImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        // Call startTracking twice, the second call should have no effect,
        // and the view passed back should be the first view.
        timer.startTracking(view) {
            timerExpectation.fulfill()
        }
        let otherView = UIView()
        timer.startTracking(otherView) {
            XCTFail()
        }
        
        waitForExpectations(timeout: Constants.timeout) { (error) in
            XCTAssertNil(error)
        }
    }
    
    // MARK: - isTracking Tests
    
    func testInitialIsTrackingValue() {
        let configuration = Configuration(minimumVisibleSeconds: Constants.shortImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        XCTAssertFalse(timer.isTracking)
    }
    
    func testIsTrackingValueAfterStartingTracking() {
        let configuration = Configuration(minimumVisibleSeconds: Constants.shortImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer.startTracking(view) {}
        
        XCTAssertTrue(timer.isTracking)
    }
    
    func testIsTrackingValueAfterTrackingFinishes() {
        let timerExpectation = expectation(description: "Wait for VisibilityTracker to fire")
        let configuration = Configuration(minimumVisibleSeconds: Constants.shortImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer.startTracking(view) {
            XCTAssertFalse(timer.isTracking)
            timerExpectation.fulfill()
        }
        
        waitForExpectations(timeout: Constants.timeout) { (error) in
            XCTAssertFalse(timer.isTracking)
        }
    }
    
    func testIsTrackingValueAfterTrackingIsStopped() {
        let configuration = Configuration(minimumVisibleSeconds: Constants.shortImpressionTime, minimumVisiblePoints: 1, pollInterval: 0.1, traversalLimit: 25)
        let timer = PixelByTimeVisibilityTracker(configuration: configuration, app: app)
        
        timer.startTracking(view) {}
        
        timer.stopTracking()
        
        XCTAssertFalse(timer.isTracking)
    }
}
