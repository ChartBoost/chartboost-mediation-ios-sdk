// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class FullscreenAdDelegateMock: Mock<FullscreenAdDelegateMock.Method>, FullscreenAdDelegate {

    enum Method {
        case didRecordImpression
        case didClick
        case didReward
        case didClose
        case didExpire
    }
    
    func didRecordImpression(ad: FullscreenAd) {
        record(.didRecordImpression, parameters: [ad])
    }
    
    func didClick(ad: FullscreenAd) {
        record(.didClick, parameters: [ad])
    }
    
    func didReward(ad: FullscreenAd) {
        record(.didReward, parameters: [ad])
    }
    
    func didClose(ad: FullscreenAd, error: ChartboostMediationError?) {
        record(.didClose, parameters: [ad, error])
    }
    
    func didExpire(ad: FullscreenAd) {
        record(.didExpire, parameters: [ad])
    }
}
