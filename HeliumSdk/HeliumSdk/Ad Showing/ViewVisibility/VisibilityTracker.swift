// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import UIKit

/// Tracks the visibility of an inputted view and invokes the block when the specified visibility conditions
/// for the view have been met.
/// - Note: Use this tracker for Helium impression tracking.
protocol VisibilityTracker {
    /// Indicates if a tracking operation is ongoing.
    /// `true` after startTracking() is called, `false` after the operation finishes due to the view becoming visible
    /// or due to the stopTracking() method getting called.
    var isTracking: Bool { get }
    /// Starts tracking the visibility of the `view`.
    /// If the tracker is already in the process of tracking a view, this method will do nothing.
    /// - Parameter view: The view to track.
    /// - Parameter completion: Completion block that is invoked when the tracked view has met the minimum visibility conditions.
    func startTracking(_ view: UIView, completion: @escaping () -> Void)
    /// Stops tracking the `view`.
    func stopTracking()
}

/// Configuration settings for VisibilityTracker.
protocol VisibilityTrackerConfiguration {
    /// The minimum amount of time (in seconds) the `view` is required to be visible on screen. Values less than 0 will be set to 0.
    var minimumVisibleSeconds: TimeInterval { get }

    /// The minimum number of device independent pixels the `view` is required to be visible on screen. Values less than 0 will be set to 0.
    var minimumVisiblePoints: CGFloat { get }

    /// The amount of time (in seconds) to continuously check for visibility.
    var pollInterval: TimeInterval { get }

    /// The maximum depth to traverse the view hiearchy when checking for visibility.
    var traversalLimit: UInt { get }
}

final class PixelByTimeVisibilityTracker: VisibilityTracker {
    
    // MARK: - Properties
    
    /// Application intformation provider.
    private let app: Application
    
    /// Completion block to fire once the visibility conditions have been met.
    private var completion: (() -> Void)?
    
    /// The timestamp that the `view` was first visible, or `nil` if `view` is not visible.
    private var firstVisibleTimestamp: TimeInterval? = nil

    /// Configuration settings for the visibility tracker.
    private let configuration: VisibilityTrackerConfiguration

    /// Backing timer used to poll the visibility of the view.
    private var timer: ResumableTimer? = nil
    
    /// The view for which visibility is being tracked.
    private weak var view: UIView? = nil
    
    /// Indicates if a tracking operation is ongoing.
    var isTracking: Bool {
        timer?.state == .active
    }
    
    // MARK: - Initialization
    
    /// Initializes an object that tracks the visibility of a view with the specified mimum visibility requirements.
    /// - Parameter configuration: Configurartion settings for the visibility tracker.
    /// - Parameter app: Optional dependency injected application state. By default, this value is `UIApplication.shared`.
    init(configuration: VisibilityTrackerConfiguration, app: Application = UIApplication.shared) {
        // Initialize immutable properties
        self.configuration = configuration
        self.app = app
    }
        
    deinit {
        // Explicitly stop tracking on deallocation as a preventative measure
        // against edge conditions where internal state cleanup of this object
        // is delayed when the timer is about to fire.
        view = nil
        stopTracking()
    }
    
    // MARK: - Tracker Manipulation
    
    /// Starts tracking the visibility of the `view`.
    /// If the tracker is already in the process of tracking a view, this method will do nothing.
    /// - Parameter view: The view to track.
    /// - Parameter completion: Completion block that is invoked when the tracked view has met the minimum visibility conditions.
    func startTracking(_ view: UIView, completion: @escaping () -> Void) {
        // Ensure that the timer isn't currently allocated and tracking another view.
        guard timer == nil else { return }
        
        // Keep the completion block for later execution.
        self.completion = completion
        
        // Initialize the polling timer used to track the visibility of the view.
        timer = ResumableTimer(interval: configuration.pollInterval, repeats: true) { [weak self] _ in
            self?.checkViewVisibility()
        }
        
        // Capture the view to track.
        self.view = view
        
        // Start tracking immediately.
        timer?.scheduleNow()
    }
    
    /// Stops tracking the `view`.
    func stopTracking() {
        firstVisibleTimestamp = nil
        view = nil
        
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Visibility Verification
    
    /// Checks the `view`'s current visibility status.
    /// If the `view` has met the minimum visibility conditions, the `completion` block will be invoked
    /// and the timer will be invalidated.
    private func checkViewVisibility() {
        // If the view becomes `nil`, invalidate the timer since there is nothing
        // to track anymore.
        guard let view = view else {
            stopTracking()
            return
        }
        
        // Reset the visibility timestamp if the view goes from visible
        // to not visible while tracking.
        let isViewVisible = view.isVisible(minimumVisiblePoints: configuration.minimumVisiblePoints, maximumDepth: configuration.traversalLimit)
        guard isViewVisible && app.state == .active else {
            firstVisibleTimestamp = nil
            return
        }
        
        // Capture the current timestamp.
        let now = Date().timeIntervalSinceReferenceDate
        
        // Set the timestamp if this is the first tick that this view is visible.
        // If this is the first time the tracker is checking visibility, capture
        // the timestamp and move on.
        guard let timestamp = firstVisibleTimestamp else {
            firstVisibleTimestamp = now
            return
        }
        
        // Once the view has been visible for `minimumVisibleSeconds`,
        // call our completion block.
        if now - timestamp >= configuration.minimumVisibleSeconds {
            notifyCompletion()
        }
    }
    
    /// Trigger the stored `completion` block and stops tracking the view.
    private func notifyCompletion() {
        // Ensure the timer is still active when we fire. After we fire
        // once, the timer is invalidated, and so any subsequent calls to
        // fire will be no-ops.
        guard let timer = timer, case .active = timer.state else {
            return
        }
        
        // Stop tracking now so there will not be subquent calls to
        // this method.
        stopTracking()
        
        // Notify the completion handler.
        completion?()
    }
}
