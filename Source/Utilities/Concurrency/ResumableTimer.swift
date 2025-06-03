// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// `ResumableTimer` is a thread safe wrapper for `Timer`, with pause and resume functionality.
final class ResumableTimer {
    // MARK: - Timer State Enumeration

    /// Timer state
    enum State: Equatable {
        /// Timer is active.
        case active

        /// Timer has fired or has been invalidated, and is no longer able to be scheduled.
        case complete

        /// Timer is paused, with the associated value indicating the remaining time left in seconds.
        case paused(remaining: TimeInterval)

        /// Timer is ready to be scheduled.
        case ready
    }

    // MARK: - Properties

    /// Initial time interval in seconds.
    private let interval: TimeInterval

    /// Indicates whether the timer is repeating or single-use.
    private let isRepeating: Bool

    /// Queue used to synchronize access to `timer` since it is not thread-safe.
    /// This will allow concurrent reads, but synchronous writes.
    private let synchronizationQueue = DispatchQueue(label: "com.chartboost.mediation.resumabletimer.queue", attributes: .concurrent)

    /// Underlying timer.
    /// - Note: This timer is optional so that it can be set to `nil` which will guarantee that it is removed from the main run loop.
    private var timer: Timer?

    /// Closure that is invoked when the timer fires.
    private var timerClosure: ((ResumableTimer) -> Void)?

    /// Current state of the timer that needs to be synchronized by `synchronizationQueue`.
    private(set) var timerState: State = .ready

    // MARK: - Computed Properties

    /// A Boolean value that indicates whether the timer is currently valid.
    var isValid: Bool {
        synchronizationQueue.sync {
            // When the current state is not `complete`, the timer is considered valid.
            guard case .complete = state else { return true }
            return false
        }
    }

    /// Current state of the timer.
    var state: State {
        synchronizationQueue.sync {
            return timerState
        }
    }

    // MARK: - Initialization

    /// Initializes the timer.
    /// - Parameter timerInterval: The number of seconds between firings of the timer. If seconds is less than or equal to 0.0, this method
    /// chooses the nonnegative value of 0.1 milliseconds instead.
    /// - Parameter repeats: If `true`, the timer will repeatedly reschedule itself until invalidated. If `false`, the timer will be
    /// invalidated after it fires. The default is `false`
    /// - Parameter runLoopMode: The run loop mode that the timer will run on. The default mode is `RunLoop.Mode.common`.
    /// - Parameter closure: The execution body of the timer; the timer itself is passed as the parameter to this closure when executed to
    /// aid in avoiding cyclical references.
    /// - Returns: An initialized timer.
    required init(
        interval timerInterval: TimeInterval,
        repeats: Bool = false,
        runLoopMode: RunLoop.Mode = .common,
        closure: @escaping (ResumableTimer) -> Void
    ) {
        // Initialize immutable internal state
        interval = timerInterval
        isRepeating = repeats
        timerClosure = closure

        // Initialize time timer if able to. This requires at least iOS 10.
        timer = Timer(fire: .distantFuture, interval: timerInterval, repeats: repeats) { [weak self] _ in
            // Obtain strong reference to self, otherwise don't bother.
            guard let self else { return }

            // Copy timer closure since it may be nilled out in the invalidate() call below
            let timerClosure = self.timerClosure

            // This is the last block to fire.
            if !self.isRepeating {
                self.invalidate()
            }

            // Forward the callback along
            timerClosure?(self)
        }

        // Runloop scheduling must be performed on the main thread. To prevent
        // a potential deadlock, scheduling to the main thread will be asynchronous
        // on the next main thread run loop.
        let mainThreadOperation: () -> Void = { [weak self] in
            // Obtain strong reference to self, otherwise don't bother.
            guard let self else { return }

            // Guard against the situation possible where the timer is created
            // on a background thread, the runloop scheduling block is then scheduled
            // to run on main thread, but before the block can process, a timer
            // invalidation event occurs which invalidates the underlying
            // `Timer` and set it to `nil`.
            guard let timer = self.timer else { return }

            RunLoop.main.add(timer, forMode: runLoopMode)
        }

        // Already on main thread, safe to invoke the scheduling operation.
        if Thread.isMainThread {
            mainThreadOperation()
        }
        // Dispatch to the main thread for processing.
        else {
            DispatchQueue.main.async { mainThreadOperation() }
        }
    }

    // MARK: - Timer Methods

    /// Stops the timer from ever firing again and requests its removal from its run loop.
    /// - Note: This method will always be run on the main thread to safely remove
    /// the internal timer from the run loop.
    func invalidate() {
        // Runloop removal must be performed on the main thread since it was added
        // on the main thread.
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.invalidate() }
            return
        }

        synchronizationQueue.sync(flags: .barrier) {
            // Explicitly invalidate and `nil` out the internal timer to ensure
            // that it is removed from the main run loop and can never be restarted.
            self.timer?.invalidate()
            self.timer = nil

            // Nil out closure to avoid unnecessarily retaining captured variables
            self.timerClosure = nil

            // Update the internal state to complete.
            self.timerState = .complete
        }
    }

    /// Pauses the timer if active.
    func pause() {
        synchronizationQueue.sync(flags: .barrier) {
            // Validate that timer exists, is valid, and countdown is active.
            // Do not use `self.state` since `synchronizationQueue` is not re-entrant.
            guard let timer = self.timer, timer.isValid == true,
                  case .active = self.timerState else {
                return
            }

            // `fireDate` is the date which the timer will fire. If the timer is no longer valid, `fireDate`
            // is the last date at which the timer fired.
            let secondsLeft = max(timer.fireDate.timeIntervalSinceNow, 0)

            // Pause the timer by setting its fire date far into the future.
            timer.fireDate = .distantFuture
            self.timerState = .paused(remaining: secondsLeft)
        }
    }

    /// Schedules the timer to start with the remaining time interval.
    /// - Note: Call this method to start or resume the timer.
    func scheduleNow() {
        synchronizationQueue.sync(flags: .barrier) {
            // Need a valid timer that is not currently active before continuing to schedule.
            guard let strongTimer = self.timer else { return }

            // Determine the new fire date for the timer using the existing
            // value as the current fire date.
            var fireDate: Date = strongTimer.fireDate

            // Do not use `self.state` since `synchronizationQueue` is not re-entrant.
            switch self.timerState {
            case .paused(let remaining):
                fireDate = Date(timeIntervalSinceNow: remaining)
            case .ready:
                fireDate = Date(timeIntervalSinceNow: self.interval)
            default:
                // Timer is already active or completed, do not schedule.
                return
            }

            // Schedule now.
            strongTimer.fireDate = fireDate
            self.timerState = .active
        }
    }
}
