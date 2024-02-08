// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class AdRepositoryMock: Mock<AdRepositoryMock.Method>, AdRepository {
    
    enum Method {
        case loadAd
    }
    
    func loadAd(
        request: AdLoadRequest,
        viewController: UIViewController?,
        delegate: PartnerAdDelegate,
        completion: @escaping (AdLoadResult) -> Void
    ) {
        record(.loadAd, parameters: [request, viewController, delegate, completion])
    }
}
