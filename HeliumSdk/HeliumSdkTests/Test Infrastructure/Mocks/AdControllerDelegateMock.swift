// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class AdControllerDelegateMock: Mock<AdControllerDelegateMock.Method>, AdControllerDelegate {
    
    enum Method {
        case didTrackImpression
        case didClick
        case didReward
        case didDismiss
        case didExpire
    }
    
    func didTrackImpression() {
        record(.didTrackImpression)
    }
    
    func didClick() {
        record(.didClick)
    }
    
    func didReward() {
        record(.didReward)
    }
    
    func didDismiss(error: ChartboostMediationError?) {
        record(.didDismiss, parameters: [error])
    }
    
    func didExpire() {
        record(.didExpire)
    }
}
