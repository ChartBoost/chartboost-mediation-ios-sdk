// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class AdControllerFactoryMock: Mock<AdControllerFactoryMock.Method>, AdControllerFactory {
    
    enum Method {
        case makeAdController
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.makeAdController: AdControllerMock()]
    }
    
    func makeAdController() -> AdController {
        record(.makeAdController)
    }
}
