// Copyright 2022-2023 Chartboost, Inc.
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
    
    func validate(appIdentifier: String?, appSignature: String?) -> ChartboostMediationError? {
        record(.validate, parameters: [appIdentifier, appSignature])
    }
}
