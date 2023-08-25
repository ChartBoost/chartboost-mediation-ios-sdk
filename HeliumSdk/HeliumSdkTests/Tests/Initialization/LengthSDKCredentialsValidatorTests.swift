// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class LengthSDKCredentialsValidatorTests: HeliumTestCase {

    let validator = LengthSDKCredentialsValidator()
    
    /// Validates that the validator returns no error when credentials are valid.
    func testValidCredentials() {
        // Valid app identifier and app signature
        let result = validator.validate(appIdentifier: "1234567890120394i2304920349i203i402394", appSignature: String(repeating: "0", count: 40))
        
        XCTAssertNil(result)
    }
    
    /// Validates that the validator returns an error when credentials are invalid.
    func testInvalidCredentials() {
        // Nil app identifier
        var result = validator.validate(appIdentifier: nil, appSignature: String(repeating: "0", count: 40))
        
        XCTAssertEqual(result?.chartboostMediationCode, .initializationFailureInvalidCredentials)
        
        // Empty app identifier
        result = validator.validate(appIdentifier: "", appSignature: String(repeating: "0", count: 40))
        
        XCTAssertEqual(result?.chartboostMediationCode, .initializationFailureInvalidCredentials)
        
        // Lenght less than 21 app identifier
        result = validator.validate(appIdentifier: String(repeating: "a", count: 20), appSignature: String(repeating: "0", count: 40))
        
        XCTAssertEqual(result?.chartboostMediationCode, .initializationFailureInvalidCredentials)
        
        // Nil app signature
        result = validator.validate(appIdentifier: "1234567890120394i2304920349i203i402394", appSignature: nil)
        
        XCTAssertEqual(result?.chartboostMediationCode, .initializationFailureInvalidCredentials)
        
        // Empty app signature
        result = validator.validate(appIdentifier: "1234567890120394i2304920349i203i402394", appSignature: "")
        
        XCTAssertEqual(result?.chartboostMediationCode, .initializationFailureInvalidCredentials)
        
        // Lenght less than 40 app signature
        result = validator.validate(appIdentifier: "1234567890120394i2304920349i203i402394", appSignature: String(repeating: "0", count: 39))
        
        XCTAssertEqual(result?.chartboostMediationCode, .initializationFailureInvalidCredentials)

        // Lenght greater than 40 app signature
        result = validator.validate(appIdentifier: "1234567890120394i2304920349i203i402394", appSignature: String(repeating: "0", count: 41))
        
        XCTAssertEqual(result?.chartboostMediationCode, .initializationFailureInvalidCredentials)
    }
}
