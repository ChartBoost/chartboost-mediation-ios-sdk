// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

// TDD: https://docs.google.com/document/d/1nbCVEqzAVxeXuuu780NWU7Ctp8ohpo5cicBpmPs5Ixg/edit#heading=h.5ny1kfakcz1
// Exhaustive code list: https://chartboost.atlassian.net/wiki/spaces/HM/pages/2551513299/Helium+Error+Codes+Helium+4.0.0

final class ChartboostMediationErrorCodeTests: XCTestCase {

    typealias Code = ChartboostMediationError.Code
    
    func testExpectedErrorGroupings() throws {

        func group(for code: Code) -> Int {
            (code.rawValue / 100) * 100
        }

        Code.allInitializationCases.forEach {
            XCTAssertEqual(100, group(for: $0))
        }

        Code.allPrebidCases.forEach {
            XCTAssertEqual(200, group(for: $0))
        }

        Code.allLoadCases.forEach {
            XCTAssertEqual(300, group(for: $0))
        }

        Code.allShowCases.forEach {
            XCTAssertEqual(400, group(for: $0))
        }

        Code.allInvalidateCases.forEach {
            XCTAssertEqual(500, group(for: $0))
        }

        Code.allOtherCases.forEach {
            XCTAssertEqual(600, group(for: $0))
        }
    }

    // TDD test callout: "All Chartboost Mediation error code integers are unique"
    func testThatAllCodesAreUnique() {
        let uniqueErrorCodes = Set<Int>(Code.allCases.map(\.rawValue))
        XCTAssertEqual(uniqueErrorCodes.count, Code.allCases.count)
    }

    func testErrorsAgainstExpectedData() throws {
        for (code, expected) in Code.rawExpectedData {
            let error = ChartboostMediationError(code: code)

            // TDD test callout: All Chartboost Mediation error codes must start with the CM_ prefix and end with a 3-digit number
            XCTAssertEqual("CM_", error.chartboostMediationCode.string.prefix(3))
            XCTAssertEqual(code.rawValue, Int(error.chartboostMediationCode.string.suffix(3)))
            XCTAssertEqual(expected.codeString, error.chartboostMediationCode.string)

            // TDD test callout: All Chartboost Mediation error codes must have non-empty codes, messages, causes, and resolutions
            XCTAssertFalse(error.chartboostMediationCode.name.isEmpty)
            XCTAssertEqual(expected.constant, error.chartboostMediationCode.name)

            // TDD test callout: All Chartboost Mediation error codes must have non-empty codes, messages, causes, and resolutions
            XCTAssertFalse(error.chartboostMediationCode.message.isEmpty)
            XCTAssertEqual(expected.message, error.chartboostMediationCode.message)
            XCTAssertTrue(expected.message.suffix(1) == ".") // ends with period

            // TDD test callout: All Chartboost Mediation error codes must have non-empty codes, messages, causes, and resolutions
            XCTAssertFalse(error.chartboostMediationCode.cause.isEmpty)
            XCTAssertEqual(expected.cause, error.chartboostMediationCode.cause)
            XCTAssertTrue(expected.cause.suffix(1) == ".") // ends with period

            // TDD test callout: All Chartboost Mediation error codes must have non-empty codes, messages, causes, and resolutions
            XCTAssertFalse(error.chartboostMediationCode.resolution.isEmpty)
            XCTAssertEqual(expected.resolution, error.chartboostMediationCode.resolution)
            if expected.resolution != "N/A." {
                XCTAssertTrue(expected.resolution.suffix(1) == ".") // ends with period
            }
        }
    }

    // TDD test callout: For each range, defined Chartboost Mediation error codes must increment by 1 successively
    func testErrorCodeSuccessiveIncrement() {
        let initialization = Code.allInitializationCases.map(\.rawValue).sorted()
        XCTAssertEqual(initialization[0], ChartboostMediationError.Code.Group.initialization.rawValue)
        XCTAssertEqual(initialization[Code.allInitializationCases.count - 1], Code.allInitializationCases.count - 1 + ChartboostMediationError.Code.Group.initialization.rawValue)
        
        let prebid = Code.allPrebidCases.map(\.rawValue).sorted()
        XCTAssertEqual(prebid[0], ChartboostMediationError.Code.Group.prebid.rawValue)
        XCTAssertEqual(prebid[Code.allPrebidCases.count - 1], Code.allPrebidCases.count - 1 + ChartboostMediationError.Code.Group.prebid.rawValue)

        let load = Code.allLoadCases.map(\.rawValue).sorted()
        XCTAssertEqual(load[0], ChartboostMediationError.Code.Group.load.rawValue)
        XCTAssertEqual(load[Code.allLoadCases.count - 1], Code.allLoadCases.count - 1 + ChartboostMediationError.Code.Group.load.rawValue)

        let show = Code.allShowCases.map(\.rawValue).sorted()
        XCTAssertEqual(show[0], ChartboostMediationError.Code.Group.show.rawValue)
        XCTAssertEqual(show[Code.allShowCases.count - 1], Code.allShowCases.count - 1 + ChartboostMediationError.Code.Group.show.rawValue)

        let invalidate = Code.allInvalidateCases.map(\.rawValue).sorted()
        XCTAssertEqual(invalidate[0], ChartboostMediationError.Code.Group.invalidate.rawValue)
        XCTAssertEqual(invalidate[Code.allInvalidateCases.count - 1], Code.allInvalidateCases.count - 1 + ChartboostMediationError.Code.Group.invalidate.rawValue)

        let others = Code.allOtherCases.map(\.rawValue).sorted()
        XCTAssertEqual(others[0], ChartboostMediationError.Code.Group.others.rawValue)
        XCTAssertEqual(others[Code.allOtherCases.count - 1], Code.allOtherCases.count - 1 + ChartboostMediationError.Code.Group.others.rawValue)
    }

