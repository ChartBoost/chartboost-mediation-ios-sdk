// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostCoreSDK
@testable import ChartboostMediationSDK
import XCTest

final class CoreModuleTests: ChartboostMediationTestCase {
    func testInitialize() throws {
        let module = CoreModule(credentials: nil)
        let config = ModuleConfiguration(sdkConfiguration: .init(
            chartboostAppID: "",
            modules: [module],
            skippedModuleIDs: [""])
        )
        let expectation = expectation(description: "initialize module")

        module.initialize(configuration: config) {[unowned self] error in
            XCTAssertEqual(mocks.sdkInitializer.recordedMethods, [SDKInitializerMock.Method.initialize])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
}
