// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Factory type to create ad controllers.
protocol AdControllerFactory {
    func makeAdController() -> AdController
}

struct ContainerAdControllerFactory: AdControllerFactory {
    
    func makeAdController() -> AdController {
        SingleAdStorageAdController()
    }
}