    // TDD test callout: For each range from 1XX to 6XX (for now), there must be at least 2 defined Chartboost Mediation error code (1 is a generic one, the other a specific one)
    // Note: "generic" is presumed to be the code that is X00 and the specific ones are XYY where YY is not 00
    func testMinimumErrorCodesPerGroup() {
        let initialization = Code.allInitializationCases.map(\.rawValue)
        XCTAssertTrue(initialization.count >= 2)
        XCTAssertTrue(initialization.filter({$0 == 100}).count == 1)
        XCTAssertTrue(initialization.filter({$0 == 200}).count == 0)
        XCTAssertTrue(initialization.filter({$0 == 300}).count == 0)
        XCTAssertTrue(initialization.filter({$0 == 400}).count == 0)
        XCTAssertTrue(initialization.filter({$0 == 500}).count == 0)
        XCTAssertTrue(initialization.filter({$0 == 600}).count == 0)

        let prebid = Code.allPrebidCases.map(\.rawValue)
        XCTAssertTrue(prebid.count >= 2)
        XCTAssertTrue(prebid.filter({$0 == 200}).count == 1)
        XCTAssertTrue(prebid.filter({$0 == 100}).count == 0)
        XCTAssertTrue(prebid.filter({$0 == 300}).count == 0)
        XCTAssertTrue(prebid.filter({$0 == 400}).count == 0)
        XCTAssertTrue(prebid.filter({$0 == 500}).count == 0)
        XCTAssertTrue(prebid.filter({$0 == 600}).count == 0)

        let load = Code.allLoadCases.map(\.rawValue)
        XCTAssertTrue(load.count >= 2)
        XCTAssertTrue(load.filter({$0 == 300}).count == 1)
        XCTAssertTrue(load.filter({$0 == 100}).count == 0)
        XCTAssertTrue(load.filter({$0 == 200}).count == 0)
        XCTAssertTrue(load.filter({$0 == 400}).count == 0)
        XCTAssertTrue(load.filter({$0 == 500}).count == 0)
        XCTAssertTrue(load.filter({$0 == 600}).count == 0)

        let show = Code.allShowCases.map(\.rawValue)
        XCTAssertTrue(show.count >= 2)
        XCTAssertTrue(show.filter({$0 == 400}).count == 1)
        XCTAssertTrue(show.filter({$0 == 100}).count == 0)
        XCTAssertTrue(show.filter({$0 == 200}).count == 0)
        XCTAssertTrue(show.filter({$0 == 300}).count == 0)
        XCTAssertTrue(show.filter({$0 == 500}).count == 0)
        XCTAssertTrue(show.filter({$0 == 600}).count == 0)

        let invalidate = Code.allInvalidateCases.map(\.rawValue)
        XCTAssertTrue(invalidate.count >= 2)
        XCTAssertTrue(invalidate.filter({$0 == 500}).count == 1)
        XCTAssertTrue(invalidate.filter({$0 == 100}).count == 0)
        XCTAssertTrue(invalidate.filter({$0 == 200}).count == 0)
        XCTAssertTrue(invalidate.filter({$0 == 300}).count == 0)
        XCTAssertTrue(invalidate.filter({$0 == 400}).count == 0)
        XCTAssertTrue(invalidate.filter({$0 == 600}).count == 0)

        let other = Code.allOtherCases.map(\.rawValue)
        XCTAssertTrue(other.count >= 2)
        XCTAssertTrue(other.filter({$0 == 600}).count == 1)
        XCTAssertTrue(other.filter({$0 == 100}).count == 0)
        XCTAssertTrue(other.filter({$0 == 200}).count == 0)
        XCTAssertTrue(other.filter({$0 == 300}).count == 0)
        XCTAssertTrue(other.filter({$0 == 400}).count == 0)
        XCTAssertTrue(other.filter({$0 == 500}).count == 0)
    }
}

extension ChartboostMediationError.Code {
    static var allInitializationCases: [Self] { Self.allCases.filter({ $0.rawValue >= 100 && $0.rawValue < 200 }) }
    static var allPrebidCases: [Self] { Self.allCases.filter({ $0.rawValue >= 200 && $0.rawValue < 300 }) }
    static var allLoadCases: [Self] { Self.allCases.filter({ $0.rawValue >= 300 && $0.rawValue < 400 }) }
    static var allShowCases: [Self] { Self.allCases.filter({ $0.rawValue >= 400 && $0.rawValue < 500 }) }
    static var allInvalidateCases: [Self] { Self.allCases.filter({ $0.rawValue >= 500 && $0.rawValue < 600 }) }
    static var allOtherCases: [Self] { Self.allCases.filter({ $0.rawValue >= 600 && $0.rawValue < 700 }) }

