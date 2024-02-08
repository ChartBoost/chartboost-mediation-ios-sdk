// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class PartnerAdapterFactoryMock: Mock<PartnerAdapterFactoryMock.Method>, PartnerAdapterFactory {
    
    enum Method {
        case adaptersFromClassNames
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.adaptersFromClassNames: [(PartnerAdapterMock(), MutablePartnerAdapterStorage())]]
    }
    
    func adapters(fromClassNames classNames: Set<String>) -> [(PartnerAdapter, MutablePartnerAdapterStorage)] {
        record(.adaptersFromClassNames, parameters: [classNames])
    }
}
