// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Legacy error type. Use `ChartboostMediationError` instead.
@available(*, deprecated, message: "Use `ChartboostMediationError` instead.")
public typealias HeliumError = ChartboostMediationError

/// Legacy error code type. Use `ChartboostMediationError.Code` instead.
@available(*, deprecated, message: "Use `ChartboostMediationError.Code` instead.")
public typealias HeliumErrorCode = ChartboostMediationError.Code

/// Error type passed by the Chartboost Mediation SDK in its public delegate methods to provide context relative to the failure of a
/// certain operation.
///
/// You may print a `ChartboostMediationError` directly on the console to read the information it contains, or you may read the value
/// of standard `NSError` properties, like `localizedDescription`, `localizedRecoveryOptions`, `localizedRecoverySuggestion`, and
/// `localizedFailureReason`.
@objc(ChartboostMediationError)
public class ChartboostMediationError: NSError {
    // MARK: - Constants

    /// Chartboost Mediation SDK error domain.
    private static let chartboostMediationErrorDomain = "com.chartboost.mediation"
    private static let userInfoDataKey = "cm_data"

    // MARK: - Properties

    /// The underlying ``Code`` for this error.
    @objc public var chartboostMediationCode: Code {
        Code(rawValue: code) ?? .unknown
    }

    var data: Data? {
        userInfo[Self.userInfoDataKey] as? Data
    }

    var underlyingError: Error? {
        userInfo[NSUnderlyingErrorKey] as? Error
    }

    // This description string is consistent with the Android `toString()`. Both are consumed by our Unity SDK.
    /// A human readable, localized description of this error.
    override public var localizedDescription: String {
        let code = chartboostMediationCode
        return "\(code.name) (\(code.string)). Cause: \(code.cause) Resolution: \(code.resolution)"
    }

    // MARK: - Initializers

    /// Initializes the Chartboost Mediation error with the specified error code and description.
    /// - Parameter code: Chartboost Mediation error code.
    /// - Parameter description: Human readable description of the error. This description will be available under the
    /// `NSLocalizedDescriptionKey` field of the `userInfo`.
    /// - Returns: An initialized Chartboost Mediation error.
    convenience init(code: Code, description: String? = nil, error: Error? = nil) {
        self.init(code: code, description: description, error: error, errors: nil)
    }

    convenience init(code: Code, description: String? = nil, error: Error? = nil, data: Data?) {
        self.init(code: code, description: description, error: error, errors: nil, data: data)
    }

    convenience init(code: Code, description: String? = nil, errors: [Error]) {
        self.init(code: code, description: description, error: nil, errors: errors)
    }

    /// Common init.
    private init(code: Code, description: String?, error: Error?, errors: [Error]?, data: Data? = nil) {
        var userInfo: [String: Any] = [:]
        userInfo[NSLocalizedDescriptionKey] = code.message
        userInfo[NSLocalizedFailureReasonErrorKey] = code.cause
        userInfo[NSLocalizedRecoverySuggestionErrorKey] = code.resolution
        userInfo[NSUnderlyingErrorKey] = error as NSError?
        userInfo[Self.userInfoDataKey] = data

        // Limiting the custom description length to prevent bugs or malicious integrations from creating errors with super long strings
        // that may end up getting sent to our backend.
        if let description {
            // prefix result needs to be transformed from Substring to String
            userInfo[NSLocalizedFailureErrorKey] = String(description.prefix(1000))
        }
        if #available(iOS 14.5, *) {
            userInfo[NSMultipleUnderlyingErrorsKey] = errors as [NSError]?
        }
        super.init(domain: Self.chartboostMediationErrorDomain, code: code.rawValue, userInfo: userInfo)
    }

    // Private override to avoid exposing this init to publishers.
    override private init(domain: String, code: Int, userInfo dict: [String: Any]? = nil) {
        super.init(domain: domain, code: code, userInfo: dict)
    }

    // Internal override to avoid exposing this init to publishers.
    internal required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
