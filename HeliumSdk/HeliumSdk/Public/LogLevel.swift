// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import os.log

/// Log severity levels for the unified logging subsystem.
@objc(ChartboostMediationLogLevel)
public enum LogLevel: Int, Codable {
    /// Log very low level and/or noisy information that may be useful during development or troubleshooting.
    case trace
    /// Log information that may be useful during development or troubleshooting.
    case debug
    /// Log helpful, non-essential information.
    case info
    /// Log information that may result in a failure.
    case warning
    /// Log information that communicates an error.
    case error
    /// No logging is expected to be performed.
    case none
}

extension LogLevel: Comparable {
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
