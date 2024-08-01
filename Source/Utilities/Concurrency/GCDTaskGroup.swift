// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A `DispatchTaskGroup` implementation using GCD's DispatchGroup.
final class GCDTaskGroup: DispatchTaskGroup {
    /// The backing GCD DispatchGroup that does all the work.
    private let group = DispatchGroup()
    /// The closure to execute when all the group tasks have finished.
    /// Nil when the `onAllFinished()` completion has been called.
    /// Empty closure as initial value to differentiate from the final state where it is set to nil.
    private var allFinishedCompletion: (() -> Void)? = {}
    /// The dispatch queue to execute tasks on.
    private let queue: DispatchQueue

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    func add(_ task: @escaping (@escaping () -> Void) -> Void) {
        queue.async { [self] in
            // Return early if already finished
            guard allFinishedCompletion != nil else { return }
            // Start task
            group.enter()
            task { [weak self] in    // this closure is called by task when it decides it is finished
                guard self?.allFinishedCompletion != nil else { return }
                // Finish task
                self?.group.leave()
            }
        }
    }

    func onAllFinished(timeout: TimeInterval, execute finished: @escaping () -> Void) {
        // Completion where we don't strongly capture neither self nor the `finished` completion.
        // This is the completion passed in the call to dispatch group notify(), where strongly capturing things causes weird issues where
        // the dispatch group won't stop retaining the completion even after executing it and the group itself being deallocated.
        let completion = { [weak self] in
            guard self?.allFinishedCompletion != nil else { return }
            self?.allFinishedCompletion?()
            self?.allFinishedCompletion = nil   // marks the task group as finished
        }
        // Completion where we retain self (the GCDTaskGroup) until it is executed.
        // This means we don't need to retain the GCDTaskGroup on the caller side, we can trust that it will remain alive for as long as
        // it is needed.
        let completionRetainingSelf = { [self] in
            _ = self    // dumb statement just to explicitly capture self in the closure capture group without warnings
            completion()
        }
        // dispatch on queue so tasks previously added can be processed before we call group.notify()
        queue.async { [self] in
            // Return early if already finished
            guard self.allFinishedCompletion != nil else { return }
            // Save the finished completion to be called later
            self.allFinishedCompletion = finished
            // We set both a group finish notification and a timeout task and let whichever finishes first execute `finished`
            // Note we only strongly capture the task group instance in the timeout task completion.
            group.notify(queue: queue, execute: completion) // fires if all tasks complete
            queue.asyncAfter(deadline: .now() + timeout, execute: completionRetainingSelf)    // fires after a timeout interval
        }
    }
}
