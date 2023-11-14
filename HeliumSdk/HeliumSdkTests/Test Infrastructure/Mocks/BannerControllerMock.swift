// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class BannerControllerMock: Mock<BannerControllerMock.Method>, BannerControllerProtocol {

    enum Method {
        case loadAd
        case clearAd
        case viewVisibilityDidChange
    }
    
    override var defaultReturnValues: [Method: Any?] {
        [.loadAd: "some request id",
         .clearAd: true]
    }

    var delegate: BannerControllerDelegate?
    var keywords: [String : String]?
    var request: ChartboostMediationBannerLoadRequest
    var showingBannerLoadResult: AdLoadResult?
    var isPaused: Bool = false

    init(request: ChartboostMediationBannerLoadRequest = .init(placement: "placement", size: .standard)) {
        self.request = request
    }

    func loadAd(viewController: UIViewController, completion: @escaping (ChartboostMediationSDK.ChartboostMediationBannerLoadResult) -> Void) {
        record(.loadAd, parameters: [viewController, completion])
    }
    
    func clearAd() {
        record(.clearAd, parameters: [])
    }
    
    func viewVisibilityDidChange(to visible: Bool) {
        record(.viewVisibilityDidChange, parameters: [visible])
    }
}
