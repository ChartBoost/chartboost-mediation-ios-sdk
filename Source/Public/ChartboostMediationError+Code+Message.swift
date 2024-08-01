// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

extension ChartboostMediationError.Code {
    /// A brief description of what triggered the error.
    /// In Objective-C, access this value in the `ChartboostMediationError.userInfo` dictionary
    /// with the key `NSLocalizedDescriptionKey`.
    public var message: String {
        switch group {
        case .initialization:
            switch self {
            case .initializationSkipped:
                return "Partner initialization was skipped."
            default:
                return "Initialization has failed."
            }
        case .prebid:
            return "Partner token fetch has failed."
        case .load:
            return "Ad load has failed."
        case .show:
            return "Ad show has failed."
        case .invalidate:
            return "Ad invalidation has failed."
        case .others:
            switch self {
            case .partnerError:
                return "The partner has returned an error."
            case .internal:
                return "An internal error has occurred."
            case .noConnectivity:
                return "No Internet connectivity was available."
            case .adServerError:
                return "An ad server issue has occurred."
            case .invalidArguments:
                return "Invalid/empty arguments were passed to the function call, which caused the function to terminate prematurely."
            case .preinitializationActionFailed:
                return "Requested action failed because it needs to be performed before initializing Chartboost Mediation."
            default:
                break
            }
        }
        return "An unknown error has occurred. It is unclear if it originates from Chartboost Mediation or mediation partner(s)."
    }
}
