// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class DispatchTaskGroupMock: DispatchTaskGroup {
    
    var executesAddedTasksImmediately = true
    var addedTasks: [(@escaping () -> Void) -> Void] = []
    var executedFinishedCompletionImmediately = true
    var finishedCompletion: () -> Void = {}
    var finishTimeout: TimeInterval?
    
    func add(_ task: @escaping (@escaping () -> Void) -> Void) {
        if executesAddedTasksImmediately {
            task({})
        } else {
            addedTasks.append(task)
        }
    }
    
    func onAllFinished(timeout: TimeInterval, execute finished: @escaping () -> Void) {
        finishTimeout = timeout
        if executedFinishedCompletionImmediately {
            finished()
        } else {
            finishedCompletion = finished
        }
    }
}
