// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Provides the capability to generate errors suitable to be passed in completion handlers for `PartnerAd` operations.
/// All functionality is provided by default implementations.
public extension PartnerAd {
        
    /// Returns a Chartboost Mediation error suitable to be passed in completion handlers for PartnerAd operations.
    /// - parameter code: A code that identifies the error.
    func error(_ code: ChartboostMediationError.Code) -> Error {
        self.error(code, description: nil, error: nil)
    }
    
    /// Returns a Chartboost Mediation error suitable to be passed in completion handlers for PartnerAd operations.
    /// - parameter code: A code that identifies the error.
    /// - parameter description: A string providing further information about the error.
    func error(_ code: ChartboostMediationError.Code, description: String?) -> Error {
        self.error(code, description: description, error: nil)
    }
    
    /// Returns a Chartboost Mediation error suitable to be passed in completion handlers for PartnerAd operations.
    /// - parameter code: A code that identifies the error.
    /// - parameter error: The error that triggered this error, if any.
    func error(_ code: ChartboostMediationError.Code, error: Error?) -> Error {
        self.error(code, description: nil, error: error)
    }
    
    /// Returns a Chartboost Mediation error suitable to be passed in completion handlers for PartnerAd operations.
    /// - parameter code: A code that identifies the error.
    /// - parameter description: A string providing further information about the error.
    /// - parameter error: The error that triggered this error, if any.
    func error(_ code: ChartboostMediationError.Code, description: String?, error: Error?) -> Error {
        ChartboostMediationError(code: code, description: description, error: error)
    }
    
    /// Creates an error with a partner error code, suitable to be passed in completion handlers for PartnerAd operations.
    /// You may use it when a partner callback provides a simple error code, like `Int` or `enum`, instead of an error type, like `Error` or `NSError`.
    /// - parameter code: A code that identifies the error, obtained from the partner SDK.
    func partnerError(_ code: Int) -> Error {
        partnerError(code, description: nil)
    }
    
    /// Creates an error with a partner error code, suitable to be passed in completion handlers for PartnerAd operations.
    /// You may use it when a partner callback provides a simple error code, like `Int` or `enum`, instead of an error type, like `Error` or `NSError`.
    /// - parameter code: A code that identifies the error, obtained from the partner SDK.
    /// - parameter description: A string providing further information about the error.
    func partnerError(_ code: Int, description: String?) -> Error {
        NSError(
            domain: "com.chartboost.mediation.partner",
            code: code,
            userInfo: description.map { [NSLocalizedDescriptionKey: $0] }
        )
    }
}
