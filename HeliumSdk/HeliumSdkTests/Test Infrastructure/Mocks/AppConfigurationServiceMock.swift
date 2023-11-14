// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class AppConfigurationServiceMock: Mock<AppConfigurationServiceMock.Method>, AppConfigurationServiceProtocol {
    
    enum Method {
        case fetchAppConfiguration
    }
    
    func fetchAppConfiguration(sdkInitHash: String?, completion: @escaping FetchAppConfigurationCompletion) {
        record(.fetchAppConfiguration, parameters: [sdkInitHash, completion])
    }
}
