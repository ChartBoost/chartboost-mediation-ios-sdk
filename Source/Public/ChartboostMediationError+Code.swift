// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

extension ChartboostMediationError {

    /// Chartboost Mediation SDK error codes.
    @objc(CBMErrorCode)
    public enum Code: Int, CaseIterable {
        /// Categories of errors.
        public enum Group: Int {
            /// Errors that occur during SDK initialization.
            case initialization = 100

            /// Errors that occur during prebid.
            case prebid = 200

            /// Errors that occur during ad load.
            case load = 300

            /// Errors that occur during ad show.
            case show = 400

            /// Errors that occur during ad invalidation.
            case invalidate = 500

            /// All other errors.
            case others = 600
        }

        /// The group that this error belongs to.
        public var group: Group {
            let groupCode = (rawValue / 100) * 100
            return Group(rawValue: groupCode) ?? .others
        }

        // MARK: - 100: Initialization

        /// There was an error that was not accounted for.
        case initializationFailureUnknown = 100

        /// The initialization process started but was aborted midway prior to completion.
        case initializationFailureAborted = 101

        /// An ad blocker was detected.
        case initializationFailureAdBlockerDetected = 102

        /// The adapter instance responsible to initialize this partner is no longer in memory.
        case initializationFailureAdapterNotFound = 103

        /// Chartboost Mediation received an invalid app config payload from the ad server.
        case initializationFailureInvalidAppConfig = 104

        /// Invalid/empty credentials were supplied to initialize the partner.
        case initializationFailureInvalidCredentials = 105

        /// No Internet connectivity was available.
        case initializationFailureNoConnectivity = 106

        /// The partner adapter and/or SDK might not have been properly integrated.
        case initializationFailurePartnerNotIntegrated = 107

        /// The initialization operation has taken too long to complete.
        case initializationFailureTimeout = 108

        /// You explicitly skipped initializing the partner.
        case initializationSkipped = 109

        /// An exception was thrown during initialization.
        case initializationFailureException = 110

        /// There is no View Controller with which to initialize the partner.
        case initializationFailureViewControllerNotFound = 111

        /// Init request failed due to a networking error.
        case initializationFailureNetworkingError = 112

        /// The partner does not support this OS version.
        case initializationFailureOSVersionNotSupported = 113

        /// The initialization request failed due to a server error.
        case initializationFailureServerError = 114

        /// An error occurred within the Chartboost Mediation initialization sequence.
        case initializationFailureInternalError = 115

        // MARK: - 200: Prebid

        /// There was an error that was not accounted for.
        case prebidFailureUnknown = 200

        /// The adapter instance responsible to this token fetch is no longer in memory.
        case prebidFailureAdapterNotFound = 201

        /// Required data is missing.
        case prebidFailureInvalidArgument = 202
        /// The partner was not able to call its bidding APIs because it was not initialized, either because
        /// you have explicitly skipped its initialization or there were issues initializing it.
        case prebidFailureNotInitialized = 203

        /// The partner adapter and/or SDK might not have been properly integrated.
        case prebidFailurePartnerNotIntegrated = 204

        /// The token fetch operation has taken too long to complete.
        case prebidFailureTimeout = 205

        /// An exception was thrown during token fetch.
        case prebidFailureException = 206

        /// The partner does not support this OS version.
        case prebidFailureOSVersionNotSupported = 207

        /// Prebid request failed due to a networking error.
        case prebidFailureNetworkingError = 208

        /// The partner does not support that ad format.
        case prebidFailureUnsupportedAdFormat = 209

        // MARK: - 300: Load

        /// There was an error that was not accounted for.
        case loadFailureUnknown = 300

        /// The ad load process started but was aborted midway prior to completion.
        case loadFailureAborted = 301

        /// An ad blocker was detected.
        case loadFailureAdBlockerDetected = 302

        /// The adapter instance responsible to this load operation is no longer in memory.
        case loadFailureAdapterNotFound = 303

        /// The auction for this ad request did not succeed.
        case loadFailureAuctionNoBid = 304

        /// The auction for this ad request has taken too long to complete.
        case loadFailureAuctionTimeout = 305

        /// The ad markup String is invalid.
        case loadFailureInvalidAdMarkup = 306

        /// The ad request is malformed.
        case loadFailureInvalidAdRequest = 307

        /// The auction for this ad request succeeded but the bid response is corrupt.
        case loadFailureInvalidBidResponse = 308

        /// The Chartboost Mediation placement is invalid or empty.
        case loadFailureInvalidChartboostMediationPlacement = 309

        /// The partner placement is invalid or empty.
        case loadFailureInvalidPartnerPlacement = 310

        /// A placement for a different ad format was used in the ad request for the current ad format.
        case loadFailureMismatchedAdFormat = 311

        /// No Internet connectivity was available.
        case loadFailureNoConnectivity = 312

        /// There is no ad inventory at this time.
        case loadFailureNoFill = 313
        /// The partner was not able to call its load APIs because it was not initialized, either because you
        /// have explicitly skipped its initialization or there were issues initializing it.
        case loadFailurePartnerNotInitialized = 314
        /// The ad request might have succeeded but there was not enough storage to store the ad. Therefore
        /// this is treated as a failure.
        case loadFailureOutOfStorage = 315

        /// The partner adapter and/or SDK might not have been properly integrated.
        case loadFailurePartnerNotIntegrated = 316

        /// Too many ad requests have been made over a short amount of time.
        case loadFailureRateLimited = 317

