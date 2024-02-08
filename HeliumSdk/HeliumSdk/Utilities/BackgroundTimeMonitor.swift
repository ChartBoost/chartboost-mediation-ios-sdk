// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A protocol to define the means of providing a new instance of a `BackgroundTimeMonitorOperation`.
protocol BackgroundTimeMonitoring {
    func startMonitoringOperation() -> BackgroundTimeMonitorOperator
}

/// An implementation of `BackgroundTimeMonitoring`
class BackgroundTimeMonitor: BackgroundTimeMonitoring {
    func startMonitoringOperation() -> BackgroundTimeMonitorOperator {
        BackgroundTimeMonitorOperation()
    }
}
