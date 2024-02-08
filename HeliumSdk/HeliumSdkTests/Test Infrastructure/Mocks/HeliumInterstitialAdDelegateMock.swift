// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class HeliumInterstitialAdDelegateMock: Mock<HeliumInterstitialAdDelegateMock.Method>, CHBHeliumInterstitialAdDelegate {
        
    enum Method {
        case didLoad
        case didShow
        case didClick
        case didClose
        case didRecordImpression
    }
    
    func heliumInterstitialAd(withPlacementName placementName: String, requestIdentifier: String, winningBidInfo: [String: Any]?, didLoadWithError error: ChartboostMediationError?) {
        record(.didLoad, parameters: [placementName, requestIdentifier, winningBidInfo, error])
    }
    
    func heliumInterstitialAd(withPlacementName placementName: String, didShowWithError error: ChartboostMediationError?) {
        record(.didShow, parameters: [placementName, error])
    }
    
    func heliumInterstitialAd(withPlacementName placementName: String, didClickWithError error: ChartboostMediationError?) {
        record(.didClick, parameters: [placementName, error])
    }
    
    func heliumInterstitialAd(withPlacementName placementName: String, didCloseWithError error: ChartboostMediationError?) {
        record(.didClose, parameters: [placementName, error])
    }
    
    func heliumInterstitialAdDidRecordImpression(withPlacementName placementName: String) {
        record(.didRecordImpression, parameters: [placementName])
    }
}
