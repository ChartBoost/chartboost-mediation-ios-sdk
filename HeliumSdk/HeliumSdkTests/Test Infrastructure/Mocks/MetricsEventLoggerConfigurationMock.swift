// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class MetricsEventLoggerConfigurationMock: MetricsEventLoggerConfiguration {
    var filter: [MetricsEvent.EventType] = MetricsEvent.EventType.allCases
    var country: String? = "some country"
    var testIdentifier: String? = "some test identifier"
}
