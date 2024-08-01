// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import ChartboostCoreSDK
@testable import ChartboostMediationSDK

class ConsentSettingsMock: Mock<ConsentSettingsMock.Method>, ConsentSettings {

    enum Method {
        case setConsents
        case setIsUserUnderage
    }

    var delegate: ConsentSettingsDelegate?

    var consents: [ConsentKey: ConsentValue] = [:]

    var gdprApplies: Bool?

    var isUserUnderage = false

    func setConsents(_ consents: [ConsentKey : ConsentValue], modifiedKeys: Set<ConsentKey>) {
        record(.setConsents, parameters: [consents, modifiedKeys])
    }

    func setIsUserUnderage(_ isUserUnderage: Bool) {
        record(.setIsUserUnderage, parameters: [isUserUnderage])
    }
}
