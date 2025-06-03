// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

/// A XCTestCase subclass that replaces the shared dependencies container by a mock.
class ChartboostMediationTestCase: XCTestCase {
    
    let dependenciesContainer = DependenciesContainerMock()
    
    /// Mocks used for dependency injection in all test classes.
    /// Properties that use the Injected property wrapper get these values injected.
    var mocks: MocksContainer { dependenciesContainer.mocks }
    
    override func setUp() {
        // Replace the shared dependencies container, so when a Mediation SDK class is created in order to test it all its @Injected properties are assigned to mock values.
        DependenciesContainerStore.container = dependenciesContainer
    }

    static func urlPathFromTestName(_ function: StaticString = #function) -> String {
        return String("/\(function)").replacingOccurrences(of: "()", with: "")
    }
}
