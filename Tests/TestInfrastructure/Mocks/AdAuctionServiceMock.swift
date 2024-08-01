// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class AdAuctionServiceMock: Mock<AdAuctionServiceMock.Method>, AdAuctionService {
    
    enum Method {
        case startAuction
    }
    
    func startAuction(request: InternalAdLoadRequest, completion: @escaping (AdAuctionResponse) -> Void) {
        record(.startAuction, parameters: [request, completion])
    }
}
