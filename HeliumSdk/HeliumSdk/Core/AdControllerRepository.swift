// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A repository that produces AdController instances on demand.
protocol AdControllerRepository {
    /// Returns an AdController instance suitable for the specified placement.
    func adController(forHeliumPlacement heliumPlacement: String) -> AdController
}

/// An AdControllerRepository that shares the same ad controller per Helium placement.
/// Note that there will never be ads of different format but with same placement.
final class SingleControllerPerPlacementAdControllerRepository: AdControllerRepository {
    /// Already created controllers keyed by Helium placement.
    private var controllers: [String: AdController] = [:]
    /// A factory that knows how to create new ad controllers
    @Injected(\.adControllerFactory) private var factory

    func adController(forHeliumPlacement heliumPlacement: String) -> AdController {
        // If controller already created for this placement return it
        if let controller = controllers[heliumPlacement] {
            return controller
        }
        // Otherwise create a new controller, save it, and return it
        let controller = factory.makeAdController()
        controllers[heliumPlacement] = controller
        return controller
    }
}
