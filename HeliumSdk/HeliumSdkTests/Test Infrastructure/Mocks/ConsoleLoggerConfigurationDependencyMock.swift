// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK

/// This is just a simple data mock, thus no need to inherit `Mock`.
final class ConsoleLoggerConfigurationDependencyMock: ConsoleLoggerConfiguration {
    var logLevel: LogLevel?
}
