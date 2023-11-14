// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// The unified logging subystem.  The console handler is attached by default.
final class Logger {
    /// The default logger.
    static let `default` = Logger()

    /// Initializer.
    /// - Parameter subsystem: A subsystem for the log.  This value is used as the subsystem for `OSLog(subsystem:category:)` on iOS 12+.  The default is `com.chartboost.mediation.sdk`.
    /// - Parameter category: The category for the log. This value is used as the category for `OSLog(subsystem:category:)` on iOS 12+. It is also included with the ouput within the brackets that prepend the message.  The default is "CM"; if one is provided it is appended to "CM-".
    init(subsystem: String? = nil, category: String? = nil) {
        self.subsystem = subsystem ?? defaultSubsystem
        if let category = category {
            self.category = "\(baseCategory) - \(category)"
        } else {
            self.category = baseCategory
        }
    }

    /// Attach a custom logger handler to the logging system. The console handler is attached by default.
    /// - Parameter handler: A custom class that conforms to the `LogHandler` protocol.
    class func attachHandler(_ handler: LogHandler) {
        $handlers.mutate { handlers in
            guard !handlers.contains(where: { handler === $0 }) else {
                return
            }
            handlers.append(handler)
        }
    }

    /// Detatch a custom logger handler to the logging system.
    /// - Parameter handler: A custom class that conforms to the `LogHandler` protocol.
    class func detachHandler(_ handler: LogHandler) {
        $handlers.mutate { handlers in
            guard let index = handlers.firstIndex(where: { handler === $0 }) else {
                return
            }
            handlers.remove(at: index)
        }
    }

    /// Log a message to all of the attached handlers.
    /// - Parameter message: The logged message.
    /// - Parameter level: The level of the log message.
    func log(_ message: String, level: LogLevel) {
        let entry = LogEntry(message: message, subsystem: subsystem, category: category, logLevel: level)
        Self.$handlers.mutate { handlers in
            handlers.forEach { handler in
                logHandleQueue.async {
                    handler.handle(entry)
                }
            }
        }
    }

    /// Log a message to all of the attached handlers at log severity level `trace`.
    /// - Parameter message: The logged message.
    func trace(_ message: String) {
        log(message, level: .trace)
    }

    /// Log a message to all of the attached handlers at log severity level `debug`.
    /// - Parameter message: The logged message.
    func debug(_ message: String) {
        log(message, level: .debug)
    }

    /// Log a message to all of the attached handlers at log severity level `info`.
    /// - Parameter message: The logged message.
    func info(_ message: String) {
        log(message, level: .info)
    }

    /// Log a message to all of the attached handlers at log severity level `warning`.
    /// - Parameter message: The logged message.
    func warning(_ message: String) {
        log(message, level: .warning)
    }

    /// Log a message to all of the attached handlers at log severity level `error`.
    /// - Parameter message: The logged message.
    func error(_ message: String) {
        log(message, level: .error)
    }

    // MARK: - Private

    private let logHandleQueue = DispatchQueue(label: "com.chartboost.mediation.sdk.logger-handler")
    @Atomic private static var handlers: [LogHandler] = [ConsoleLoggerHandler()]
    private let defaultSubsystem = "com.chartboost.mediation.sdk"
    private let baseCategory = "Chartboost Mediation"
    private let subsystem: String
    private let category: String
}

/// A global logger instance for convenience.
let logger = Logger.default
