// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK

/// Console log handler configuration.
protocol MediationConsoleLogHandlerConfiguration {
    var logLevelOverride: LogLevel? { get }
}

/// A custom log handler that handles log level overrides from backend.
class MediationConsoleLogHandler: ConsoleLogHandler {
    @Injected(\.consoleLogHandlerConfiguration) private var configuration

    @Atomic var clientSideLogLevel: LogLevel = .info

    // This is the logLevel property used by the superclass.
    override var logLevel: LogLevel {
        get {
            // The app configuration can provide a log level in order to override the value for
            // production apps using network re-writing for field debugging purposes.
            configuration.logLevelOverride ?? clientSideLogLevel
        }
        set {
            assertionFailure("Set the clientSideLogLevel instead.")
            clientSideLogLevel = newValue
        }
    }
}
