// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Validates a set of initialization credentials.
protocol SDKCredentialsValidator {
    /// Takes user-provided appID and returns an error if they are invalid.
    func validate(appIdentifier: String?) -> ChartboostMediationError?
}

/// A basic validator that just checks that the credentials strings have the proper length.
struct LengthSDKCredentialsValidator: SDKCredentialsValidator {
    func validate(appIdentifier: String?) -> ChartboostMediationError? {
        guard let appIdentifier, appIdentifier.count > 20 else {
            return ChartboostMediationError(code: .initializationFailureInvalidCredentials)
        }
        return nil
    }
}
