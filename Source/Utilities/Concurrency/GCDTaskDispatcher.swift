// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A GCD-backed TaskDispatcher implementation.
/// It uses the main DispatchQueue to perform work on the main queue.
/// It uses a background DispatchQueue passed on init to perform work on the background.
final class GCDTaskDispatcher: TaskDispatcher {
    private let mainQueue = DispatchQueue.main
    private let backgroundQueue: DispatchQueue

    init(backgroundQueue: DispatchQueue) {
        self.backgroundQueue = backgroundQueue
    }

    func sync<T>(
        on queue: TaskDispatcherQueue,
        flags: Set<TaskDispatcherExecutionFlag>,
        execute work: @escaping () throws -> T
    ) rethrows -> T {
        try dispatchQueue(for: queue).sync(flags: workItemFlags(for: flags), execute: work)
    }

    func async(
        on queue: TaskDispatcherQueue,
        flags: Set<TaskDispatcherExecutionFlag>,
        execute work: @escaping () -> Void
    ) {
        dispatchQueue(for: queue).async(flags: workItemFlags(for: flags), execute: work)
    }

    func async(
        on queue: TaskDispatcherQueue,
        after delay: TimeInterval,
        execute work: @escaping () -> Void
    ) {
        dispatchQueue(for: queue).asyncAfter(deadline: .now() + delay, execute: work)
    }

    func async(
        on queue: TaskDispatcherQueue,
        delay: TimeInterval,
        repeat repeats: Bool,
        execute work: @escaping () -> Void
    ) -> DispatchTask {
        let queue = dispatchQueue(for: queue)
        let timer = ResumableTimer(interval: delay, repeats: repeats) { _ in
            queue.async(execute: work)
        }
        let task = TimerDispatchTask(timer: timer)
        timer.scheduleNow()
        return task
    }

    func group(on queue: TaskDispatcherQueue) -> DispatchTaskGroup {
        GCDTaskGroup(queue: dispatchQueue(for: queue))
    }

    private func dispatchQueue(for queue: TaskDispatcherQueue) -> DispatchQueue {
        switch queue {
        case .main: return mainQueue
        case .background: return backgroundQueue
        }
    }

    private func workItemFlags(for flags: Set<TaskDispatcherExecutionFlag>) -> DispatchWorkItemFlags {
        flags.contains(.barrier) ? .barrier : []
    }
}

// Convenience factory method

extension TaskDispatcher where Self == GCDTaskDispatcher {
    static func serialBackgroundQueue(name: String) -> Self {
        GCDTaskDispatcher(backgroundQueue: DispatchQueue(label: "com.chartboost.mediation.\(name)"))
    }
}
