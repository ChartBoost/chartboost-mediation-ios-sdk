// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import Foundation

class BannerSwapControllerMock: Mock<BannerControllerMock.Method>, BannerSwapControllerProtocol {

    enum Method {
        case loadAd
        case clearAd
        case viewVisibilityDidChange
    }

    var delegate: ChartboostMediationSDK.BannerSwapControllerDelegate?
    var keywords: [String : String]?
    var request: ChartboostMediationSDK.ChartboostMediationBannerLoadRequest?
    var showingBannerLoadResult: ChartboostMediationSDK.AdLoadResult?

    func loadAd(request: ChartboostMediationSDK.ChartboostMediationBannerLoadRequest, viewController: UIViewController, completion: @escaping (ChartboostMediationSDK.ChartboostMediationBannerLoadResult) -> Void) {
        record(.loadAd, parameters: [request, viewController, completion])
    }

    func clearAd() {
        record(.clearAd, parameters: [])
    }

    func viewVisibilityDidChange(on view: UIView, to visible: Bool) {
        record(.viewVisibilityDidChange, parameters: [view, visible])
    }
}
