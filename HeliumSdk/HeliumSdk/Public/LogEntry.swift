// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// An object containing information about a single log message.
///
/// For every log message emitted by the SDK, ``LogHandler/handle(_:)`` will be called on all handlers that have been
/// registered with ``Helium/attachLogHandler(_:)``.
@objc(ChartboostMediationLogEntry)
final public class LogEntry: NSObject {
    /// The message content of the log.
    @objc public let message: String
    /// A subsystem for the log.
    ///
    /// This value is used as the subsystem for `OSLog(subsystem:category:)` on iOS 12+.
    @objc public let subsystem: String
    /// The category for the log.
    ///
    /// This value is used as the category for `OSLog(subsystem:category:)` on iOS 12+. It is also included with the ouput
    /// within the brackets that prepend the message. For example: "[CM] initialization has completed"
    @objc public let category: String
    /// The date that this log entry was created.
    @objc public let date: Date
    /// The log level for this entry.
    @objc public let logLevel: LogLevel

    /// Initializer.
    init(message: String, subsystem: String, category: String, logLevel: LogLevel) {
        self.message = message
        self.subsystem = subsystem
        self.category = category
        self.date = Date()
        self.logLevel = logLevel
    }
}
