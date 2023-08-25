// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class SDKInitializerMock: Mock<SDKInitializerMock.Method>, SDKInitializer {
    
    enum Method {
        case initialize
    }
    
    func initialize(appIdentifier: String?, appSignature: String?, partnerIdentifiersToSkipInitialization: Set<PartnerIdentifier>, completion: @escaping (ChartboostMediationError?) -> Void) {
        record(.initialize, parameters: [appIdentifier, appSignature, partnerIdentifiersToSkipInitialization, completion])
    }
}
