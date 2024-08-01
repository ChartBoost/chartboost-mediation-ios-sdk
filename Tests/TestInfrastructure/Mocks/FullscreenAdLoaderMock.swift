// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class FullscreenAdLoaderMock: Mock<FullscreenAdLoaderMock.Method>, FullscreenAdLoader {
    
    enum Method {
        case loadFullscreenAd
    }
    
    func loadFullscreenAd(with request: FullscreenAdLoadRequest, completion: @escaping (FullscreenAdLoadResult) -> Void) {
        record(.loadFullscreenAd, parameters: [request, completion])
    }
}
