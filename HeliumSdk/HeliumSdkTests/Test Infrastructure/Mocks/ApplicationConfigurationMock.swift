// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class ApplicationConfigurationMock: Mock<ApplicationConfigurationMock.Method>, ApplicationConfiguration {
    
    enum Method {
        case update
    }

    func update(with data: Data) throws {
        try throwingRecord(.update, parameters: [data])
    }
}
