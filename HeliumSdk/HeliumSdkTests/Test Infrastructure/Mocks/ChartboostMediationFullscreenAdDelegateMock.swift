// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class ChartboostMediationFullscreenAdDelegateMock: Mock<ChartboostMediationFullscreenAdDelegateMock.Method>, ChartboostMediationFullscreenAdDelegate {
    
    enum Method {
        case didRecordImpression
        case didClick
        case didReward
        case didClose
        case didExpire
    }
    
    func didRecordImpression(ad: ChartboostMediationFullscreenAd) {
        record(.didRecordImpression, parameters: [ad])
    }
    
    func didClick(ad: ChartboostMediationFullscreenAd) {
        record(.didClick, parameters: [ad])
    }
    
    func didReward(ad: ChartboostMediationFullscreenAd) {
        record(.didReward, parameters: [ad])
    }
    
    func didClose(ad: ChartboostMediationFullscreenAd, error: ChartboostMediationError?) {
        record(.didClose, parameters: [ad, error])
    }
    
    func didExpire(ad: ChartboostMediationFullscreenAd) {
        record(.didExpire, parameters: [ad])
    }
}
