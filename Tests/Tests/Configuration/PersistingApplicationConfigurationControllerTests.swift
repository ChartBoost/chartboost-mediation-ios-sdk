// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class PersistingApplicationConfigurationControllerTests: ChartboostMediationTestCase {

    private static let fullSDKInitResponseData = JSONLoader.loadData(.full_sdk_init_response)

    lazy var controller = PersistingApplicationConfigurationController()
    
    private static let persistedInitHash = "some init hash"
    private static let updatedInitHash = "some updated init hash"
    
    var expectedConfigFileURL: URL {
        try! mocks.fileStorage.urlForSDKConfigurationDirectory.appendingPathComponent("HeConfig.json")
    }
    
    override func setUp() {
        super.setUp()
        
        // Clean up records from restore action that happens on the controller's init.
        // We do this here to avoid having to worry about it on every test we write.
        controller.restorePersistedConfiguration() // access to force instantiation of lazy var and restore the config
        mocks.fileStorage.removeAllRecords()
        mocks.appConfiguration.removeAllRecords()
        
        // Set persisted init hash to be passed by the controller to the service in fetchAppConfiguration calls
        mocks.userDefaultsStorage.values["init-hash"] = Self.persistedInitHash
    }
    
    /// Validates that the controller restores a persisted configuration on init.
    func testRestoresPersistedConfiguration() {
        // Setup: persisted data file exists
        mocks.fileStorage.setReturnValue(true, for: .fileExists)
        
        // Init the controller and restore config
        let controller = PersistingApplicationConfigurationController()
        controller.restorePersistedConfiguration()

        // Check that config is updated with the persisted data
        XCTAssertMethodCallsContains(mocks.fileStorage, .readData, parameters: [expectedConfigFileURL])
        XCTAssertMethodCalls(mocks.appConfiguration, .update, parameters: [mocks.fileStorage.returnValue(for: .readData)])
    }
    
    /// Validates that the controller tries to restore a persisted configuration on init and fails gracefully if none is available.
    func testInitTriesToRestorePersistedConfigurationAndFailsIfUnavailable() {
        // Setup: persisted data does not exist
        mocks.fileStorage.setReturnValue(false, for: .fileExists)
        
        // Init the controller and restore config
        let controller = PersistingApplicationConfigurationController()
        controller.restorePersistedConfiguration()

        // Check that config is not updated and data not read
        XCTAssertNoMethodCall(mocks.fileStorage, to: .readData)
        XCTAssertNoMethodCalls(mocks.appConfiguration)
    }
    
    /// Validates that the controller tries to restore a persisted configuration on init and fails gracefully if the persisted data is invalid.
    func testInitTriesToRestorePersistedConfigurationAndFailsIfInvalid() {
        // Setup: persisted data file exists, configuration fails to update
        mocks.fileStorage.setReturnValue(true, for: .fileExists)
        mocks.appConfiguration.setReturnValue(NSError.test(), for: .update)
        
        // Init a controller and restore config
        let controller = PersistingApplicationConfigurationController()
        controller.restorePersistedConfiguration()

        // Check that config is tried to be updated with the persisted data
        XCTAssertMethodCallsContains(mocks.fileStorage, .readData, parameters: [expectedConfigFileURL])
        XCTAssertMethodCalls(mocks.appConfiguration, .update, parameters: [mocks.fileStorage.returnValue(for: .readData)])
    }

    /// Validates that the controller `updateConfiguration` succeeds when it gets new config data from backend,
    /// updates the configuration and persists it successfully.
    func testUpdateConfigurationSucceedsOnHappyPathWithBackendUpdate() {
        // Update configuration
        var completed = false
        controller.updateConfiguration { appConfigSource, error in
            // Check operation is successful
            XCTAssertEqual(appConfigSource, .backend)
            XCTAssertNil(error)
            completed = true
        }
        
        // Check that we are waiting for service to finish
        var serviceCompletion: FetchAppConfigurationCompletion = { _ in }
        XCTAssertMethodCalls(
            mocks.appConfigurationService,
            .fetchAppConfiguration,
            parameters: [Self.persistedInitHash, XCTMethodCaptureParameter { serviceCompletion = $0 }]
        )
        XCTAssertNoMethodCalls(mocks.appConfiguration)
        XCTAssertNoMethodCalls(mocks.fileStorage)
        XCTAssertFalse(completed)
        
        // Make service finish successfuly
        serviceCompletion(.success((sdkInitHash: Self.updatedInitHash, data: Self.fullSDKInitResponseData)))
        
        // Check that the configuration is updated and persisted, the init hash persisted, and we finished
        XCTAssertMethodCalls(mocks.appConfiguration, .update, parameters: [Self.fullSDKInitResponseData])
        XCTAssertMethodCallsContains(mocks.fileStorage, .write, parameters: [Self.fullSDKInitResponseData, expectedConfigFileURL])
        XCTAssertEqual(mocks.userDefaultsStorage.values["init-hash"] as? String, Self.updatedInitHash)
        XCTAssertTrue(completed)
    }

    /// Validates that the controller `updateConfiguration` succeeds when it gets empty config data
    /// from backend with HTTP status code 204 (No Content). SDK init hash and config data are not
    /// updated because they are already stored.
    func testUpdateConfigurationSucceedsOnHappyPathWithoutBackendUpdate() {
        // Setup: configuration succeeds, persistence succeeds
        mocks.appConfiguration.setReturnValue(nil, for: .update)
        
        // Update configuration
        var completed = false
        controller.updateConfiguration { appConfigSource, error in
            // Check operation is successful
            XCTAssertEqual(appConfigSource, .localCache)
            XCTAssertNil(error)
            completed = true
        }
        
        // Check that we are waiting for service to finish
        var serviceCompletion: FetchAppConfigurationCompletion = { _ in }
        XCTAssertMethodCalls(
            mocks.appConfigurationService,
            .fetchAppConfiguration,
            parameters: [Self.persistedInitHash, XCTMethodCaptureParameter { serviceCompletion = $0 }]
        )
        XCTAssertNoMethodCalls(mocks.appConfiguration)
        XCTAssertNoMethodCalls(mocks.fileStorage)
        XCTAssertFalse(completed)
        
        // Make service finish successfuly
        serviceCompletion(.success(nil))

        // Check that the configuration is updated and persisted, the init hash persisted, and we finished
        XCTAssertNoMethodCalls(mocks.appConfiguration)
        XCTAssertNoMethodCalls(mocks.fileStorage)
        XCTAssertEqual(mocks.userDefaultsStorage.values["init-hash"] as? String, Self.persistedInitHash)
        XCTAssert(completed)
    }
    
    /// Validates that the controller `updateConfiguration` succeeds when it gets new config data,
    /// updates the configuration successfully, and persiststence fails.
    func testUpdateConfigurationSucceedsWhenPersistenceFails() {
        // Setup: configuration succeeds, persistence fails
        mocks.fileStorage.setReturnValue(NSError.test(), for: .write)
        
        // Update configuration
        var completed = false
        controller.updateConfiguration { appConfigSource, error in
            // Check operation is successful
            XCTAssertEqual(appConfigSource, .backend)
            XCTAssertNil(error)
            completed = true
        }
        
        // Check that we are waiting for service to finish
        var serviceCompletion: FetchAppConfigurationCompletion = { _ in }
        XCTAssertMethodCalls(
            mocks.appConfigurationService,
            .fetchAppConfiguration,
            parameters: [Self.persistedInitHash, XCTMethodCaptureParameter { serviceCompletion = $0 }]
        )
        XCTAssertNoMethodCalls(mocks.appConfiguration)
        XCTAssertNoMethodCalls(mocks.fileStorage)
        XCTAssertFalse(completed)
        
        // Make service finish successfuly
        serviceCompletion(.success((sdkInitHash: Self.updatedInitHash, data: Self.fullSDKInitResponseData)))
        
        // Check that the configuration is updated and persisted, the init hash persisted, and we finished
        XCTAssertMethodCalls(mocks.appConfiguration, .update, parameters: [Self.fullSDKInitResponseData])
        XCTAssertMethodCallsContains(mocks.fileStorage, .write, parameters: [Self.fullSDKInitResponseData, expectedConfigFileURL])
        XCTAssertEqual(mocks.userDefaultsStorage.values["init-hash"] as? String, Self.updatedInitHash)
        XCTAssertTrue(completed)
    }
    
    /// Validates that the controller `updateConfiguration` fails when fetching the new data from the service fails.
    func testUpdateConfigurationFailsWhenServiceFails() {
        let expectedError = ChartboostMediationError(code: .adServerError)
        
        // Update configuration
        var completed = false
        controller.updateConfiguration { appConfigSource, error in
            // Check operation failed
            XCTAssertEqual(appConfigSource, .localCache)
            XCTAssertEqual(error as NSError?, expectedError)
            completed = true
        }
        
        // Check that we are waiting for service to finish
        var serviceCompletion: FetchAppConfigurationCompletion = { _ in }
        XCTAssertMethodCalls(
            mocks.appConfigurationService,
            .fetchAppConfiguration,
            parameters: [Self.persistedInitHash, XCTMethodCaptureParameter { serviceCompletion = $0 }]
        )
        XCTAssertNoMethodCalls(mocks.appConfiguration)
        XCTAssertNoMethodCalls(mocks.fileStorage)
        XCTAssertFalse(completed)
        
        // Make service finish with an error
        serviceCompletion(.failure(expectedError))
        
        // Check that the configuration is not updated and we finished
        XCTAssertNoMethodCalls(mocks.appConfiguration)
        XCTAssertNoMethodCall(mocks.fileStorage, to: .write)
        XCTAssertEqual(mocks.userDefaultsStorage.values["init-hash"] as? String, Self.persistedInitHash)   // init hash did not change
        XCTAssertTrue(completed)
    }
}
