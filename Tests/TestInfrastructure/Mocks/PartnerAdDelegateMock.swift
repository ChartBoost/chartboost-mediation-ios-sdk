// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class PartnerAdDelegateMock: Mock<PartnerAdDelegateMock.Method>, PartnerAdDelegate {
    
    enum Method {
        case didTrackImpression
        case didClick
        case didReward
        case didDismiss
        case didExpire
    }
    
    func didTrackImpression(_ ad: PartnerAd) {
        record(.didTrackImpression, parameters: [ad])
    }
    
    func didClick(_ ad: PartnerAd) {
        record(.didClick, parameters: [ad])
    }
    
    func didReward(_ ad: PartnerAd) {
        record(.didReward, parameters: [ad])
    }
    
    func didDismiss(_ ad: PartnerAd, error: Error?) {
        record(.didDismiss, parameters: [ad, error])
    }
    
    func didExpire(_ ad: PartnerAd) {
        record(.didExpire, parameters: [ad])
    }
}
