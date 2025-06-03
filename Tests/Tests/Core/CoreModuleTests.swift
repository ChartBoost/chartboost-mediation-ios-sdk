// Copyright 2018-2025 Chartboost, Inc.
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

        module.initialize(configuration: config) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        var initializerCompletion: (ChartboostMediationError?) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.sdkInitializer, .initialize, parameters: [config.chartboostAppID, XCTMethodCaptureParameter { initializerCompletion = $0 }])
        initializerCompletion(nil)
        wait(for: [expectation], timeout: 1)
    }
}
