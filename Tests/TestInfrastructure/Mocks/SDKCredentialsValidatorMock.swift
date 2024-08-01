// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class SDKCredentialsValidatorMock: Mock<SDKCredentialsValidatorMock.Method>, SDKCredentialsValidator {
    
    enum Method {
        case validate
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.validate: nil]
    }
    
    func validate(appIdentifier: String?) -> ChartboostMediationError? {
        record(.validate, parameters: [appIdentifier])
    }
}
