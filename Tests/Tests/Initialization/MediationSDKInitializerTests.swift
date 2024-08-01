// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class MediationSDKInitializerTests: ChartboostMediationTestCase {

    lazy var initializer = MediationSDKInitializer()

    /// Validates that initialization finishes immediately with success if the SDK is already initialized.
    func testInitializeSucceedsIfAlreadyInitialized() {
        // Setup: initialize successfully
        testInitializeSucceedsAfterConfigUpdatesAsLongAsItIsNotTheDefault()
        
        // Initialize
        var completed = false
        initializer.initialize(appIdentifier: "hello") { error in
            // Check initialization succeeded with a nil error
            XCTAssertNil(error)
            completed = true
        }
        
        // Check that initialization completed immediately
        XCTAssertTrue(completed)
        // Check that controllers were not called
        XCTAssertNoMethodCalls(mocks.partnerController)
        XCTAssertNoMethodCalls(mocks.appConfigurationController)
    }
    
    /// Validates that initialization finishes immediately silently if the SDK is already initializing.
    func testInitializeFinishesSilentlyIfAlreadyInitializing() {
        // Setup: credentials validator returns nil error
        mocks.credentialsValidator.setReturnValue(nil, for: .validate)
        
        // Initialize
        var completed = false
        initializer.initialize(appIdentifier: "hello") { error in
            // Check initialization succeeded with a nil error
            XCTAssertNil(error)
            completed = true
        }
        
        // Check that the credentials are saved
        XCTAssertEqual(mocks.environment.app.chartboostAppID, "hello")
        // Check that the configs are requested to update
        var appConfigCompletion: UpdateAppConfigCompletion = { _, _ in }
        XCTAssertMethodCalls(
            mocks.appConfigurationController,
            .restorePersistedConfiguration, .updateConfiguration,
            parameters: [], [XCTMethodCaptureParameter { appConfigCompletion = $0 }]
        )
        // Check that operation is waiting for config to update
        XCTAssertFalse(completed)
        
        // Call initialize again
        var completed2 = false
        initializer.initialize(appIdentifier: "hello") { error in
            completed2 = true
        }
        
        // Check that nothing happens
        XCTAssertNoMethodCalls(mocks.partnerController)
        XCTAssertNoMethodCalls(mocks.appConfigurationController)
        XCTAssertFalse(completed)
        XCTAssertFalse(completed2)
        
        // Finish the config update, marking that the config is not default
        appConfigCompletion(.backend, ChartboostMediationError(code: .unknown)) // even if we pass an error we should succeed
        
        // Check that partners are initialized
        XCTAssertMethodCalls(mocks.partnerController, .setUpAdapters)
        // Check that the operation is waiting for a one second delay
        XCTAssertFalse(completed)
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), 1.0])  // 1 is the number of secs
        
        // Perform the delayed task immediately
        mocks.taskDispatcher.performDelayedWorkItems()
        
        // Check that initialization finished successfully
        XCTAssertTrue(completed)
        
        // Check that 2nd initialization was ignored
        XCTAssertFalse(completed2)
    }
    
    /// Validates that initialization finishes immediately with failure if the credentials are invalid.
    func testInitializeFailsIfCredentialsAreInvalid() {
        // Setup: credentials validator returns an error
        mocks.credentialsValidator.setReturnValue(ChartboostMediationError(code: .initializationFailureInvalidCredentials), for: .validate)
        
        // Initialize
        var completed = false
        initializer.initialize(appIdentifier: "hello") { error in
            // Check initialization failed with an error
            XCTAssertEqual(error?.chartboostMediationCode, .initializationFailureInvalidCredentials)
            completed = true
        }
        
        // Check that initialization completed immediately
        XCTAssertTrue(completed)
        // Check that controllers were not called
        XCTAssertNoMethodCalls(mocks.partnerController)
        XCTAssertMethodCalls(mocks.appConfigurationController, .restorePersistedConfiguration, parameters: [])
    }
    
    /// Validates that initialization finishes successfuly after the config is updated even if that fails, as long as the current config is not the default one.
    func testInitializeSucceedsAfterConfigUpdatesAsLongAsItIsNotTheDefault() {
        
        // Setup: credentials validator returns nil error
        mocks.credentialsValidator.setReturnValue(nil, for: .validate)
        // Setup: app config with partner config to check later that it is passed to partner controller to initialize adapters
        mocks.sdkInitializerConfiguration.partnerCredentials = [
            "partner1": [
                "some key": "some value",
                "asdf": 4,
                "123": ["1", "2", "3"],
                "hey": ["1": "2"]
            ],
            "partner2": [
                "other key": "other value",
                "asdf": "3",
                "2": 23,
                "": 42.42,
                "prebids": [
                    ["prebid_key1": "prebid_value1", "prebid_key2": [1, 2, 3]] as [String: Any]
                ]
            ],
            "partner3": [
                "prebids": [
                    ["prebid_key3": "prebid_value3", "prebid_key4": ["a": "b"]] as [String: Any],
                    ["prebid_key5": "prebid_value5"]
                ]
            ]
        ]
        mocks.sdkInitializerConfiguration.partnerAdapterClassNames = ["one", "two"]

        // Initialize
        var completed = false
        initializer.initialize(appIdentifier: "hello") { error in
            // Check initialization succeeded with a nil error
            XCTAssertNil(error)
            completed = true
        }
        
        // Check that the credentials are saved
        XCTAssertEqual(mocks.environment.app.chartboostAppID, "hello")
        // Check that the configs are requested to update
        var appConfigCompletion: UpdateAppConfigCompletion = { _, _ in }
        XCTAssertMethodCalls(
            mocks.appConfigurationController,
            .restorePersistedConfiguration, .updateConfiguration,
            parameters: [], [XCTMethodCaptureParameter { appConfigCompletion = $0 }]
        )
        // Check that operation is waiting for config to update
        XCTAssertFalse(completed)
        
        // Finish the config update, marking that the config is not default
        appConfigCompletion(.backend, ChartboostMediationError(code: .unknown)) // even if we pass an error we should succeed
        
        // Check that partners are initialized
        XCTAssertMethodCalls(mocks.partnerController, .setUpAdapters, parameters: [mocks.sdkInitializerConfiguration.partnerCredentials, mocks.sdkInitializerConfiguration.partnerAdapterClassNames, Set<PartnerID>(), XCTMethodIgnoredParameter()])

        // Check that the operation is waiting for a one second delay
        XCTAssertFalse(completed)
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), 1.0])  // 1 is the number of secs
        
        // Perform the delayed task immediately
        mocks.taskDispatcher.performDelayedWorkItems()
        
        // Check that initialization finished successfully
        XCTAssertTrue(completed)
    }
    
    /// Validates that initialization finishes with failure after the config fails to update and we don't have a non-default persisted config.
    func testInitializeFailsAfterConfigUpdatesWithFailureAndADefaultConfig() {
        // Setup: credentials validator returns nil error
        mocks.credentialsValidator.setReturnValue(nil, for: .validate)
        
        // Initialize
        var completed = false
        initializer.initialize(appIdentifier: "hello") { error in
            // Check initialization failed with an error
            XCTAssertEqual(error?.chartboostMediationCode, .unknown)
            completed = true
        }
        
        // Check that the credentials are saved
        XCTAssertEqual(mocks.environment.app.chartboostAppID, "hello")
        // Check that the configs are requested to update
        var appConfigCompletion: UpdateAppConfigCompletion = { _, _ in }
        XCTAssertMethodCalls(
            mocks.appConfigurationController,
            .restorePersistedConfiguration, .updateConfiguration,
            parameters: [], [XCTMethodCaptureParameter { appConfigCompletion = $0 }]
        )
        // Check that operation is waiting for config to update
        XCTAssertFalse(completed)
        
        // Finish the config update, marking that the config as default (meaning no config was updated nor previously persisted)
        appConfigCompletion(.hardcodedDefault, ChartboostMediationError(code: .unknown))
        
        // Check that partners are not initialized
        XCTAssertNoMethodCalls(mocks.partnerController)
        // Check that initialization finished with failure
        XCTAssertTrue(completed)
    }
}
