// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class ILRDEventPublisherMock: Mock<ILRDEventPublisherMock.Method>, ILRDEventPublisher {
    
    enum Method {
        case postILRDEvent
    }
    
    func postILRDEvent(forPlacement placement: String, ilrdJSON: [String : Any]) {
        record(.postILRDEvent, parameters: [placement, ilrdJSON])
    }
}
