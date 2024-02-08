// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class BidFulfillOperationMock: Mock<BidFulfillOperationMock.Method>, BidFulfillOperation {
    
    enum Method {
        case run
    }
    
    func run(completion: @escaping (BidFulfillOperationResult) -> Void) {
        record(.run, parameters: [completion])
    }
}
