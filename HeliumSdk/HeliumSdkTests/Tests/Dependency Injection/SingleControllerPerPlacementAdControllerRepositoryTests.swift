// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class SingleControllerPerPlacementAdControllerRepositoryTests: ChartboostMediationTestCase {

    lazy var repository = SingleControllerPerPlacementAdControllerRepository()
    
    /// Validates that when asked to provide a controller for a new placement the repository creates one through the factory.
    func testAdControllerForNewPlacement() {
        // Ask for an ad controller
        let controller = repository.adController(forHeliumPlacement: "hello")
        
        // Check that it's the one the factory returned
        XCTAssertMethodCalls(mocks.adControllerFactory, .makeAdController)
        XCTAssertIdentical(controller, mocks.adControllerFactory.returnValue(for: .makeAdController))
    }
    
    /// Validates that when asked to provide a controller for an existing placement the repository returns the saved controller instead of creating a new one.
    func testAdControllerForExistingPlacement() {
        // Setup: ask for a new ad controller
        testAdControllerForNewPlacement()
        let existingController = mocks.adControllerFactory.returnValue(for: .makeAdController) as AdControllerMock
        
        // Change the factory return value so we can validate that it's not used
        mocks.adControllerFactory.setReturnValue(AdControllerMock(), for: .makeAdController)
        // Ask for the same controller
        let controller = repository.adController(forHeliumPlacement: "hello")
        
        // Check that it's the previous one and the factory is not used
        XCTAssertNoMethodCalls(mocks.adControllerFactory)
        XCTAssertNotIdentical(controller, mocks.adControllerFactory.returnValue(for: .makeAdController))
        XCTAssertIdentical(controller, existingController)
    }
    
    /// Validates that when asked to provide a controller for a different placement the repository creates a new one even if there was another already created for a different placement.
    func testAdControllerForDifferentPlacements() {
        // Setup: ask for a new ad controller
        testAdControllerForNewPlacement()
        let existingController = mocks.adControllerFactory.returnValue(for: .makeAdController) as AdControllerMock
        
        // Change the factory return value so we can validate that it's not used
        mocks.adControllerFactory.setReturnValue(AdControllerMock(), for: .makeAdController)
        // Ask for an ad controller
        let controller = repository.adController(forHeliumPlacement: "hello 2")
        
        // Check that it's the one the factory returned
        XCTAssertMethodCalls(mocks.adControllerFactory, .makeAdController)
        XCTAssertIdentical(controller, mocks.adControllerFactory.returnValue(for: .makeAdController))
        XCTAssertNotIdentical(controller, existingController)
    }
}
