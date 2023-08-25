// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class BidFulfillOperationFactoryMock: Mock<BidFulfillOperationFactoryMock.Method>, BidFulfillOperationFactory {
    
    enum Method {
        case makeBidFulfillOperation
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.makeBidFulfillOperation: BidFulfillOperationMock()]
    }
    
    func makeBidFulfillOperation(bids: [Bid], request: HeliumAdLoadRequest, viewController: UIViewController?, delegate: PartnerAdDelegate) -> BidFulfillOperation {
        record(.makeBidFulfillOperation, parameters: [bids, request, viewController, delegate])
    }
}
