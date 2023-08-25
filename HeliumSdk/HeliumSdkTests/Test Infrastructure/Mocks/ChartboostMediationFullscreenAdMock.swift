// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class ChartboostMediationFullscreenAdMock: Mock<ChartboostMediationFullscreenAdMock.Method>, ChartboostMediationFullscreenAd {
    
    enum Method {
        case show
        case invalidate
    }
    
    var delegate: ChartboostMediationFullscreenAdDelegate?
    
    var customData: String?
    
    var request: ChartboostMediationAdLoadRequest = .init(placement: "some placement")
    
    var winningBidInfo: [String: Any] = [:]
    
    func show(with viewController: UIViewController, completion: @escaping (ChartboostMediationAdShowResult) -> Void) {
        record(.show, parameters: [viewController, completion])
    }
    
    func invalidate() {
        record(.invalidate)
    }
}
