// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class BannerControllerMock: Mock<BannerControllerMock.Method>, BannerControllerProtocol {

    enum Method {
        case loadAd
        case clearAd
    }
    
    override var defaultReturnValues: [Method: Any?] {
        [.loadAd: "some request id",
         .clearAd: true]
    }

    var delegate: BannerControllerDelegate?
    var keywords: [String : String]?
    var partnerSettings: [String : Any]?
    var request: BannerAdLoadRequest
    var showingBannerAdLoadResult: InternalAdLoadResult?
    var isPaused: Bool = false

    init(request: BannerAdLoadRequest = .init(placement: "placement", size: .standard)) {
        self.request = request
    }

    func loadAd(viewController: UIViewController, completion: @escaping (BannerAdLoadResult) -> Void) {
        record(.loadAd, parameters: [viewController, completion])
    }
    
    func clearAd() {
        record(.clearAd, parameters: [])
    }
}
