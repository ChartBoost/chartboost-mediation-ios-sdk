// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A asynchronous task dispatched with a task dispatcher.
/// Backed by a ResumableTimer, it is thread-safe and can be canceled, resumed and paused.
final class TimerDispatchTask: DispatchTask {
    /// The current state of the task.
    var state: DispatchTaskState {
        switch timer.timerState {
        case .active, .ready: return .active    // timers are scheduled immediately when created by DefaultTaskDispatcher
        case .complete: return .complete
        case .paused: return .paused
        }
    }
    /// The remaining time for a paused task, 0 otherwise.
    var remainingTime: TimeInterval {
        if case .paused(let time) = timer.timerState {
            return time
        } else {
            return 0
        }
    }
    /// The backing timer that provides all the logic. This class is thread-safe because ResumableTimer is thread-safe.
    private let timer: ResumableTimer

    init(timer: ResumableTimer) {
        self.timer = timer
    }

    func cancel() {
        timer.invalidate()
    }

    func pause() {
        timer.pause()
    }

    func resume() {
        timer.scheduleNow()
    }
}
