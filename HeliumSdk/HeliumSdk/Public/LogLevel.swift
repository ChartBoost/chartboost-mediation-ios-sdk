// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import os.log

/// Log severity levels for the unified logging subsystem.
@objc(ChartboostMediationLogLevel)
public enum LogLevel: Int, Codable {
    /// No logging is expected to be performed.
    case none

    /// Log information that communicates an error.
    case error

    /// Log information that may result in a failure.
    case warning

    /// Log helpful, non-essential information.
    case info

    /// Log information that may be useful during development or troubleshooting.
    case debug

    /// Deprecated. 
    /// Log very low level and/or noisy information that may be useful during development or troubleshooting.
    @available(*, deprecated, message: "Use `.verbose` instead")
    case trace

    /// Log very low level and/or noisy information that may be useful during development or troubleshooting.
    case verbose
}

extension LogLevel: Comparable {
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
