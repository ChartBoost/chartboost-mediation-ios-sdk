// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class AdControllerMock: Mock<AdControllerMock.Method>, AdController {
    
    enum Method {
        case loadAd
        case clearLoadedAd
        case clearShowingAd
        case showAd
        case markLoadedAdAsShown
        case forceInternalExpiration
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.clearLoadedAd: true,
         .clearShowingAd: nil]
    }
    
    weak var delegate: AdControllerDelegate?
    
    var customData: String?
    
    var isReadyToShowAd = false
    
    func loadAd(request: InternalAdLoadRequest, viewController: UIViewController?, completion: @escaping (InternalAdLoadResult) -> Void) {
        record(.loadAd, parameters: [request, viewController, completion])
    }
    
    func clearLoadedAd() {
        record(.clearLoadedAd)
    }
    
    func clearShowingAd(completion: @escaping (ChartboostMediationError?) -> Void) {
        record(.clearShowingAd)
        completion(returnValue(for: .clearShowingAd))
    }
    
    func showAd(viewController: UIViewController, completion: @escaping (InternalAdShowResult) -> Void) {
        record(.showAd, parameters: [viewController, completion])
    }
    
    func markLoadedAdAsShown() {
        record(.markLoadedAdAsShown)
    }

    func forceInternalExpiration() {
        record(.forceInternalExpiration)
    }
}