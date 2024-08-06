// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class ApplicationConfigurationControllerMock: Mock<ApplicationConfigurationControllerMock.Method>, ApplicationConfigurationController {
    
    enum Method {
        case restorePersistedConfiguration
        case updateConfiguration
    }

    func restorePersistedConfiguration() {
        record(.restorePersistedConfiguration)
    }

    func updateConfiguration(completion: @escaping UpdateAppConfigCompletion) {
        record(.updateConfiguration, parameters: [completion])
    }
}