    struct ExpectedData {
        let codeString: String
        let constant: String
        let message: String
        let cause: String
        let resolution: String

        init(_ string: [String]) {
            codeString = string[0]
            constant = string[1]
            message = string[2]
            cause = string[3]
            resolution = string[4]
        }
    }

    static let defaultInitMessage = "Partner initialization has failed."
    static let defaultPrebidMessage = "Partner token fetch has failed."
    static let defaultLoadMessage = "Partner ad load has failed."
    static let defaultShowMessage = "Partner ad show has failed."
    static let defaultInvalidateMessage = "Partner ad invalidation has failed."
    static let defaultUnknownMessage = "An unknown error has occurred. It is unclear if it originates from Chartboost Mediation or mediation partner(s)."

    // https://chartboost.atlassian.net/wiki/spaces/HM/pages/2551513299/Helium+Error+Codes+Helium+4.0.0
    static let rawExpectedData: [Self: ExpectedData] = [
        // 100
        .initializationFailureUnknown: ExpectedData(["CM_100", "CM_INITIALIZATION_FAILURE_UNKNOWN", "Chartboost Mediation initialization has failed.", "There was an error that was not accounted for.", "Try again. If the problem persists, contact Chartboost Mediation Support and provide your console logs."]),
        .initializationFailureAborted: ExpectedData(["CM_101", "CM_INITIALIZATION_FAILURE_ABORTED", defaultInitMessage, "The initialization process started but was aborted midway prior to completion.", "Contact Chartboost Mediation Support and/or the mediation partner and provide a copy of your console logs."]),
        .initializationFailureAdBlockerDetected: ExpectedData(["CM_102", "CM_INITIALIZATION_FAILURE_AD_BLOCKER_DETECTED", defaultInitMessage, "An ad blocker was detected.", "N/A."]),
        .initializationFailureAdapterNotFound: ExpectedData(["CM_103", "CM_INITIALIZATION_FAILURE_ADAPTER_NOT_FOUND", defaultInitMessage, "The adapter instance responsible to initialize this partner is no longer in memory.", "This is an internal error. Contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .initializationFailureInvalidAppConfig: ExpectedData(["CM_104", "CM_INITIALIZATION_FAILURE_INVALID_APP_CONFIG", defaultInitMessage, "Chartboost Mediation received an invalid app config payload from the ad server.", "If this problem persists, reach out to the Chartboost Mediation team for further assistance. If possible, always forward us a copy of Chartboost Mediation network traffic."]),
        .initializationFailureInvalidCredentials: ExpectedData(["CM_105", "CM_INITIALIZATION_FAILURE_INVALID_CREDENTIALS", defaultInitMessage, "Invalid/empty credentials were supplied to initialize the partner.", "Ensure appropriate fields are correctly entered on the Chartboost Mediation dashboard."]),
        .initializationFailureNoConnectivity: ExpectedData(["CM_106", "CM_INITIALIZATION_FAILURE_NO_CONNECTIVITY", defaultInitMessage, "No Internet connectivity was available.", "Ensure there is Internet connectivity and try again."]),
        .initializationFailurePartnerNotIntegrated: ExpectedData(["CM_107", "CM_INITIALIZATION_FAILURE_PARTNER_NOT_INTEGRATED", defaultInitMessage, "The partner adapter and/or SDK might not have been properly integrated.", "Check your adapter/SDK integration. If this error persists, contact Chartboost Mediation Support and provide a minimal reproducible build."]),
        .initializationFailureTimeout: ExpectedData(["CM_108", "CM_INITIALIZATION_FAILURE_TIMEOUT", defaultInitMessage, "The initialization operation has taken too long to complete.", "This should not be a critical error. Typically the partner can continue to finish initialization in the background. If this error persists, contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .initializationSkipped: ExpectedData(["CM_109", "CM_INITIALIZATION_SKIPPED", "Partner initialization was skipped.", "You explicitly skipped initializing the partner.", "N/A."]),
        .initializationFailureException: ExpectedData(["CM_110", "CM_INITIALIZATION_FAILURE_EXCEPTION", defaultInitMessage, "An exception was thrown during initialization.", "Check your console logs for more details. If this error persists, contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .initializationFailureViewControllerNotFound: ExpectedData(["CM_111", "CM_INITIALIZATION_FAILURE_VIEW_CONTROLLER_NOT_FOUND", defaultInitMessage, "There is no View Controller with which to initialize the partner.", "Ensure that the a view controller is provided during initialization."]),
        .initializationFailureNetworkingError: ExpectedData(["CM_112", "CM_INITIALIZATION_FAILURE_NETWORKING_ERROR", "Chartboost Mediation initialization has failed.", "Init request failed due to a networking error.", "Typically this error should resolve by itself. If the error persists, contact Chartboost Mediation support and share a copy of your network traffic logs."]),
        .initializationFailureOSVersionNotSupported: ExpectedData(["CM_113", "CM_INITIALIZATION_FAILURE_OS_VERSION_NOT_SUPPORTED", "Partner initialization has failed.", "The partner does not support this OS version.", "This is an expected error and can be ignored. Devices running newer OS versions should work fine."]),
        .initializationFailureServerError: ExpectedData(["CM_114", "CM_INITIALIZATION_FAILURE_SERVER_ERROR", "Partner initialization has failed.", "The initialization request failed due to a server error.", "If this problem persists, reach out to Chartboost Mediation Support and/or the mediation partner team for further assistance. If possible, always share a copy of your network traffic logs."]),
        .initializationFailureInternalError: ExpectedData(["CM_115", "CM_INITIALIZATION_FAILURE_INTERNAL_ERROR", "Chartboost Mediation initialization has failed.", "An error occurred within the Chartboost Mediation initialization sequence.", "This is an internal error. Contact Chartboost Mediation Support and provide a copy of your console logs."]),

        // 200
        .prebidFailureUnknown: ExpectedData(["CM_200", "CM_PREBID_FAILURE_UNKNOWN", defaultPrebidMessage, "There was an error that was not accounted for.", "Try again. If the problem persists, contact Chartboost Mediation Support and provide your console logs."]),
        .prebidFailureAdapterNotFound: ExpectedData(["CM_201", "CM_PREBID_FAILURE_ADAPTER_NOT_FOUND", defaultPrebidMessage, "The adapter instance responsible to this token fetch is no longer in memory.", "This is an internal error. Contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .prebidFailureInvalidArgument: ExpectedData(["CM_202", "CM_PREBID_FAILURE_INVALID_ARGUMENT", defaultPrebidMessage, "Required data is missing.", "This is an internal error. Contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .prebidFailureNotInitialized: ExpectedData(["CM_203", "CM_PREBID_FAILURE_NOT_INITIALIZED", defaultPrebidMessage, "The partner was not able to call its bidding APIs because it was not initialized, either because you have explicitly skipped its initialization or there were issues initializing it.", "If this network supports bidding and you have explicitly skipped its initialization, allow it to initialize. Otherwise, try to re-initialize it."]),
        .prebidFailurePartnerNotIntegrated: ExpectedData(["CM_204", "CM_PREBID_FAILURE_PARTNER_NOT_INTEGRATED", defaultPrebidMessage, "The partner adapter and/or SDK might not have been properly integrated.", "Check your adapter/SDK integration. If this error persists, contact Chartboost Mediation Support and provide a minimal reproducible build."]),
        .prebidFailureTimeout: ExpectedData(["CM_205", "CM_PREBID_FAILURE_TIMEOUT", defaultPrebidMessage, "The token fetch operation has taken too long to complete.", "Try again. Typically, this issue should resolve itself. If the issue persists, contact the mediation partner and provide a copy of your console logs."]),
        .prebidFailureException: ExpectedData(["CM_206", "CM_PREBID_FAILURE_EXCEPTION", defaultPrebidMessage, "An exception was thrown during token fetch.", "Check your console logs for more details. If this error persists, contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .prebidFailureOSVersionNotSupported: ExpectedData(["CM_207", "CM_PREBID_FAILURE_OS_VERSION_NOT_SUPPORTED", defaultPrebidMessage, "The partner does not support this OS version.", "This is an expected error and can be ignored. Devices running newer OS versions should work fine."]),
        .prebidFailureNetworkingError: ExpectedData(["CM_208", "CM_PREBID_FAILURE_NETWORKING_ERROR", defaultPrebidMessage, "Prebid request failed due to a networking error.", "Typically this error should resolve by itself. If the error persists, contact Chartboost Mediation Support and/or the mediation partner team and share a copy of your network traffic logs."]),

        // 300
        .loadFailureUnknown: ExpectedData(["CM_300", "CM_LOAD_FAILURE_UNKNOWN", defaultLoadMessage, "There was an error that was not accounted for.", "Try again. If the problem persists, contact Chartboost Mediation Support and provide your console logs."]),
        .loadFailureAborted: ExpectedData(["CM_301", "CM_LOAD_FAILURE_ABORTED", defaultLoadMessage, "The ad load process started but was aborted midway prior to completion.", "Contact Chartboost Mediation Support and/or the mediation partner and provide a copy of your console logs."]),
        .loadFailureAdBlockerDetected: ExpectedData(["CM_302", "CM_LOAD_FAILURE_AD_BLOCKER_DETECTED", defaultLoadMessage, "An ad blocker was detected.", "N/A."]),
        .loadFailureAdapterNotFound: ExpectedData(["CM_303", "CM_LOAD_FAILURE_ADAPTER_NOT_FOUND", defaultLoadMessage, "The adapter instance responsible to this load operation is no longer in memory.", "This is an internal errror. Contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .loadFailureAuctionNoBid: ExpectedData(["CM_304", "CM_LOAD_FAILURE_AUCTION_NO_BID", defaultLoadMessage, "The auction for this ad request did not succeed.", "Try again. Typically, this issue should resolve itself. If the issue persists, contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .loadFailureAuctionTimeout: ExpectedData(["CM_305", "CM_LOAD_FAILURE_AUCTION_TIMEOUT", defaultLoadMessage, "The auction for this ad request has taken too long to complete.", "Try again. Typically, this issue should resolve itself. If the issue persists, contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .loadFailureInvalidAdMarkup: ExpectedData(["CM_306", "CM_LOAD_FAILURE_INVALID_AD_MARKUP", defaultLoadMessage, "The ad markup String is invalid.", "Contact Chartboost Mediation Support and/or the mediation partner and provide a copy of your network traffic logs."]),
        .loadFailureInvalidAdRequest: ExpectedData(["CM_307", "CM_LOAD_FAILURE_INVALID_AD_REQUEST", defaultLoadMessage, "The ad request is malformed.", "Contact Chartboost Mediation Support and/or the mediation partner and provide a copy of your network traffic logs."]),
        .loadFailureInvalidBidResponse: ExpectedData(["CM_308", "CM_LOAD_FAILURE_INVALID_BID_RESPONSE", defaultLoadMessage, "The auction for this ad request succeeded but the bid response is corrupt.", "Try again. Typically, this issue should resolve itself. If the issue persists, contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .loadFailureInvalidChartboostMediationPlacement: ExpectedData(["CM_309", "CM_LOAD_FAILURE_INVALID_CHARTBOOST_MEDIATION_PLACEMENT", defaultLoadMessage, "The Chartboost Mediation placement is invalid or empty.", "Ensure the Chartboost Mediation placement is properly defined on the Chartboost Mediation dashboard."]),
        .loadFailureInvalidPartnerPlacement: ExpectedData(["CM_310", "CM_LOAD_FAILURE_INVALID_PARTNER_PLACEMENT", defaultLoadMessage, "The partner placement is invalid or empty.", "Ensure the partner placement is properly defined on the Chartboost Mediation dashboard."]),
        .loadFailureMismatchedAdFormat: ExpectedData(["CM_311", "CM_LOAD_FAILURE_MISMATCHED_AD_FORMAT", defaultLoadMessage, "A placement for a different ad format was used in the ad request for the current ad format.", "Ensure you are using the correct placement for the correct ad format."]),
        .loadFailureNoConnectivity: ExpectedData(["CM_312", "CM_LOAD_FAILURE_NO_CONNECTIVITY", defaultLoadMessage, "No Internet connectivity was available.", "Ensure there is Internet connectivity and try again."]),
        .loadFailureNoFill: ExpectedData(["CM_313", "CM_LOAD_FAILURE_NO_FILL", defaultLoadMessage, "There is no ad inventory at this time.", "Try again but be mindful of CM_LOAD_FAILURE_RATE_LIMITED."]),
        .loadFailurePartnerNotInitialized: ExpectedData(["CM_314", "CM_LOAD_FAILURE_PARTNER_NOT_INITIALIZED", defaultLoadMessage, "The partner was not able to call its load APIs because it was not initialized, either because you have explicitly skipped its initialization or there were issues initializing it.", "If you would like to load and show ads from this partner, allow it to initialize or try to re-initialize it."]),
        .loadFailureOutOfStorage: ExpectedData(["CM_315", "CM_LOAD_FAILURE_OUT_OF_STORAGE", defaultLoadMessage, "The ad request might have succeeded but there was not enough storage to store the ad. Therefore this is treated as a failure.", "N/A."]),
        .loadFailurePartnerNotIntegrated: ExpectedData(["CM_316", "CM_LOAD_FAILURE_PARTNER_NOT_INTEGRATED", defaultLoadMessage, "The partner adapter and/or SDK might not have been properly integrated.", "Check your adapter/SDK integration. If this error persists, contact Chartboost Mediation Support and provide a minimal reproducible build."]),
        .loadFailureRateLimited: ExpectedData(["CM_317", "CM_LOAD_FAILURE_RATE_LIMITED", defaultLoadMessage, "Too many ad requests have been made over a short amount of time.", "Avoid continually making ad requests in a short amount of time. You may implement an exponential backoff strategy to help mitigate this issue."]),
        .loadFailureShowInProgress: ExpectedData(["CM_318", "CM_LOAD_FAILURE_SHOW_IN_PROGRESS", defaultLoadMessage, "An ad is already showing.", "You can only load another ad once the current ad is done showing."]),
        .loadFailureTimeout: ExpectedData(["CM_319", "CM_LOAD_FAILURE_TIMEOUT", defaultLoadMessage, "The ad request operation has taken too long to complete.", "If this issue persists, contact Chartboost Mediation Support and/or the mediation partner and provide a copy of your console logs."]),
        .loadFailureUnsupportedAdFormat: ExpectedData(["CM_320", "CM_LOAD_FAILURE_UNSUPPORTED_AD_FORMAT", defaultLoadMessage, "The partner does not support that ad format.", "Try again with a different ad format. If the ad format you are requesting for is supported by the partner, contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .loadFailurePrivacyOptIn: ExpectedData(["CM_321", "CM_LOAD_FAILURE_PRIVACY_OPT_IN", defaultLoadMessage, "One or more privacy settings have been opted in.", "N/A."]),
        .loadFailurePrivacyOptOut: ExpectedData(["CM_322", "CM_LOAD_FAILURE_PRIVACY_OPT_OUT", defaultLoadMessage, "One or more privacy settings have been opted out.", "N/A."]),
        .loadFailurePartnerInstanceNotFound: ExpectedData(["CM_323", "CM_LOAD_FAILURE_PARTNER_INSTANCE_NOT_FOUND", defaultLoadMessage, "The partner SDK instance is null.", "Check your adapter/SDK integration. If this error persists, contact Chartboost Mediation Support and provide a minimal reproducible build."]),
        .loadFailureMismatchedAdParams: ExpectedData(["CM_324", "CM_LOAD_FAILURE_MISMATCHED_AD_PARAMS", defaultLoadMessage, "The partner returned an ad with different ad parameters than the one requested.", "This is typically caused by a partner SDK bug. Contact the mediation partner and provide a copy of your console logs."]),
        .loadFailureInvalidBannerSize: ExpectedData(["CM_325", "CM_LOAD_FAILURE_INVALID_BANNER_SIZE", defaultLoadMessage, "The supplied banner size is invalid.", "Ensure the requested banner size is valid."]),
        .loadFailureException: ExpectedData(["CM_326", "CM_LOAD_FAILURE_EXCEPTION", defaultLoadMessage, "An exception was thrown during ad load.", "Check your console logs for more details. If this error persists, contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .loadFailureLoadInProgress: ExpectedData(["CM_327", "CM_LOAD_FAILURE_LOAD_IN_PROGRESS", defaultLoadMessage, "An ad is already loading.", "Wait until the current ad load is done before loading another ad."]),
        .loadFailureViewControllerNotFound: ExpectedData(["CM_328", "CM_LOAD_FAILURE_VIEW_CONTROLLER_NOT_FOUND", defaultLoadMessage, "There is no View Controller to load the ad in.", "Ensure that a view controller is provided during the load."]),
        .loadFailureNoInlineView: ExpectedData(["CM_329", "CM_LOAD_FAILURE_NO_INLINE_VIEW", defaultLoadMessage, "The partner returns an ad with no inline view to show.", "This is typically caused by a partner adapter bug. Contact the mediation partner and provide a copy of your console logs."]),
        .loadFailureNetworkingError: ExpectedData(["CM_330", "CM_LOAD_FAILURE_NETWORKING_ERROR", defaultLoadMessage, "Ad request failed due to a networking error.", "Typically this error should resolve by itself. If the error persists, contact Chartboost Mediation support and share a copy of your network traffic logs."]),
        .loadFailureChartboostMediationNotInitialized: ExpectedData(["CM_331", "CM_LOAD_FAILURE_CHARTBOOST_MEDIATION_NOT_INITIALIZED", defaultLoadMessage, "The Chartboost Mediation SDK was not initialized.", "Ensure the Chartboost Mediation SDK is initialized before loading ads."]),
        .loadFailureOSVersionNotSupported: ExpectedData(["CM_332", "CM_LOAD_FAILURE_OS_VERSION_NOT_SUPPORTED", defaultLoadMessage, "The partner does not support this OS version.", "This is an expected error and can be ignored. Devices running newer OS versions should work fine."]),
        .loadFailureServerError: ExpectedData(["CM_333", "CM_LOAD_FAILURE_SERVER_ERROR", defaultLoadMessage, "The load request failed due to a server error.", "If this problem persists, reach out to Chartboost Mediation Support and/or the mediation partner team for further assistance. If possible, always share a copy of your network traffic logs."]),
        .loadFailureInvalidCredentials: ExpectedData(["CM_334", "CM_LOAD_FAILURE_INVALID_CREDENTIALS", defaultLoadMessage, "Invalid/empty credentials were supplied to load the ad.", "Ensure appropriate fields are correctly entered on the partner dashboard."]),
        .loadFailureWaterfallExhaustedNoFill: ExpectedData(["CM_335", "CM_LOAD_FAILURE_WATERFALL_EXHAUSTED_NO_FILL", "All waterfall entries have been exhausted. No ad fill.", "All waterfall entries have resulted in an error or no fill.", "Try again. If the problem persists, verify Partner settings in the Chartboost Mediation dashboard."]),
        .loadFailureAdTooLarge: ExpectedData(["CM_336", "CM_LOAD_FAILURE_AD_TOO_LARGE", defaultLoadMessage, "The partner ad dimension size is too large.", "Try again. If the problem persists, verify Partner settings in the Chartboost Mediation dashboard."]),

        // 400
        .showFailureUnknown: ExpectedData(["CM_400", "CM_SHOW_FAILURE_UNKNOWN", defaultShowMessage, "There was an error that was not accounted for.", "Try again. If the problem persists, contact Chartboost Mediation Support and provide your console logs."]),
        .showFailureViewControllerNotFound: ExpectedData(["CM_401", "CM_SHOW_FAILURE_VIEW_CONTROLLER_NOT_FOUND", defaultShowMessage, "There is no View Controller to show the ad in.", "Ensure that a view controller is provided during the show."]),
        .showFailureAdBlockerDetected: ExpectedData(["CM_402", "CM_SHOW_FAILURE_AD_BLOCKER_DETECTED", defaultShowMessage, "An ad blocker was detected.", "N/A."]),
        .showFailureAdNotFound: ExpectedData(["CM_403", "CM_SHOW_FAILURE_AD_NOT_FOUND", defaultShowMessage, "An ad that might have been cached is no longer available to show.", "Try loading another ad but be mindful of CM_LOAD_FAILURE_RATE_LIMITED."]),
        .showFailureAdExpired: ExpectedData(["CM_404", "CM_SHOW_FAILURE_AD_EXPIRED", defaultShowMessage, "The ad was expired by the partner SDK after a set time window.", "Try loading another ad but be mindful of CM_LOAD_FAILURE_RATE_LIMITED."]),
        .showFailureAdNotReady: ExpectedData(["CM_405", "CM_SHOW_FAILURE_AD_NOT_READY", defaultShowMessage, "There is no ad ready to show.", "Try loading another ad and ensure it is ready before it's shown."]),
        .showFailureAdapterNotFound: ExpectedData(["CM_406", "CM_SHOW_FAILURE_ADAPTER_NOT_FOUND", defaultShowMessage, "The adapter instance responsible to this show operation is no longer in memory.", "This is an internal error. Contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .showFailureInvalidChartboostMediationPlacement: ExpectedData(["CM_407", "CM_SHOW_FAILURE_INVALID_CHARTBOOST_MEDIATION_PLACEMENT", defaultShowMessage, "The Chartboost Mediation placement is invalid or empty.", "Ensure the Chartboost Mediation placement is properly defined on the Chartboost Mediation dashboard."]),
        .showFailureInvalidPartnerPlacement: ExpectedData(["CM_408", "CM_SHOW_FAILURE_INVALID_PARTNER_PLACEMENT", defaultShowMessage, "The partner placement is invalid or empty.", "Ensure the partner placement is properly defined on the Chartboost Mediation dashboard."]),
        .showFailureMediaBroken: ExpectedData(["CM_409", "CM_SHOW_FAILURE_MEDIA_BROKEN", defaultShowMessage, "The media associated with this ad is corrupt and cannot be rendered.", "Try loading another ad. If this problem persists, contact the mediation partner and provide a copy of your console and network traffic logs."]),
        .showFailureNoConnectivity: ExpectedData(["CM_410", "CM_SHOW_FAILURE_NO_CONNECTIVITY", defaultShowMessage, "No Internet connectivity was available.", "Ensure there is Internet connectivity and try again."]),
        .showFailureNoFill: ExpectedData(["CM_411", "CM_SHOW_FAILURE_NO_FILL", defaultShowMessage, "There is no ad inventory at this time.", "Try loading another ad but be mindful of CM_LOAD_FAILURE_RATE_LIMITED."]),
        .showFailureNotInitialized: ExpectedData(["CM_412", "CM_SHOW_FAILURE_NOT_INITIALIZED", defaultShowMessage, "The partner was not able to call its show APIs because it was not initialized, either because you have explicitly skipped its initialization or there were issues initializing it.", "If you would like to load and show ads from this partner, allow it to initialize or try to re-initialize it."]),
        .showFailureNotIntegrated: ExpectedData(["CM_413", "CM_SHOW_FAILURE_NOT_INTEGRATED", defaultShowMessage, "The partner adapter and/or SDK might not have been properly integrated.", "Check your adapter/SDK integration. If this error persists, contact Chartboost Mediation Support and provide a minimal reproducible build."]),
        .showFailureShowInProgress: ExpectedData(["CM_414", "CM_SHOW_FAILURE_SHOW_IN_PROGRESS", defaultShowMessage, "An ad is already showing.", "You cannot show multiple fullscreen ads simultaneously. Wait until the current ad is done showing before showing another ad."]),
        .showFailureTimeout: ExpectedData(["CM_415", "CM_SHOW_FAILURE_TIMEOUT", defaultShowMessage, "The show operation has taken too long to complete.", "If this issue persists, contact Chartboost Mediation Support and/or the mediation partner and provide a copy of your console logs."]),
        .showFailureVideoPlayerError: ExpectedData(["CM_416", "CM_SHOW_FAILURE_VIDEO_PLAYER_ERROR", defaultShowMessage, "There was an error with the video player.", "Contact Chartboost Mediation Support or the mediation partner and provide details of your integration."]),
        .showFailurePrivacyOptIn: ExpectedData(["CM_417", "CM_SHOW_FAILURE_PRIVACY_OPT_IN", defaultShowMessage, "One or more privacy settings have been opted in.", "N/A."]),
        .showFailurePrivacyOptOut: ExpectedData(["CM_418", "CM_SHOW_FAILURE_PRIVACY_OPT_OUT", defaultShowMessage, "One or more privacy settings have been opted out.", "N/A."]),
        .showFailureWrongResourceType: ExpectedData(["CM_419", "CM_SHOW_FAILURE_WRONG_RESOURCE_TYPE", defaultShowMessage, "A resource was found but it doesn't match the ad type to be shown.", "This is an internal error. Typically, it should resolve itself. If this issue persists, contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .showFailureUnsupportedAdType: ExpectedData(["CM_420", "CM_SHOW_FAILURE_UNSUPPORTED_AD_FORMAT", defaultShowMessage, "The ad format is not supported by the partner SDK.", "Try again with a different ad format. If the ad format you are requesting for is supported by the partner, contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .showFailureException: ExpectedData(["CM_421", "CM_SHOW_FAILURE_EXCEPTION", defaultShowMessage, "An exception was thrown during ad show.", "Check your console logs for more details. If this error persists, contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .showFailureUnsupportedAdSize: ExpectedData(["CM_422", "CM_SHOW_FAILURE_UNSUPPORTED_AD_SIZE", defaultShowMessage, "The ad size is not supported by the partner SDK.", "If this issue persists, contact the mediation partner and provide a copy of your console logs."]),
        .showFailureInvalidBannerSize: ExpectedData(["CM_423", "CM_SHOW_FAILURE_INVALID_BANNER_SIZE", defaultShowMessage, "The supplied banner size is invalid.", "Ensure the requested banner size is valid."]),

        // 500
        .invalidateFailureUnknown: ExpectedData(["CM_500", "CM_INVALIDATE_FAILURE_UNKNOWN", defaultInvalidateMessage, "There was an error that was not accounted for.", "Try again. If the problem persists, contact Chartboost Mediation Support and provide your console logs."]),
        .invalidateFailureAdNotFound: ExpectedData(["CM_501", "CM_INVALIDATE_FAILURE_AD_NOT_FOUND", defaultInvalidateMessage, "There is no ad to invalidate.", "N/A."]),
        .invalidateFailureAdapterNotFound: ExpectedData(["CM_502", "CM_INVALIDATE_FAILURE_ADAPTER_NOT_FOUND", defaultInvalidateMessage, "The adapter instance responsible to this show operation is no longer in memory.", "This is an internal error. Contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .invalidateFailureNotInitialized: ExpectedData(["CM_503", "CM_INVALIDATE_FAILURE_NOT_INITIALIZED", defaultInvalidateMessage, "The partner was not able to call its invalidate APIs because it was not initialized, either because you have explicitly skipped its initialization or there were issues initializing it.", "If this network supports ad invalidation and you have explicitly skipped its initialization, allow it to initialize. Otherwise, try to re-initialize it."]),
        .invalidateFailurePartnerNotIntegrated: ExpectedData(["CM_504", "CM_INVALIDATE_FAILURE_PARTNER_NOT_INTEGRATED", defaultInvalidateMessage, "The partner adapter and/or SDK might not have been properly integrated.", "Check your adapter/SDK integration. If this error persists, contact Chartboost Mediation Support and provide a minimal reproducible build."]),
        .invalidateFailureTimeout: ExpectedData(["CM_505", "CM_INVALIDATE_FAILURE_TIMEOUT", defaultInvalidateMessage, "The invalidate operation has taken too long to complete.", "If this issue persists, contact Chartboost Mediation Support and/or the mediation partner and provide a copy of your console logs."]),
        .invalidateFailureWrongResourceType: ExpectedData(["CM_506", "CM_INVALIDATE_FAILURE_WRONG_RESOURCE_TYPE", defaultInvalidateMessage, "A resource was found but it doesn't match the ad type to be invalidated.", "This is an internal error. Typically, it should resolve itself. If this issue persists, contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .invalidateFailureException: ExpectedData(["CM_507", "CM_INVALIDATE_FAILURE_EXCEPTION", defaultInvalidateMessage, "An exception was thrown during ad invalidation.", "Check your console logs for more details. If this error persists, contact Chartboost Mediation Support and provide a copy of your console logs."]),

        // 600
        .unknown: ExpectedData(["CM_600", "CM_UNKNOWN_ERROR", defaultUnknownMessage, "There is no known cause.", "No information is available about this error."]),
        .partnerError: ExpectedData(["CM_601", "CM_PARTNER_ERROR", "The partner has returned an error.", "Unknown.", "The Chartboost Mediation SDK does not have insights into this type of error. Contact the mediation partner and provide details of your integration."]),
        .internal: ExpectedData(["CM_602", "CM_INTERNAL_ERROR", "An internal error has occurred.", "Unknown.", "This is an internal error. Contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .noConnectivity: ExpectedData(["CM_603", "CM_NO_CONNECTIVITY", "No Internet connectivity was available.", "Unknown.", "Ensure there is Internet connectivity and try again."]),
        .adServerError: ExpectedData(["CM_604", "CM_AD_SERVER_ERROR", "An ad server issue has occurred.", "Unknown.", "This is an internal error. Contact Chartboost Mediation Support and provide a copy of your console logs."]),
        .invalidArguments: ExpectedData(["CM_605", "CM_INVALID_ARGUMENTS", "Invalid/empty arguments were passed to the function call, which caused the function to terminate prematurely.", "Unknown.", "Depending on when this error occurs, it could be due to an issue in Chartboost Mediation or mediation partner(s) or your integration. Contact Chartboost Mediation Support and provide a copy of your console logs."]),
    ]
}