        /// An ad is already showing.
        case loadFailureShowInProgress = 318

        /// The ad request operation has taken too long to complete.
        case loadFailureTimeout = 319

        /// The partner does not support that ad format.
        case loadFailureUnsupportedAdFormat = 320

        /// One or more privacy settings have been opted in.
        case loadFailurePrivacyOptIn = 321

        /// One or more privacy settings have been opted out.
        case loadFailurePrivacyOptOut = 322

        /// The partner SDK instance is null.
        case loadFailurePartnerInstanceNotFound = 323

        /// The partner returned an ad with different ad parameters than the one requested.
        case loadFailureMismatchedAdParams = 324

        /// The supplied banner size is invalid.
        case loadFailureInvalidBannerSize = 325

        /// An exception was thrown during ad load.
        case loadFailureException = 326

        /// An ad is already loading.
        case loadFailureLoadInProgress = 327

        /// There is no View Controller to load the ad in.
        case loadFailureViewControllerNotFound = 328

        /// The partner returns a banner ad with no view to show.
        case loadFailureNoBannerView = 329

        /// Ad request failed due to a networking error.
        case loadFailureNetworkingError = 330

        /// The Chartboost Mediation SDK was not initialized.
        case loadFailureChartboostMediationNotInitialized = 331

        /// The partner does not support this OS version.
        case loadFailureOSVersionNotSupported = 332

        /// The load request failed due to a server error.
        case loadFailureServerError = 333

        /// Invalid/empty credentials were supplied to load the ad.
        case loadFailureInvalidCredentials = 334

        /// All waterfall entries have resulted in an error or no fill.
        case loadFailureWaterfallExhaustedNoFill = 335

        /// The returned ad was larger than the requested size.
        case loadFailureAdTooLarge = 336

        // MARK: - 400: Show

        /// There was an error that was not accounted for.
        case showFailureUnknown = 400

        /// There is no View Controller to show the ad in.
        case showFailureViewControllerNotFound = 401

        /// An ad blocker was detected.
        case showFailureAdBlockerDetected = 402

        /// An ad that might have been cached is no longer available to show.
        case showFailureAdNotFound = 403

        /// The ad was expired by the partner SDK after a set time window.
        case showFailureAdExpired = 404

        /// There is no ad ready to show.
        case showFailureAdNotReady = 405

        /// The adapter instance responsible to this show operation is no longer in memory.
        case showFailureAdapterNotFound = 406

        /// The Chartboost Mediation placement is invalid or empty.
        case showFailureInvalidChartboostMediationPlacement = 407

        /// The partner placement is invalid or empty.
        case showFailureInvalidPartnerPlacement = 408

        /// The media associated with this ad is corrupt and cannot be rendered.
        case showFailureMediaBroken = 409

        /// No Internet connectivity was available.
        case showFailureNoConnectivity = 410

        /// There is no ad inventory at this time.
        case showFailureNoFill = 411
        /// The partner was not able to call its show APIs because it was not initialized, either because you
        /// have explicitly skipped its initialization or there were issues initializing it.
        case showFailureNotInitialized = 412

        /// The partner adapter and/or SDK might not have been properly integrated.
        case showFailureNotIntegrated = 413

        /// An ad is already showing.
        case showFailureShowInProgress = 414

        /// The show operation has taken too long to complete.
        case showFailureTimeout = 415

        /// There was an error with the video player.
        case showFailureVideoPlayerError = 416

        /// One or more privacy settings have been opted in.
        case showFailurePrivacyOptIn = 417

        /// One or more privacy settings have been opted out.
        case showFailurePrivacyOptOut = 418

        /// A resource was found but it doesn't match the ad type to be shown.
        case showFailureWrongResourceType = 419

        /// The ad format is not supported by the partner SDK.
        case showFailureUnsupportedAdType = 420

        /// An exception was thrown during ad show.
        case showFailureException = 421

        /// The ad size is not supported by the partner SDK.
        case showFailureUnsupportedAdSize = 422

        /// The supplied banner size is invalid.
        case showFailureInvalidBannerSize = 423

        // MARK: - 500: Invalidate

        /// There was an error that was not accounted for.
        case invalidateFailureUnknown = 500

        /// There is no ad to invalidate.
        case invalidateFailureAdNotFound = 501

        /// The adapter instance responsible to this show operation is no longer in memory.
        case invalidateFailureAdapterNotFound = 502
        /// The partner was not able to call its invalidate APIs because it was not initialized, either
        /// because you have explicitly skipped its initialization or there were issues initializing it.
        case invalidateFailureNotInitialized = 503

        /// The partner adapter and/or SDK might not have been properly integrated.
        case invalidateFailurePartnerNotIntegrated = 504

        /// The invalidate operation has taken too long to complete.
        case invalidateFailureTimeout = 505

        /// A resource was found but it doesn't match the ad type to be invalidated.
        case invalidateFailureWrongResourceType = 506

        /// An exception was thrown during ad invalidation.
        case invalidateFailureException = 507

        // MARK: - 600: Other

        /// There is no known cause.
        case unknown = 600

        /// Unknown partner error.
        case partnerError = 601

        /// Unknown internal error.
        case `internal` = 602

        /// No connectivity.
        case noConnectivity = 603

        /// Ad server error.
        case adServerError = 604

        /// Invalid arguments.
        case invalidArguments = 605

        /// Preinitialization action failed.
        case preinitializationActionFailed = 606
    }
}
