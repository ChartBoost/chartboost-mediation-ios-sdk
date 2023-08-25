// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class PartnerAdapterTests: HeliumTestCase {

    let adapter = PartnerAdapterMock()
    
    // MARK: - Errors
    
    /// Validates that the error() method provided as a protocol extension returns a proper error when passing one parameter.
    func testErrorConcise() throws {
        let error = adapter.error(.loadFailureLoadInProgress)
        let ChartboostMediationError = try XCTUnwrap(error as? ChartboostMediationError)
        XCTAssertEqual(ChartboostMediationError.chartboostMediationCode, .loadFailureLoadInProgress)
        XCTAssertNil(ChartboostMediationError.userInfo[NSLocalizedFailureErrorKey])
        XCTAssertNil(ChartboostMediationError.userInfo[NSUnderlyingErrorKey])
    }
    
    /// Validates that the error() method provided as a protocol extension returns a proper error when passing all parameters.
    func testErrorFull() throws {
        let underlyingError = NSError.test()
        let error = adapter.error(.initializationFailureUnknown, description: "Some partner description", error: underlyingError)
        
        let ChartboostMediationError = try XCTUnwrap(error as? ChartboostMediationError)
        XCTAssertEqual(ChartboostMediationError.chartboostMediationCode, .initializationFailureUnknown)
        XCTAssertEqual(ChartboostMediationError.userInfo[NSLocalizedFailureErrorKey] as? String, "Some partner description")
        XCTAssertEqual(ChartboostMediationError.userInfo[NSUnderlyingErrorKey] as? NSError, underlyingError)
    }
    
    // MARK: - Logging
    
    /// Validates the logging public API. Does not do any checks, since the result of these calls are just prints to the console, but makes sure that the API can be used as intended and that nothing crashes.
    func testLogging() {
        // Logging an event
        adapter.log(.privacyUpdated(setting: "some setting", value: 42))
        // Logging an event with a non-nil error
        adapter.log(.setUpFailed(NSError.test()))
        // Logging an event with a non-NSError error
        adapter.log(.setUpFailed(TestError.someError))
        // Logging an event with an ChartboostMediationError error
        adapter.log(.setUpFailed(ChartboostMediationError(code: .initializationFailureInvalidCredentials, description: "hello")))
        // Logging a custom event
        adapter.log(.custom("some" + "event"))
        // Logging a custom event with an empty string literal
        adapter.log("")
        // Logging a custom event with a non-empty string literal
        adapter.log("hello here")
        // Logging a custom event with a string interpolation
        adapter.log("hello here \(Date())!")
    }
    
    /// Just to test non-NSError error logging in `testLogging()`.
    private enum TestError: Error {
        case someError
    }
}

