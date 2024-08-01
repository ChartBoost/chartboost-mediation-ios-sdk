// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import ChartboostCoreSDK
@testable import ChartboostMediationSDK

class ConsentSettingsDelegateMock: Mock<ConsentSettingsDelegateMock.Method>, ConsentSettingsDelegate {
    
    enum Method {
        case setConsents
        case setIsUserUnderage
    }

    func setConsents(_ consents: [ConsentKey : ConsentValue], modifiedKeys: Set<ConsentKey>) {
        record(.setConsents, parameters: [consents, modifiedKeys])
    }

    func setIsUserUnderage(_ isUserUnderage: Bool) {
        record(.setIsUserUnderage, parameters: [isUserUnderage])
    }
}
