// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

// This list must reflect the documentation at https://chartboost.atlassian.net/wiki/spaces/HM/pages/2551513299
extension ChartboostMediationError.Code {
    
    /// A brief description of what triggered the error.
    public var message: String {
        switch group {
        case .initialization:
            switch self {
            case .initializationFailureUnknown, .initializationFailureNetworkingError, .initializationFailureInternalError:
                return "Chartboost Mediation initialization has failed."
            case .initializationSkipped:
                return "Partner initialization was skipped."
            default:
                return "Partner initialization has failed."
            }
        case .prebid:
            return "Partner token fetch has failed."
        case .load:
            switch self {
            case .loadFailureWaterfallExhaustedNoFill:
                return "All waterfall entries have been exhausted. No ad fill."
            default:
                return "Partner ad load has failed."
            }
        case .show:
            return "Partner ad show has failed."
        case .invalidate:
            return "Partner ad invalidation has failed."
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
            default:
                break
            }
        }
        return "An unknown error has occurred. It is unclear if it originates from Chartboost Mediation or mediation partner(s)."
    }
}
