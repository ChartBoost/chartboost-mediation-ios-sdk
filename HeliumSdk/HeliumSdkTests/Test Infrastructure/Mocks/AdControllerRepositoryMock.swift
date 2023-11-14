// Copyright 2018-2023 Chartboost, Inc.
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
    
    func adController(forHeliumPlacement heliumPlacement: String) -> AdController {
        record(.adController, parameters: [heliumPlacement])
    }
}
