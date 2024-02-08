// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class FullScreenAdShowObserverMock: Mock<FullScreenAdShowObserverMock.Method>, FullScreenAdShowObserver {
    
    enum Method {
        case didShowFullScreenAd
        case didCloseFullScreenAd
    }
    
    func didShowFullScreenAd() {
        record(.didShowFullScreenAd)
    }
    
    func didCloseFullScreenAd() {
        record(.didCloseFullScreenAd)
    }
}
