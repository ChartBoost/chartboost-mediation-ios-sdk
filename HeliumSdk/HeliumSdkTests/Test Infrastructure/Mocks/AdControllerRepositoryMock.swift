// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class AdControllerRepositoryMock: Mock<AdControllerRepositoryMock.Method>, AdControllerRepository {
    
    enum Method {
        case adController
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.adController: AdControllerMock()]
    }
    
    func adController(for mediationPlacement: String) -> AdController {
        record(.adController, parameters: [mediationPlacement])
    }
}
