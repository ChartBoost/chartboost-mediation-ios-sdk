// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class FullScreenAdShowCoordinatorMock: Mock<FullScreenAdShowCoordinatorMock.Method>, FullScreenAdShowCoordinator & FullScreenAdShowObserver {
    
    enum Method {
        case addObserver
        case didShowFullScreenAd
        case didCloseFullScreenAd
    }
    
    func addObserver(_ observer: FullScreenAdShowObserver) {
        record(.addObserver, parameters: [observer])
    }
    
    func didShowFullScreenAd() {
        record(.didShowFullScreenAd)
    }
    
    func didCloseFullScreenAd() {
        record(.didCloseFullScreenAd)
    }
}
