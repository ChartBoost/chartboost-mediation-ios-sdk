// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class LogCaptureHandler: LogHandler {
    var didReceiveEntry: ((LogEntry?) -> Void)?

    @Atomic var lastEntry: LogEntry? {
        didSet {
            didReceiveEntry?(lastEntry)
        }
    }

    func handle(_ entry: LogEntry) {
        lastEntry = entry
    }

    func clear() {
        lastEntry = nil
    }
}
