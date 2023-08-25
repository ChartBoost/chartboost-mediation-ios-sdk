// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol BidFulfillOperationFactory {
    func makeBidFulfillOperation(bids: [Bid], request: HeliumAdLoadRequest, viewController: UIViewController?, delegate: PartnerAdDelegate) -> BidFulfillOperation
}

struct ContainerBidFulfillOperationFactory: BidFulfillOperationFactory {
    
    func makeBidFulfillOperation(bids: [Bid], request: HeliumAdLoadRequest, viewController: UIViewController?, delegate: PartnerAdDelegate) -> BidFulfillOperation {
        PartnerControllerBidFulfillOperation(bids: bids, request: request, viewController: viewController, delegate: delegate)
    }
}
