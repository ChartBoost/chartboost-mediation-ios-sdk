// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class HeliumBannerAdDelegateMock: Mock<HeliumBannerAdDelegateMock.Method>, HeliumBannerAdDelegate {
        
    enum Method {
        case didLoad
        case didClick
        case didRecordImpression
    }
    
    func heliumBannerAd(placementName: String, requestIdentifier: String, winningBidInfo: [String: Any]?, didLoadWithError error: ChartboostMediationError?) {
        record(.didLoad, parameters: [placementName, requestIdentifier, winningBidInfo, error])
    }

    func heliumBannerAd(placementName: String, didClickWithError error: ChartboostMediationError?) {
        record(.didClick, parameters: [placementName, error])
    }
    
    func heliumBannerAdDidRecordImpression(placementName: String) {
        record(.didRecordImpression, parameters: [placementName])
    }
}
