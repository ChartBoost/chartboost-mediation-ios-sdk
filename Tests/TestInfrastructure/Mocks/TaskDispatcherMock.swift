// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

// This mock cannot be auto-generated because of its custom mechanism to execute tasks immediately.
class TaskDispatcherMock: Mock<TaskDispatcherMock.Method>, TaskDispatcher {
    
    enum Method {
        case sync
        case async
        case asyncDelayed
        case group
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.asyncDelayed: DispatchTaskMock(),
         .group: DispatchTaskGroupMock()]
    }
    
    var returnTask: DispatchTaskMock {
        get { returnValue(for: .asyncDelayed) }
        set { setReturnValue(newValue, for: .asyncDelayed) }
    }
    
    var returnGroup: DispatchTaskGroupMock {
        returnValue(for: .group)
    }
    
    var executesNonDelayedWorkImmediately = true
    var executesDelayedWorkImmediately = false
    var recordsNonDelayedDispatchMethods = false
    var nonDelayedWorkItems: [() -> Void] = []
    var delayedWorkItems: [() -> Void] = []
    
    func performDelayedWorkItems() {
        let items = delayedWorkItems
        delayedWorkItems = []
        for item in items {
           item()
        }
    }
    
    func sync<T>(on queue: TaskDispatcherQueue, flags: Set<TaskDispatcherExecutionFlag>, execute work: @escaping () throws -> T) rethrows -> T {
        if recordsNonDelayedDispatchMethods {
            record(.sync, parameters: [queue, flags])
        }
        return try work()
    }
    
    func async(on queue: TaskDispatcherQueue, flags: Set<TaskDispatcherExecutionFlag>, execute work: @escaping () -> Void) {
        if recordsNonDelayedDispatchMethods {
            record(.async, parameters: [queue, flags])
        }
        if executesNonDelayedWorkImmediately {
            work()
        } else {
            nonDelayedWorkItems.append(work)
        }
    }
    
    func async(on queue: TaskDispatcherQueue, after delay: TimeInterval, execute work: @escaping () -> Void) {
        record(.asyncDelayed, parameters: [queue, delay])
        if executesDelayedWorkImmediately {
            work()
        } else {
            delayedWorkItems.append(work)
        }
    }
    
    func async(on queue: TaskDispatcherQueue, delay: TimeInterval, repeat repeats: Bool, execute work: @escaping () -> Void) -> DispatchTask {
        record(.asyncDelayed, parameters: [queue, delay, repeats])
        if executesDelayedWorkImmediately {
            work()
        } else {
            delayedWorkItems.append(work)
        }
        return returnTask
    }
    
    func group(on queue: TaskDispatcherQueue) -> DispatchTaskGroup {
        record(.group, parameters: [queue])
    }
}
