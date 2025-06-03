// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// The type of queue to dispatch a task on with a task dispatcher.
enum TaskDispatcherQueue: Int {
    /// The main queue.
    case main
    /// A background queue. It may be serial or concurrent, depending on the task dispatcher implementation.
    case background
}

/// Flags for extra configuration when dispatching a task on with a task dispatcher.
/// An enum just because it's easier than exposing an OptionSet class to Obj-C at this moment. We should reconsider this decision if in the
/// future we need a combination of flags.
enum TaskDispatcherExecutionFlag: Int {
    /// If used on a concurrent queue this acts as a barrier. Has no effect on serial queues. Corresponds to DispatchWorkItemFlags.barrier.
    case barrier
}

/// The state of a DispatchTask.
enum DispatchTaskState {
    /// Task is has been dispatched and it's execution is not done.
    case active
    /// Task has been executed or has been cancelled, and is no longer able to be resumed.
    case complete
    /// Task is paused. Applies only to delayed tasks.
    case paused
}

/// A asynchronous task dispatched with a task dispatcher. It is thread-safe and can be canceled, resumed and paused.
protocol DispatchTask {
    /// The current state of the task.
    var state: DispatchTaskState { get }
    /// The remaining time for a paused task, 0 otherwise.
    var remainingTime: TimeInterval { get }
    /// Cancels a task so it is never performed. Calls on an already-executed or already-canceled tasks do nothing.
    func cancel()
    /// Pauses a task so it doesn't get executed until resumed.
    func pause()
    /// Resumes a paused task so it gets executed after the remaining time interval.
    func resume()
}

/// A group of tasks that notifies the user when all of them have completed.
protocol DispatchTaskGroup {
    /// Adds a task to the group.
    /// - important: The passed closure should call the `finished` completion whenever it is done.
    /// Any task added after the `onAllFinished` completion has been executed will be ignored.
    func add(_ task: @escaping (_ finished: @escaping () -> Void) -> Void)
    /// Sets the completion handler to be called by the group when all its tasks are finished or after a specified timeout interval.
    func onAllFinished(timeout: TimeInterval, execute finished: @escaping () -> Void)
}

/// A task dispatcher takes care of executing code on different threads asynchronously, optionally with a delay and repetition.
/// It is intended to replace direct uses of DispatchQueue and NSTimer.
/// It provides a unified and simplified concurrency solution which can be easily mocked, avoiding cumbersome asynchronous code in unit
/// tests and allowing them to run SDK code synchronously and fast. Note in order to dispatch code synchronously you will need to use
/// `TaskDispatcher`. `AsynchronousTaskDispatcher` is intentionally limited to only async operations so it can be safely used by
/// multiple components without the risk of causing deadlocks.
protocol AsynchronousTaskDispatcher {
    /// Executes code asynchronously on the chosen queue. Use this instead of DispatchQueue.async()
    func async(
        on queue: TaskDispatcherQueue,
        flags: Set<TaskDispatcherExecutionFlag>,
        execute work: @escaping () -> Void
    )
    /// Executes code with a delay on the chosen queue. Use this instead of DispatchQueue.asyncAfter()
    func async(
        on queue: TaskDispatcherQueue,
        after delay: TimeInterval,
        execute work: @escaping () -> Void
    )
    /// Executes code with a delay on the chosen queue. Returns a cancellable task. Use this instead of NSTimer.
    func async(
        on queue: TaskDispatcherQueue,
        delay: TimeInterval,
        repeat: Bool,
        execute work: @escaping () -> Void
    ) -> DispatchTask
    /// Creates a task group that executes its added tasks in the indicated queue.
    func group(on queue: TaskDispatcherQueue) -> DispatchTaskGroup
}

/// A task dispatcher takes care of executing code on different threads, synchronously or asynchronously, optionally with a delay and
/// repetition. It is intended to replace direct uses of DispatchQueue and NSTimer.
/// It provides a unified and simplified concurrency solution which can be easily mocked, avoiding cumbersome asynchronous code in unit
/// tests and allowing them to run SDK code synchronously and fast.
/// - warning: Programmers beware that dispatching code synchronously can lead to deadlocks when doing so from and to the same queue.
/// For safety, always use `AsynchronousTaskDispatcher` when possible, and be mindful when using `TaskDispatcher`: do not reuse instances
/// on multiple classes, and make sure that no recursive calls to `sync(on:flags:execute:)` can happen within that class.
protocol TaskDispatcher: AsynchronousTaskDispatcher {
    /// Executes code synchronously on the chosen queue. Use this instead of DispatchQueue.sync()
    func sync<T>(
        on queue: TaskDispatcherQueue,
        flags: Set<TaskDispatcherExecutionFlag>,
        execute work: @escaping () throws -> T
    ) rethrows -> T
}

// Extension that provides a default implementation with default values for some parameters.
extension AsynchronousTaskDispatcher {
    func async(on queue: TaskDispatcherQueue, execute work: @escaping () -> Void) {
        async(on: queue, flags: [], execute: work)
    }

    func async(on queue: TaskDispatcherQueue, delay: TimeInterval, execute work: @escaping () -> Void) -> DispatchTask {
        async(on: queue, delay: delay, repeat: false, execute: work)
    }
}

// Extension that provides a default implementation with default values for some parameters.
extension TaskDispatcher {
    func sync<T>(on queue: TaskDispatcherQueue, execute work: @escaping () throws -> T) rethrows -> T {
        try sync(on: queue, flags: [], execute: work)
    }
}
