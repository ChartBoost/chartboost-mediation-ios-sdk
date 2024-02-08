// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class SDKInitializerMock: Mock<SDKInitializerMock.Method>, SDKInitializer {
    
    enum Method {
        case initialize
    }
    
    func initialize(appIdentifier: String?, partnerIdentifiersToSkipInitialization: Set<PartnerIdentifier>, completion: @escaping (ChartboostMediationError?) -> Void) {
        record(.initialize, parameters: [appIdentifier, partnerIdentifiersToSkipInitialization, completion])
    }
}
