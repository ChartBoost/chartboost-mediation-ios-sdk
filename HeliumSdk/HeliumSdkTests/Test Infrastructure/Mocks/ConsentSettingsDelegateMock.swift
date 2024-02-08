// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class ConsentSettingsDelegateMock: Mock<ConsentSettingsDelegateMock.Method>, ConsentSettingsDelegate {
    
    enum Method {
        case didChangeGDPR
        case didChangeCCPA
        case didChangeCOPPA
    }
    
    func didChangeGDPR() {
        record(.didChangeGDPR)
    }
    
    func didChangeCCPA() {
        record(.didChangeCCPA)
    }
    
    func didChangeCOPPA() {
        record(.didChangeCOPPA)
    }
}
