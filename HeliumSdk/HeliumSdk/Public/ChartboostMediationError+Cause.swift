// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

// This list must reflect the documentation at https://chartboost.atlassian.net/wiki/spaces/HM/pages/2551513299
extension ChartboostMediationError.Code {
    
    /// A concise explanation of what caused the issue.
    public var cause: String {
        switch self {
        // 100
        case .initializationFailureUnknown:
            return "There was an error that was not accounted for."
        case .initializationFailureAborted:
            return "The initialization process started but was aborted midway prior to completion."
        case .initializationFailureAdBlockerDetected:
            return "An ad blocker was detected."
        case .initializationFailureAdapterNotFound:
            return "The adapter instance responsible to initialize this partner is no longer in memory."
        case .initializationFailureInvalidAppConfig:
            return "Chartboost Mediation received an invalid app config payload from the ad server."
        case .initializationFailureInvalidCredentials:
            return "Invalid/empty credentials were supplied to initialize the partner."
        case .initializationFailureNoConnectivity:
            return "No Internet connectivity was available."
        case .initializationFailurePartnerNotIntegrated:
            return "The partner adapter and/or SDK might not have been properly integrated."
        case .initializationFailureTimeout:
            return "The initialization operation has taken too long to complete."
        case .initializationSkipped:
            return "You explicitly skipped initializing the partner."
        case .initializationFailureException:
            return "An exception was thrown during initialization."
        case .initializationFailureViewControllerNotFound:
            return "There is no View Controller with which to initialize the partner."
        case .initializationFailureNetworkingError:
            return "Init request failed due to a networking error."
        case .initializationFailureOSVersionNotSupported:
            return "The partner does not support this OS version."
        case .initializationFailureServerError:
            return "The initialization request failed due to a server error."
        case .initializationFailureInternalError:
            return "An error occurred within the Chartboost Mediation initialization sequence."
        
        // 200
        case .prebidFailureUnknown:
            return "There was an error that was not accounted for."
        case .prebidFailureAdapterNotFound:
            return "The adapter instance responsible to this token fetch is no longer in memory."
        case .prebidFailureInvalidArgument:
            return "Required data is missing."
        case .prebidFailureNotInitialized:
            return "The partner was not able to call its bidding APIs because it was not initialized, either because you have explicitly skipped its initialization or there were issues initializing it."
        case .prebidFailurePartnerNotIntegrated:
            return "The partner adapter and/or SDK might not have been properly integrated."
        case .prebidFailureTimeout:
            return "The token fetch operation has taken too long to complete."
        case .prebidFailureException:
            return "An exception was thrown during token fetch."
        case .prebidFailureOSVersionNotSupported:
            return "The partner does not support this OS version."
        case .prebidFailureNetworkingError:
            return "Prebid request failed due to a networking error."
        
        // 300
        case .loadFailureUnknown:
            return "There was an error that was not accounted for."
        case .loadFailureAborted:
            return "The ad load process started but was aborted midway prior to completion."
        case .loadFailureAdBlockerDetected:
            return "An ad blocker was detected."
        case .loadFailureAdapterNotFound:
            return "The adapter instance responsible to this load operation is no longer in memory."
        case .loadFailureAuctionNoBid:
            return "The auction for this ad request did not succeed."
        case .loadFailureAuctionTimeout:
            return "The auction for this ad request has taken too long to complete."
        case .loadFailureInvalidAdMarkup:
            return "The ad markup String is invalid."
        case .loadFailureInvalidAdRequest:
            return "The ad request is malformed."
        case .loadFailureInvalidBidResponse:
            return "The auction for this ad request succeeded but the bid response is corrupt."
        case .loadFailureInvalidChartboostMediationPlacement:
            return "The Chartboost Mediation placement is invalid or empty."
        case .loadFailureInvalidPartnerPlacement:
            return "The partner placement is invalid or empty."
        case .loadFailureMismatchedAdFormat:
            return "A placement for a different ad format was used in the ad request for the current ad format."
        case .loadFailureNoConnectivity:
            return "No Internet connectivity was available."
        case .loadFailureNoFill:
            return "There is no ad inventory at this time."
        case .loadFailurePartnerNotInitialized:
            return "The partner was not able to call its load APIs because it was not initialized, either because you have explicitly skipped its initialization or there were issues initializing it."
        case .loadFailureOutOfStorage:
            return "The ad request might have succeeded but there was not enough storage to store the ad. Therefore this is treated as a failure."
        case .loadFailurePartnerNotIntegrated:
            return "The partner adapter and/or SDK might not have been properly integrated."
        case .loadFailureRateLimited:
            return "Too many ad requests have been made over a short amount of time."
        case .loadFailureShowInProgress:
            return "An ad is already showing."
        case .loadFailureTimeout:
            return "The ad request operation has taken too long to complete."
        case .loadFailureUnsupportedAdFormat:
            return "The partner does not support that ad format."
        case .loadFailurePrivacyOptIn:
            return "One or more privacy settings have been opted in."
        case .loadFailurePrivacyOptOut:
            return "One or more privacy settings have been opted out."
        case .loadFailurePartnerInstanceNotFound:
            return "The partner SDK instance is null."
        case .loadFailureMismatchedAdParams:
            return "The partner returned an ad with different ad parameters than the one requested."
        case .loadFailureInvalidBannerSize:
            return "The supplied banner size is invalid."
        case .loadFailureException:
            return "An exception was thrown during ad load."
        case .loadFailureLoadInProgress:
            return "An ad is already loading."
        case .loadFailureViewControllerNotFound:
            return "There is no View Controller to load the ad in."
        case .loadFailureNoInlineView:
            return "The partner returns an ad with no inline view to show."
        case .loadFailureNetworkingError:
            return "Ad request failed due to a networking error."
        case .loadFailureChartboostMediationNotInitialized:
            return "The Chartboost Mediation SDK was not initialized."
        case .loadFailureOSVersionNotSupported:
            return "The partner does not support this OS version."
        case .loadFailureServerError:
            return "The load request failed due to a server error."
        case .loadFailureInvalidCredentials:
            return "Invalid/empty credentials were supplied to load the ad."
        case .loadFailureWaterfallExhaustedNoFill:
            return "All waterfall entries have resulted in an error or no fill."
        case .loadFailureAdTooLarge:
            return "The partner ad dimension size is too large."

        // 400
        case .showFailureUnknown:
            return "There was an error that was not accounted for."
        case .showFailureViewControllerNotFound:
            return "There is no View Controller to show the ad in."
        case .showFailureAdBlockerDetected:
            return "An ad blocker was detected."
        case .showFailureAdNotFound:
            return "An ad that might have been cached is no longer available to show."
        case .showFailureAdExpired:
            return "The ad was expired by the partner SDK after a set time window."
        case .showFailureAdNotReady:
            return "There is no ad ready to show."
        case .showFailureAdapterNotFound:
            return "The adapter instance responsible to this show operation is no longer in memory."
        case .showFailureInvalidChartboostMediationPlacement:
            return "The Chartboost Mediation placement is invalid or empty."
        case .showFailureInvalidPartnerPlacement:
            return "The partner placement is invalid or empty."
        case .showFailureMediaBroken:
            return "The media associated with this ad is corrupt and cannot be rendered."
        case .showFailureNoConnectivity:
            return "No Internet connectivity was available."
        case .showFailureNoFill:
            return "There is no ad inventory at this time."
        case .showFailureNotInitialized:
            return "The partner was not able to call its show APIs because it was not initialized, either because you have explicitly skipped its initialization or there were issues initializing it."
        case .showFailureNotIntegrated:
            return "The partner adapter and/or SDK might not have been properly integrated."
        case .showFailureShowInProgress:
            return "An ad is already showing."
        case .showFailureTimeout:
            return "The show operation has taken too long to complete."
        case .showFailureVideoPlayerError:
            return "There was an error with the video player."
        case .showFailurePrivacyOptIn:
            return "One or more privacy settings have been opted in."
        case .showFailurePrivacyOptOut:
            return "One or more privacy settings have been opted out."
        case .showFailureWrongResourceType:
            return "A resource was found but it doesn't match the ad type to be shown."
        case .showFailureUnsupportedAdType:
            return "The ad format is not supported by the partner SDK."
        case .showFailureException:
            return "An exception was thrown during ad show."
        case .showFailureUnsupportedAdSize:
            return "The ad size is not supported by the partner SDK."
        case .showFailureInvalidBannerSize:
            return "The supplied banner size is invalid."
        
        // 500
        case .invalidateFailureUnknown:
            return "There was an error that was not accounted for."
        case .invalidateFailureAdNotFound:
            return "There is no ad to invalidate."
        case .invalidateFailureAdapterNotFound:
            return "The adapter instance responsible to this show operation is no longer in memory."
        case .invalidateFailureNotInitialized:
            return "The partner was not able to call its invalidate APIs because it was not initialized, either because you have explicitly skipped its initialization or there were issues initializing it."
        case .invalidateFailurePartnerNotIntegrated:
            return "The partner adapter and/or SDK might not have been properly integrated."
        case .invalidateFailureTimeout:
            return "The invalidate operation has taken too long to complete."
        case .invalidateFailureWrongResourceType:
            return "A resource was found but it doesn't match the ad type to be invalidated."
        case .invalidateFailureException:
            return "An exception was thrown during ad invalidation."

        // 600
        case .unknown:
            return "There is no known cause."
        case .noConnectivity, .adServerError, .partnerError, .internal, .invalidArguments:
            return "Unknown."
        }
    }
}
