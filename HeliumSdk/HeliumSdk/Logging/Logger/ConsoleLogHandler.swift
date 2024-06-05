// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import os.log

/// Override value of console logger configuration.
protocol ConsoleLoggerConfigurationOverride {
    var logLevel: LogLevel? { get }
}

/// A `LogHandler` that logs to the console. On iOS 12 and later, logging is performed using `os_log`, otherwise it uses `print`.
final class ConsoleLogHandler: LogHandler {
    /// The desired log level.
    @Atomic static var logLevel: LogLevel = .info

    /// Handle a `LogEntry` if the log level is sufficient for the desired output log level.
    /// On iOS 12 and later, logging is performed using `os_log`, otherwise no logging of any kind occurs.
    func handle(_ entry: LogEntry) {
        guard #available(iOS 12, *) else {
            return
        }
        guard actualLogLevel >= entry.logLevel else {
            return
        }
        guard let type = entry.logLevel.asOSLogType else {
            return
        }
        let log = OSLog(subsystem: entry.subsystem, category: entry.category)
        os_log(type, log: log, "%{public}s", entry.message)
    }

    // MARK: - Private

    @Injected(\.consoleLoggerConfigurationOverride) private var configurationOverride

    private var actualLogLevel: LogLevel {
        if let logLevelOverride = configurationOverride.logLevel {
            // The app configuration can provide a log level in order to override the value for
            // production apps using network re-writing for field debugging purposes.
            return logLevelOverride
        } else {
            return Self.logLevel
        }
    }
}

extension LogLevel {
    /// Maps `LogLevel` to an appropriate `OSLogType`.
    fileprivate var asOSLogType: OSLogType? {
        switch self {
        case .none:
            return nil
        case .verbose, .trace, .debug:
            // Use this level to capture information that may be useful during development or while
            // troubleshooting a specific problem.
            return .debug
        case .info:
            // Use this level to capture information that may be helpful, but not essential, for
            // troubleshooting errors.
            return .info
        case .warning:
            // Use this level to capture information about things that might result in a failure.
            return .default
        case .error:
            // Use this log level to report process-level errors.
            return .error
        }
    }
}
