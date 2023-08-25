// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class FullscreenAdLoaderConfigurationMock: Mock<FullscreenAdLoaderConfigurationMock.Method>, FullscreenAdLoaderConfiguration {
    
    enum Method {
        case adFormatForPlacement
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.adFormatForPlacement: AdFormat.rewarded]
    }
    
    func adFormat(forPlacement placement: String) -> AdFormat? {
        record(.adFormatForPlacement, parameters: [placement])
    }
}
