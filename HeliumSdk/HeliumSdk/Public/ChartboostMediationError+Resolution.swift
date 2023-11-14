// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

// This list must reflect the documentation at https://chartboost.atlassian.net/wiki/spaces/HM/pages/2551513299
extension ChartboostMediationError.Code {
    
    /// A concise explanation of potential next step(s) that can be taken to address the issue.
    var resolution: String {
        switch self {
        // 100
        case .initializationFailureUnknown:
            return "Try again. If the problem persists, contact Chartboost Mediation Support and provide your console logs."
        case .initializationFailureAborted:
            return "Contact Chartboost Mediation Support and/or the mediation partner and provide a copy of your console logs."
        case .initializationFailureAdapterNotFound:
            return "This is an internal error. Contact Chartboost Mediation Support and provide a copy of your console logs."
        case .initializationFailureInvalidAppConfig:
            return "If this problem persists, reach out to the Chartboost Mediation team for further assistance. If possible, always forward us a copy of Chartboost Mediation network traffic."
        case .initializationFailureInvalidCredentials:
            return "Ensure appropriate fields are correctly entered on the Chartboost Mediation dashboard."
        case .initializationFailureNoConnectivity:
            return "Ensure there is Internet connectivity and try again."
        case .initializationFailurePartnerNotIntegrated:
            return "Check your adapter/SDK integration. If this error persists, contact Chartboost Mediation Support and provide a minimal reproducible build."
        case .initializationFailureTimeout:
            return "This should not be a critical error. Typically the partner can continue to finish initialization in the background. If this error persists, contact Chartboost Mediation Support and provide a copy of your console logs."
        case .initializationFailureException:
            return "Check your console logs for more details. If this error persists, contact Chartboost Mediation Support and provide a copy of your console logs."
        case .initializationFailureAdBlockerDetected, .initializationSkipped:
            return "N/A."
        case .initializationFailureViewControllerNotFound:
            return "Ensure that the a view controller is provided during initialization."
        case .initializationFailureNetworkingError:
            return "Typically this error should resolve by itself. If the error persists, contact Chartboost Mediation support and share a copy of your network traffic logs."
        case .initializationFailureOSVersionNotSupported:
            return "This is an expected error and can be ignored. Devices running newer OS versions should work fine."
        case .initializationFailureServerError:
            return "If this problem persists, reach out to Chartboost Mediation Support and/or the mediation partner team for further assistance. If possible, always share a copy of your network traffic logs."
        case .initializationFailureInternalError:
            return "This is an internal error. Contact Chartboost Mediation Support and provide a copy of your console logs."

        // 200
        case .prebidFailureUnknown:
            return "Try again. If the problem persists, contact Chartboost Mediation Support and provide your console logs."
        case .prebidFailureAdapterNotFound, .prebidFailureInvalidArgument:
            return "This is an internal error. Contact Chartboost Mediation Support and provide a copy of your console logs."
        case .prebidFailureNotInitialized:
            return "If this network supports bidding and you have explicitly skipped its initialization, allow it to initialize. Otherwise, try to re-initialize it."
        case .prebidFailurePartnerNotIntegrated:
            return "Check your adapter/SDK integration. If this error persists, contact Chartboost Mediation Support and provide a minimal reproducible build."
        case .prebidFailureTimeout:
            return "Try again. Typically, this issue should resolve itself. If the issue persists, contact the mediation partner and provide a copy of your console logs."
        case .prebidFailureException:
            return "Check your console logs for more details. If this error persists, contact Chartboost Mediation Support and provide a copy of your console logs."
        case .prebidFailureOSVersionNotSupported:
            return "This is an expected error and can be ignored. Devices running newer OS versions should work fine."
        case .prebidFailureNetworkingError:
            return "Typically this error should resolve by itself. If the error persists, contact Chartboost Mediation Support and/or the mediation partner team and share a copy of your network traffic logs."

        // 300
        case .loadFailureUnknown:
            return "Try again. If the problem persists, contact Chartboost Mediation Support and provide your console logs."
        case .loadFailureAborted:
            return "Contact Chartboost Mediation Support and/or the mediation partner and provide a copy of your console logs."
        case .loadFailureAdBlockerDetected, .loadFailureOutOfStorage, .loadFailurePrivacyOptIn, .loadFailurePrivacyOptOut:
            return "N/A."
        case .loadFailureAdapterNotFound:
            return "This is an internal errror. Contact Chartboost Mediation Support and provide a copy of your console logs."
        case .loadFailureInvalidAdMarkup, .loadFailureInvalidAdRequest:
            return "Contact Chartboost Mediation Support and/or the mediation partner and provide a copy of your network traffic logs."
        case .loadFailureAuctionNoBid, .loadFailureAuctionTimeout, .loadFailureInvalidBidResponse:
            return "Try again. Typically, this issue should resolve itself. If the issue persists, contact Chartboost Mediation Support and provide a copy of your console logs."
        case .loadFailureInvalidChartboostMediationPlacement:
            return "Ensure the Chartboost Mediation placement is properly defined on the Chartboost Mediation dashboard."
        case .loadFailureInvalidPartnerPlacement:
            return "Ensure the partner placement is properly defined on the Chartboost Mediation dashboard."
        case .loadFailureMismatchedAdFormat:
            return "Ensure you are using the correct placement for the correct ad format."
        case .loadFailureNoConnectivity:
            return "Ensure there is Internet connectivity and try again."
        case .loadFailureNoFill:
            return "Try again but be mindful of CM_LOAD_FAILURE_RATE_LIMITED."
        case .loadFailurePartnerNotInitialized:
            return "If you would like to load and show ads from this partner, allow it to initialize or try to re-initialize it."
        case .loadFailurePartnerNotIntegrated, .loadFailurePartnerInstanceNotFound:
            return "Check your adapter/SDK integration. If this error persists, contact Chartboost Mediation Support and provide a minimal reproducible build."
        case .loadFailureRateLimited:
            return "Avoid continually making ad requests in a short amount of time. You may implement an exponential backoff strategy to help mitigate this issue."
        case .loadFailureShowInProgress:
            return "You can only load another ad once the current ad is done showing."
        case .loadFailureTimeout:
            return "If this issue persists, contact Chartboost Mediation Support and/or the mediation partner and provide a copy of your console logs."
        case .loadFailureUnsupportedAdFormat:
            return "Try again with a different ad format. If the ad format you are requesting for is supported by the partner, contact Chartboost Mediation Support and provide a copy of your console logs."
        case .loadFailureMismatchedAdParams:
            return "This is typically caused by a partner SDK bug. Contact the mediation partner and provide a copy of your console logs."
        case .loadFailureInvalidBannerSize:
            return "Ensure the requested banner size is valid."
        case .loadFailureException:
            return "Check your console logs for more details. If this error persists, contact Chartboost Mediation Support and provide a copy of your console logs."
        case .loadFailureLoadInProgress:
            return "Wait until the current ad load is done before loading another ad."
        case .loadFailureViewControllerNotFound:
            return "Ensure that a view controller is provided during the load."
        case .loadFailureNoInlineView:
            return "This is typically caused by a partner adapter bug. Contact the mediation partner and provide a copy of your console logs."
        case .loadFailureNetworkingError:
            return "Typically this error should resolve by itself. If the error persists, contact Chartboost Mediation support and share a copy of your network traffic logs."
        case .loadFailureChartboostMediationNotInitialized:
            return "Ensure the Chartboost Mediation SDK is initialized before loading ads."
        case .loadFailureOSVersionNotSupported:
            return "This is an expected error and can be ignored. Devices running newer OS versions should work fine."
        case .loadFailureServerError:
            return "If this problem persists, reach out to Chartboost Mediation Support and/or the mediation partner team for further assistance. If possible, always share a copy of your network traffic logs."
        case .loadFailureInvalidCredentials:
            return "Ensure appropriate fields are correctly entered on the partner dashboard."
        case .loadFailureWaterfallExhaustedNoFill:
            return "Try again. If the problem persists, verify Partner settings in the Chartboost Mediation dashboard."
        case .loadFailureAdTooLarge:
            return "Try again. If the problem persists, verify Partner settings in the Chartboost Mediation dashboard."

        // 400
        case .showFailureUnknown:
            return "Try again. If the problem persists, contact Chartboost Mediation Support and provide your console logs."
        case .showFailureViewControllerNotFound:
            return "Ensure that a view controller is provided during the show."
        case .showFailureAdBlockerDetected, .showFailurePrivacyOptIn, .showFailurePrivacyOptOut:
            return "N/A."
        case .showFailureAdNotFound, .showFailureAdExpired, .showFailureNoFill:
            return "Try loading another ad but be mindful of CM_LOAD_FAILURE_RATE_LIMITED."
        case .showFailureAdNotReady:
            return "Try loading another ad and ensure it is ready before it's shown."
        case .showFailureAdapterNotFound:
            return "This is an internal error. Contact Chartboost Mediation Support and provide a copy of your console logs."
        case .showFailureInvalidChartboostMediationPlacement:
            return "Ensure the Chartboost Mediation placement is properly defined on the Chartboost Mediation dashboard."
        case .showFailureInvalidPartnerPlacement:
            return "Ensure the partner placement is properly defined on the Chartboost Mediation dashboard."
        case .showFailureMediaBroken:
            return "Try loading another ad. If this problem persists, contact the mediation partner and provide a copy of your console and network traffic logs."
        case .showFailureNoConnectivity:
            return "Ensure there is Internet connectivity and try again."
        case .showFailureNotInitialized:
            return "If you would like to load and show ads from this partner, allow it to initialize or try to re-initialize it."
        case .showFailureNotIntegrated:
            return "Check your adapter/SDK integration. If this error persists, contact Chartboost Mediation Support and provide a minimal reproducible build."
        case .showFailureShowInProgress:
            return "You cannot show multiple fullscreen ads simultaneously. Wait until the current ad is done showing before showing another ad."
        case .showFailureTimeout:
            return "If this issue persists, contact Chartboost Mediation Support and/or the mediation partner and provide a copy of your console logs."
        case .showFailureVideoPlayerError:
            return "Contact Chartboost Mediation Support or the mediation partner and provide details of your integration."
        case .showFailureWrongResourceType:
            return "This is an internal error. Typically, it should resolve itself. If this issue persists, contact Chartboost Mediation Support and provide a copy of your console logs."
        case .showFailureUnsupportedAdType:
            return "Try again with a different ad format. If the ad format you are requesting for is supported by the partner, contact Chartboost Mediation Support and provide a copy of your console logs."
        case .showFailureException:
            return "Check your console logs for more details. If this error persists, contact Chartboost Mediation Support and provide a copy of your console logs."
        case .showFailureUnsupportedAdSize:
            return "If this issue persists, contact the mediation partner and provide a copy of your console logs."
        case .showFailureInvalidBannerSize:
            return "Ensure the requested banner size is valid."

        // 500
        case .invalidateFailureUnknown:
            return "Try again. If the problem persists, contact Chartboost Mediation Support and provide your console logs."
        case .invalidateFailureAdNotFound:
            return "N/A."
        case .invalidateFailureAdapterNotFound:
            return "This is an internal error. Contact Chartboost Mediation Support and provide a copy of your console logs."
        case .invalidateFailureNotInitialized:
            return "If this network supports ad invalidation and you have explicitly skipped its initialization, allow it to initialize. Otherwise, try to re-initialize it."
        case .invalidateFailurePartnerNotIntegrated:
            return "Check your adapter/SDK integration. If this error persists, contact Chartboost Mediation Support and provide a minimal reproducible build."
        case .invalidateFailureTimeout:
            return "If this issue persists, contact Chartboost Mediation Support and/or the mediation partner and provide a copy of your console logs."
        case .invalidateFailureWrongResourceType:
            return "This is an internal error. Typically, it should resolve itself. If this issue persists, contact Chartboost Mediation Support and provide a copy of your console logs."
        case .invalidateFailureException:
            return "Check your console logs for more details. If this error persists, contact Chartboost Mediation Support and provide a copy of your console logs."

        // 600
        case .unknown:
            return "No information is available about this error."
        case .noConnectivity:
            return "Ensure there is Internet connectivity and try again."
        case .adServerError, .internal:
            return "This is an internal error. Contact Chartboost Mediation Support and provide a copy of your console logs."
        case .partnerError:
            return "The Chartboost Mediation SDK does not have insights into this type of error. Contact the mediation partner and provide details of your integration."
        case .invalidArguments:
            return "Depending on when this error occurs, it could be due to an issue in Chartboost Mediation or mediation partner(s) or your integration. Contact Chartboost Mediation Support and provide a copy of your console logs."
        }
    }
}
