// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Validates a set of initialization credentials.
protocol SDKCredentialsValidator {
    /// Takes user-provided appID and appSignature and returns an error if they are invalid.
    func validate(appIdentifier: String?, appSignature: String?) -> ChartboostMediationError?
}

/// A basic validator that just checks that the credentials strings have the proper length.
struct LengthSDKCredentialsValidator: SDKCredentialsValidator {
    
    func validate(appIdentifier: String?, appSignature: String?) -> ChartboostMediationError? {
        guard let appIdentifier = appIdentifier, appIdentifier.count > 20 else {
            return ChartboostMediationError(code: .initializationFailureInvalidCredentials)
        }
        guard let appSignature = appSignature, appSignature.count == 40 else {
            return ChartboostMediationError(code: .initializationFailureInvalidCredentials)
        }
        return nil
    }
}
