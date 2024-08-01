// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import Foundation

class BannerSwapControllerMock: Mock<BannerControllerMock.Method>, BannerSwapControllerProtocol {

    enum Method {
        case loadAd
        case clearAd
    }

    var delegate: ChartboostMediationSDK.BannerSwapControllerDelegate?
    var keywords: [String : String]?
    var partnerSettings: [String : Any]?
    var request: BannerAdLoadRequest?
    var showingBannerAdLoadResult: ChartboostMediationSDK.InternalAdLoadResult?

    func loadAd(request: BannerAdLoadRequest, viewController: UIViewController, completion: @escaping (BannerAdLoadResult) -> Void) {
        record(.loadAd, parameters: [request, viewController, completion])
    }

    func clearAd() {
        record(.clearAd, parameters: [])
    }
}
