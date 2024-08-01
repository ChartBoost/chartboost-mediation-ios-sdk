// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK

extension ConsoleLogHandler {
    /// The internal console log handler for the Mediation SDK.
    static let mediation = MediationConsoleLogHandler()
}

extension Logger {
    /// The internal logger for the Mediation SDK.
    static var mediation: Logger { logger }
}

/// The internal logger for the Mediation SDK, as a global instance for convenience.
let logger: Logger = {
    let logger = Logger(
        id: "com.chartboost.mediation",
        name: "Chartboost Mediation"
    )
    logger.attachHandler(ConsoleLogHandler.mediation)
    return logger
}()
