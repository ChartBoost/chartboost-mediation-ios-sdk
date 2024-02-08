// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class HeliumRewardedAdDelegateMock: Mock<HeliumRewardedAdDelegateMock.Method>, CHBHeliumRewardedAdDelegate {
        
    enum Method {
        case didLoad
        case didShow
        case didClick
        case didClose
        case didRecordImpression
        case didGetReward
    }
    
    func heliumRewardedAd(withPlacementName placementName: String, requestIdentifier: String, winningBidInfo: [String: Any]?, didLoadWithError error: ChartboostMediationError?) {
        record(.didLoad, parameters: [placementName, requestIdentifier, winningBidInfo, error])
    }
    
    func heliumRewardedAd(withPlacementName placementName: String, didShowWithError error: ChartboostMediationError?) {
        record(.didShow, parameters: [placementName, error])
    }
    
    func heliumRewardedAd(withPlacementName placementName: String, didClickWithError error: ChartboostMediationError?) {
        record(.didClick, parameters: [placementName, error])
    }
    
    func heliumRewardedAd(withPlacementName placementName: String, didCloseWithError error: ChartboostMediationError?) {
        record(.didClose, parameters: [placementName, error])
    }
    
    func heliumRewardedAdDidRecordImpression(withPlacementName placementName: String) {
        record(.didRecordImpression, parameters: [placementName])
    }
    
    func heliumRewardedAdDidGetReward(withPlacementName placementName: String) {
        record(.didGetReward, parameters: [placementName])
    }
}
