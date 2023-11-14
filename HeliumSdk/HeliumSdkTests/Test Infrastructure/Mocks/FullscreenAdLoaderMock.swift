// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class FullscreenAdLoaderMock: Mock<FullscreenAdLoaderMock.Method>, FullscreenAdLoader {
    
    enum Method {
        case loadFullscreenAd
    }
    
    func loadFullscreenAd(with request: ChartboostMediationAdLoadRequest, completion: @escaping (ChartboostMediationFullscreenAdLoadResult) -> Void) {
        record(.loadFullscreenAd, parameters: [request, completion])
    }
}
