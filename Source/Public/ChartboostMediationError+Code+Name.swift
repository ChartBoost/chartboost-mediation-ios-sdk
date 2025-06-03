// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

extension ChartboostMediationError.Code {
    /// A prefixed string version of the error code.
    public var string: String {
        "CM_\(rawValue)"
    }

    /// A human-friendly constant string that uniquely identifies the error. 
    public var name: String {
        let codeString: String
        switch self {
        // 100
        case .initializationFailureUnknown:
            codeString = "UNKNOWN"
        case .initializationFailureAborted:
            codeString = "ABORTED"
        case .initializationFailureAdBlockerDetected:
            codeString = "AD_BLOCKER_DETECTED"
        case .initializationFailureAdapterNotFound:
            codeString = "ADAPTER_NOT_FOUND"
        case .initializationFailureInvalidAppConfig:
            codeString = "INVALID_APP_CONFIG"
        case .initializationFailureInvalidCredentials:
            codeString = "INVALID_CREDENTIALS"
        case .initializationFailureNoConnectivity:
            codeString = "NO_CONNECTIVITY"
        case .initializationFailurePartnerNotIntegrated:
            codeString = "PARTNER_NOT_INTEGRATED"
        case .initializationFailureTimeout:
            codeString = "TIMEOUT"
        case .initializationSkipped:
            return "CM_INITIALIZATION_SKIPPED" // this one is an oddball since it does not contain FAILURE
        case .initializationFailureException:
            codeString = "EXCEPTION"
        case .initializationFailureViewControllerNotFound:
            codeString = "VIEW_CONTROLLER_NOT_FOUND"
        case .initializationFailureNetworkingError:
            codeString = "NETWORKING_ERROR"
        case .initializationFailureOSVersionNotSupported:
            codeString = "OS_VERSION_NOT_SUPPORTED"
        case .initializationFailureServerError:
            codeString = "SERVER_ERROR"
        case .initializationFailureInternalError:
            codeString = "INTERNAL_ERROR"
        case .initializationFailureInitializationInProgress:
            codeString = "INITIALIZATION_IN_PROGRESS"
        case .initializationFailureInitializationDisabled:
            codeString = "INITIALIZATION_DISABLED"

        // 200
        case .prebidFailureUnknown:
            codeString = "UNKNOWN"
        case .prebidFailureAdapterNotFound:
            codeString = "ADAPTER_NOT_FOUND"
        case .prebidFailureInvalidArgument:
            codeString = "INVALID_ARGUMENT"
        case .prebidFailureNotInitialized:
            codeString = "NOT_INITIALIZED"
        case .prebidFailurePartnerNotIntegrated:
            codeString = "PARTNER_NOT_INTEGRATED"
        case .prebidFailureTimeout:
            codeString = "TIMEOUT"
        case .prebidFailureException:
            codeString = "EXCEPTION"
        case .prebidFailureOSVersionNotSupported:
            codeString = "OS_VERSION_NOT_SUPPORTED"
        case .prebidFailureNetworkingError:
            codeString = "NETWORKING_ERROR"
        case .prebidFailureUnsupportedAdFormat:
            codeString = "UNSUPPORTED_AD_FORMAT"

        // 300
        case .loadFailureUnknown:
            codeString = "UNKNOWN"
        case .loadFailureAborted:
            codeString = "ABORTED"
        case .loadFailureAdBlockerDetected:
            codeString = "AD_BLOCKER_DETECTED"
        case .loadFailureAdapterNotFound:
            codeString = "ADAPTER_NOT_FOUND"
        case .loadFailureAuctionNoBid:
            codeString = "AUCTION_NO_BID"
        case .loadFailureAuctionTimeout:
            codeString = "AUCTION_TIMEOUT"
        case .loadFailureInvalidAdMarkup:
            codeString = "INVALID_AD_MARKUP"
        case .loadFailureInvalidAdRequest:
            codeString = "INVALID_AD_REQUEST"
        case .loadFailureInvalidBidResponse:
            codeString = "INVALID_BID_RESPONSE"
        case .loadFailureInvalidChartboostMediationPlacement:
            codeString = "INVALID_CHARTBOOST_MEDIATION_PLACEMENT"
        case .loadFailureInvalidPartnerPlacement:
            codeString = "INVALID_PARTNER_PLACEMENT"
        case .loadFailureMismatchedAdFormat:
            codeString = "MISMATCHED_AD_FORMAT"
        case .loadFailureNoConnectivity:
            codeString = "NO_CONNECTIVITY"
        case .loadFailureNoFill:
            codeString = "NO_FILL"
        case .loadFailurePartnerNotInitialized:
            codeString = "PARTNER_NOT_INITIALIZED"
        case .loadFailureOutOfStorage:
            codeString = "OUT_OF_STORAGE"
        case .loadFailurePartnerNotIntegrated:
            codeString = "PARTNER_NOT_INTEGRATED"
        case .loadFailureRateLimited:
            codeString = "RATE_LIMITED"
        case .loadFailureShowInProgress:
            codeString = "SHOW_IN_PROGRESS"
        case .loadFailureTimeout:
            codeString = "TIMEOUT"
        case .loadFailureUnsupportedAdFormat:
            codeString = "UNSUPPORTED_AD_FORMAT"
        case .loadFailurePrivacyOptIn:
            codeString = "PRIVACY_OPT_IN"
        case .loadFailurePrivacyOptOut:
            codeString = "PRIVACY_OPT_OUT"
        case .loadFailurePartnerInstanceNotFound:
            codeString = "PARTNER_INSTANCE_NOT_FOUND"
        case .loadFailureMismatchedAdParams:
            codeString = "MISMATCHED_AD_PARAMS"
        case .loadFailureInvalidBannerSize:
            codeString = "INVALID_BANNER_SIZE"
        case .loadFailureException:
            codeString = "EXCEPTION"
        case .loadFailureLoadInProgress:
            codeString = "LOAD_IN_PROGRESS"
        case .loadFailureViewControllerNotFound:
            codeString = "VIEW_CONTROLLER_NOT_FOUND"
        case .loadFailureNoBannerView:
            codeString = "NO_BANNER_VIEW"
        case .loadFailureNetworkingError:
            codeString = "NETWORKING_ERROR"
        case .loadFailureChartboostMediationNotInitialized:
            codeString = "CHARTBOOST_MEDIATION_NOT_INITIALIZED"
        case .loadFailureOSVersionNotSupported:
            codeString = "OS_VERSION_NOT_SUPPORTED"
        case .loadFailureServerError:
            codeString = "SERVER_ERROR"
        case .loadFailureInvalidCredentials:
            codeString = "INVALID_CREDENTIALS"
        case .loadFailureWaterfallExhaustedNoFill:
            codeString = "WATERFALL_EXHAUSTED_NO_FILL"
        case .loadFailureAdTooLarge:
            codeString = "AD_TOO_LARGE"
        case .loadFailureSDKDisabled:
            codeString = "SDK_DISABLED"

        // 400
        case .showFailureUnknown:
            codeString = "UNKNOWN"
        case .showFailureViewControllerNotFound:
            codeString = "VIEW_CONTROLLER_NOT_FOUND"
        case .showFailureAdBlockerDetected:
            codeString = "AD_BLOCKER_DETECTED"
        case .showFailureAdNotFound:
            codeString = "AD_NOT_FOUND"
        case .showFailureAdExpired:
            codeString = "AD_EXPIRED"
        case .showFailureAdNotReady:
            codeString = "AD_NOT_READY"
        case .showFailureAdapterNotFound:
            codeString = "ADAPTER_NOT_FOUND"
        case .showFailureInvalidChartboostMediationPlacement:
            codeString = "INVALID_CHARTBOOST_MEDIATION_PLACEMENT"
        case .showFailureInvalidPartnerPlacement:
            codeString = "INVALID_PARTNER_PLACEMENT"
        case .showFailureMediaBroken:
            codeString = "MEDIA_BROKEN"
        case .showFailureNoConnectivity:
            codeString = "NO_CONNECTIVITY"
        case .showFailureNoFill:
            codeString = "NO_FILL"
        case .showFailureNotInitialized:
            codeString = "NOT_INITIALIZED"
        case .showFailureNotIntegrated:
            codeString = "NOT_INTEGRATED"
        case .showFailureShowInProgress:
            codeString = "SHOW_IN_PROGRESS"
        case .showFailureTimeout:
            codeString = "TIMEOUT"
        case .showFailureVideoPlayerError:
            codeString = "VIDEO_PLAYER_ERROR"
        case .showFailurePrivacyOptIn:
            codeString = "PRIVACY_OPT_IN"
        case .showFailurePrivacyOptOut:
            codeString = "PRIVACY_OPT_OUT"
        case .showFailureWrongResourceType:
            codeString = "WRONG_RESOURCE_TYPE"
        case .showFailureUnsupportedAdType:
            codeString = "UNSUPPORTED_AD_FORMAT"
        case .showFailureException:
            codeString = "EXCEPTION"
        case .showFailureUnsupportedAdSize:
            codeString = "UNSUPPORTED_AD_SIZE"
        case .showFailureInvalidBannerSize:
            codeString = "INVALID_BANNER_SIZE"

        // 500
        case .invalidateFailureUnknown:
            codeString = "UNKNOWN"
        case .invalidateFailureAdNotFound:
            codeString = "AD_NOT_FOUND"
        case .invalidateFailureAdapterNotFound:
            codeString = "ADAPTER_NOT_FOUND"
        case .invalidateFailureNotInitialized:
            codeString = "NOT_INITIALIZED"
        case .invalidateFailurePartnerNotIntegrated:
            codeString = "PARTNER_NOT_INTEGRATED"
        case .invalidateFailureTimeout:
            codeString = "TIMEOUT"
        case .invalidateFailureWrongResourceType:
            codeString = "WRONG_RESOURCE_TYPE"
        case .invalidateFailureException:
            codeString = "EXCEPTION"

        // 600 -- since these don't have group mnemonic, will just return immediately
        case .unknown:
            return "CM_UNKNOWN_ERROR"
        case .partnerError:
            return "CM_PARTNER_ERROR"
        case .internal:
            return "CM_INTERNAL_ERROR"
        case .noConnectivity:
            return "CM_NO_CONNECTIVITY"
        case .adServerError:
            return "CM_AD_SERVER_ERROR"
        case .invalidArguments:
            return "CM_INVALID_ARGUMENTS"
        case .preinitializationActionFailed:
            return "CM_PREINITIALIZATION_ACTION_FAILED"
        }

        return "CM_\(groupMnemonic)_\(codeString)"
    }

    private var groupMnemonic: String {
        switch group {
        case .initialization:
            return "INITIALIZATION_FAILURE"
        case .prebid:
            return "PREBID_FAILURE"
        case .load:
            return "LOAD_FAILURE"
        case .show:
            return "SHOW_FAILURE"
        case .invalidate:
            return "INVALIDATE_FAILURE"
        case .others:
            return ""
        }
    }
}
