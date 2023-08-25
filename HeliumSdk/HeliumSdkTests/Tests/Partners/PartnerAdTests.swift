// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class PartnerAdTests: HeliumTestCase {
    
    let ad = PartnerAdMock()
    
    // MARK: - Errors
    
    /// Validates that the error() method provided as a protocol extension returns a proper error when passing one parameter.
    func testErrorConcise() throws {
        ad.request = .test(partnerPlacement: "placement1234")
        
        let error = ad.error(.showFailureUnknown)
        
        let ChartboostMediationError = try XCTUnwrap(error as? ChartboostMediationError)
        XCTAssertEqual(ChartboostMediationError.chartboostMediationCode, .showFailureUnknown)
        XCTAssertNil(ChartboostMediationError.userInfo[NSLocalizedFailureErrorKey])
        XCTAssertNil(ChartboostMediationError.userInfo[NSUnderlyingErrorKey])
    }
    
    /// Validates that the error() method provided as a protocol extension returns a proper error when passing all parameters.
    func testErrorFull() throws {
        ad.request = .test(partnerPlacement: "placement1234")
        let underlyingError = NSError.test()
        let error = ad.error(.loadFailureLoadInProgress, description: "Some partner description", error: underlyingError)
        
        let ChartboostMediationError = try XCTUnwrap(error as? ChartboostMediationError)
        XCTAssertEqual(ChartboostMediationError.chartboostMediationCode, .loadFailureLoadInProgress)
        XCTAssertEqual(ChartboostMediationError.userInfo[NSLocalizedFailureErrorKey] as? String, "Some partner description")
        XCTAssertEqual(ChartboostMediationError.userInfo[NSUnderlyingErrorKey] as? NSError, underlyingError)
    }
    
    // MARK: - Logging
    
    /// Validates the logging public API. Does not do any checks, since the result of these calls are just prints to the console, but makes sure that the API can be used as intended and that nothing crashes.
    func testLogging() {
        // Logging an event
        ad.log(.didReward)
        // Logging an event with a nil error
        ad.log(.didClick(error: nil))
        // Logging an event with a non-nil error
        ad.log(.showFailed(NSError.test()))
        // Logging an event with a non-NSError error
        ad.log(.showFailed(TestError.someError))
        // Logging an event with an ChartboostMediationError error
        ad.log(.showFailed(ChartboostMediationError(code: .initializationFailureInvalidCredentials, description: "hello")))
        // Logging a custom event
        ad.log(.custom("some" + "event"))
        // Logging a custom event with an empty string literal
        ad.log("")
        // Logging a custom event with a non-empty string literal
        ad.log("hello here")
        // Logging a custom event with a string interpolation
        ad.log("hello here \(Date())!")
    }
    
    /// Just to test non-NSError error logging in `testLogging()`.
    private enum TestError: Error {
        case someError
    }
}
