// Copyright 2022-2023 Chartboost, Inc.
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
    
    var bannerContainer: UIView?
    
    var keywords: HeliumKeywords?

    func loadAd(with viewController: UIViewController) {
        record(.loadAd, parameters: [viewController])
    }
    
    func clearAd() {
        record(.clearAd, parameters: [])
    }
    
    func viewVisibilityDidChange(on view: UIView, to visible: Bool) {
        record(.viewVisibilityDidChange, parameters: [view, visible])
    }
}
