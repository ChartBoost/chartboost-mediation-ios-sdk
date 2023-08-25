// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class SDKInitializerConfigurationMock: SDKInitializerConfiguration {
    var initTimeout: TimeInterval = 1
    var partnerCredentials: [PartnerIdentifier : [String : Any]] = [:]
    var partnerAdapterClassNames: Set<String> = ["one", "two"]
}
