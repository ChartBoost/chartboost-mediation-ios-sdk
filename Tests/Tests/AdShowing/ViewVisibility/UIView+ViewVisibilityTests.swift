// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import UIKit
import XCTest
@testable import ChartboostMediationSDK

class UIViewViewVisibilityTests: ChartboostMediationTestCase {
    // MARK: - Test Constants

    struct Constants {
        /// Default view frame size used for testing.
        static let defaultFrameSize = CGSize(width: 320, height: 50)
    }
    
    // MARK: - Test Properties
    
    /// Superview meant to contain `view`.
    var superview = UIView()
    
    /// View to track
    var view = UIView()
    
    /// Window attached to `superview`.
    var window = UIWindow()
    
    // MARK: - Test Setup
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
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
    
    // MARK: - Frame Intersection Tests
    
    /// Validate that the entire `view` is visible in its `superview`.
    func testPointsTrackingMode() {
        let points = Constants.defaultFrameSize.width * Constants.defaultFrameSize.height
        XCTAssertTrue(view.isVisible(minimumVisiblePoints: 1))
        XCTAssertTrue(view.isVisible(minimumVisiblePoints: points))
    }
    
    /// Validate that partial overlap of the `view` and `superview`.
    func testViewWithPartialOverlapPointsTrackingMode() {
        // Make this view have 4 points visible, it should be visible
        // if testing against 4 points, but not 5 points.
        view.frame.origin = CGPoint(x: Constants.defaultFrameSize.width - 2, y: Constants.defaultFrameSize.height - 2)
        XCTAssertTrue(view.isVisible(minimumVisiblePoints: 4))
        XCTAssertFalse(view.isVisible(minimumVisiblePoints: 5))
    }
    
    /// Validate that fractional partial overlap of the `view` and `superview`.
    func testFractionalPointOverlap() {
        view.frame.origin = CGPoint(x: Constants.defaultFrameSize.width - 0.5, y: Constants.defaultFrameSize.height - 0.5)
        XCTAssertTrue(view.isVisible(minimumVisiblePoints: 0))
        XCTAssertFalse(view.isVisible(minimumVisiblePoints: 1))
    }
    
    /// Validate clipped and moved views.
    func testSuperviewClipsView() {
        // Even though the view is clipped by its superview, the view is
        // still 100% within the window.
        superview.frame.size = CGSize(width: Constants.defaultFrameSize.width, height: Constants.defaultFrameSize.height / 2)
        XCTAssertTrue(view.isVisible)
    }

    /// Validate that view is not visible if there is no intersection.
    func testViewDoesNotIntersectWindow() {
        view.frame.origin = CGPoint(x: Constants.defaultFrameSize.width, y: Constants.defaultFrameSize.height)
        XCTAssertFalse(view.isVisible)
    }
    
    /// Validate view is not visible if its superview does not intersect the window frame.
    func testSuperviewDoesNotIntersectWindow() {
        superview.frame.origin = CGPoint(x: Constants.defaultFrameSize.width, y: Constants.defaultFrameSize.height)
        XCTAssertFalse(view.isVisible)
    }
    
    /// Validates use case where the super view does not intersect the window, but the view does.
    func testSuperviewDoesNotIntersectWindowButViewDoes() {
        // Even though the view is not within the bounds of the superview,
        // the view is still 100% within the bounds of the window.
        superview.frame.origin = CGPoint(x: Constants.defaultFrameSize.width, y: Constants.defaultFrameSize.height)
        view.frame.origin = CGPoint(x: -Constants.defaultFrameSize.width, y: -Constants.defaultFrameSize.height)
        XCTAssertTrue(view.isVisible)
    }
    
    /// Validate view is visible even if the window is not at the normal (0, 0) origin.
    func testWindowNotAtOrigin() {
        // Even if the window is not at the origin, the view should still
        // be contained 100% within the window.
        window.frame.origin = CGPoint(x: Constants.defaultFrameSize.width * 2, y: Constants.defaultFrameSize.height * 2)
        XCTAssertTrue(view.isVisible)
    }
    
    // MARK: - Zero Area Tests
    
    /// Validate views with zero area.
    func testViewWithNoArea() {
        // The view technically intersects, but should have no visible points.
        view.frame = .zero
        XCTAssertTrue(view.isVisible)
        XCTAssertFalse(view.isVisible(minimumVisiblePoints: 1))
    }
    
    /// Validate superview with zero area.
    func testSuperviewWithNoArea() {
        // Even though the view is clipped by its superview, the view is
        // still 100% within the window.
        superview.frame = .zero
        XCTAssertTrue(view.isVisible)
    }
    
    ///  Validate window with zero area.
    func testWindowWithNoArea() {
        // The view technically intersects, but should have no visible points.
        window.frame = .zero
        XCTAssertTrue(view.isVisible)
        XCTAssertFalse(view.isVisible(minimumVisiblePoints: 1))
    }
    
    // MARK: - Hidden View Tests
    
    /// Validate hidden view is not visible.
    func testHiddenView() {
        view.isHidden = true
        XCTAssertFalse(view.isVisible)
    }
    
    /// Validate hidden super view is not visible.
    func testViewWithHiddenSuperview() {
        superview.isHidden = true
        XCTAssertFalse(view.isVisible)
    }
    
    // MARK: - Missing View Tests
    
    /// Validate view with no superview is not visible.
    func testViewWithoutSuperview() {
        view.removeFromSuperview()
        XCTAssertFalse(view.isVisible)
    }
    
    /// Validate view with no window is not visible.
    func testViewWithoutWindow() {
        superview.removeFromSuperview()
        XCTAssertFalse(view.isVisible)
    }
    
    // MARK: - Out of Range Tests
    
    /// Validate that specifying points < 0 is visible.
    func testPointsLessThanZero() {
        // -1 points will clamp to 0 points, so the view should be visible.
        let result = view.isVisible(minimumVisiblePoints:-1)
        XCTAssertTrue(result)
    }
    
    /// Validate that specifying more minimum points than there is area will not be visible.
    func testPointsGreaterThanNumberOfPointsInView() {
        // If we pass in more points than are in the view, it is not visible.
        let points = Constants.defaultFrameSize.width * Constants.defaultFrameSize.height + 1
        XCTAssertFalse(view.isVisible(minimumVisiblePoints: points))
    }
}
