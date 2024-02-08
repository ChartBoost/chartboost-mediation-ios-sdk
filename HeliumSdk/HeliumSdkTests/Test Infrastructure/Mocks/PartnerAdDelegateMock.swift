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
    
    func didTrackImpression(_ ad: PartnerAd, details: PartnerEventDetails) {
        record(.didTrackImpression, parameters: [ad, details])
    }
    
    func didClick(_ ad: PartnerAd, details: PartnerEventDetails) {
        record(.didClick, parameters: [ad, details])
    }
    
    func didReward(_ ad: PartnerAd, details: PartnerEventDetails) {
        record(.didReward, parameters: [ad, details])
    }
    
    func didDismiss(_ ad: PartnerAd, details: PartnerEventDetails, error: Error?) {
        record(.didDismiss, parameters: [ad, details, error])
    }
    
    func didExpire(_ ad: PartnerAd, details: PartnerEventDetails) {
        record(.didExpire, parameters: [ad, details])
    }
}
