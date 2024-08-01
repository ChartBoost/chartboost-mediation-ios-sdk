// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK
import Foundation

/// Factory to create a ``AuctionsHTTPRequest`` model using the information provided by
/// the publisher, partners, and the current environment.
protocol AuctionsHTTPRequestFactory {
    /// Generates the request in a thread-safe manner.
    /// - parameter request: The ad load request model
    /// - parameter loadRateLimit: The current load rate limit for the placement.
    /// - parameter bidderInformation: The partner bid tokens.
    /// - parameter completion: The handler that takes in the generated request.
    func makeRequest(
        request: InternalAdLoadRequest,
        loadRateLimit: TimeInterval,
        bidderInformation: BidderInformation,
        completion: @escaping (AuctionsHTTPRequest) -> Void
    )
}

/// Mediation's concrete implementation of ``AuctionsHTTPRequestFactory``.
struct MediationAuctionsHTTPRequestFactory: AuctionsHTTPRequestFactory {
    @Injected(\.consentSettings) private var consentSettings
    @Injected(\.environment) private var environment
    @Injected(\.privacyConfiguration) var privacyConfig
    @Injected(\.taskDispatcher) private var taskDispatcher

    func makeRequest(
        request: InternalAdLoadRequest,
        loadRateLimit: TimeInterval,
        bidderInformation: BidderInformation,
        completion: @escaping (AuctionsHTTPRequest) -> Void
    ) {
        taskDispatcher.async(on: .main) {   // execute on main to prevent issues when accessing UIKit APIs via the environment
            completion(
                AuctionsHTTPRequest(
                    adFormat: request.adFormat,
                    bidRequest: makeBidRequest(request: request, bidderInformation: bidderInformation),
                    loadRateLimit: Int(loadRateLimit),
                    loadID: request.loadID,
                    queueID: request.queueID
                )
            )
        }
    }

    private func makeBidRequest(request: InternalAdLoadRequest, bidderInformation: BidderInformation) -> OpenRTB.BidRequest {
        OpenRTB.BidRequest(
            imp: [makeImpression(request: request)],
            app: makeApp(),
            device: makeDevice(),
            user: makeUser(request: request),
            regs: makeRegulations(),
            ext: makeExtension(request: request, bidderInformation: bidderInformation),
            test: environment.testMode.isTestModeEnabled.intValue
        )
    }

    private func makeApp() -> OpenRTB.App {
        var ext: OpenRTB.App.Extension?
        if environment.app.gameEngineName != nil || environment.app.gameEngineVersion != nil {
            ext = OpenRTB.App.Extension(
                game_engine_name: environment.app.gameEngineName,
                game_engine_version: environment.app.gameEngineVersion
            )
        }
        return OpenRTB.App(
            id: environment.app.chartboostAppID,
            bundle: environment.app.bundleID,
            ver: environment.app.appVersion,
            ext: ext
        )
    }

    private func makeDevice() -> OpenRTB.Device {
        let ext = OpenRTB.Device.Extension(
            ifv: environment.appTracking.idfv,
            atts: environment.appTracking.appTransparencyAuthStatus,
            inputLanguage: environment.userSettings.inputLanguages,
            networktype: environment.telephonyNetwork.networkTypes,
            audiooutputtype: environment.audio.audioOutputTypes,
            audioinputtype: environment.audio.audioInputTypes,
            audiovolume: environment.audio.audioVolume,
            screenbright: environment.screen.screenBrightness,
            batterylevel: environment.device.batteryLevel,
            charging: environment.device.isBatteryCharging.intValue,
            darkmode: environment.screen.isDarkModeEnabled.intValue,
            totaldisk: environment.device.totalDiskSpace,
            diskspace: environment.device.freeDiskSpace,
            textsize: environment.userSettings.textSize,
            boldtext: environment.userSettings.isBoldTextEnabled.intValue
        )

        var mccmnc: String?
        if let mobileCountryCode = environment.telephonyNetwork.mobileCountryCode,
           !mobileCountryCode.isEmpty,
           let mobileNetworkCode = environment.telephonyNetwork.mobileNetworkCode,
           !mobileNetworkCode.isEmpty {
            mccmnc = "\(mobileCountryCode)-\(mobileNetworkCode)"
        }

        let utcoffset: Int?
        if #available(iOS 17.0, *) {
            if privacyConfig.privacyBanList.contains(.timeZone) {
                utcoffset = nil
            } else {
                utcoffset = TimeZone.current.secondsFromGMT(for: Date()) / 60
            }
        } else {
            utcoffset = TimeZone.current.secondsFromGMT(for: Date()) / 60
        }

        let geo = OpenRTB.Device.Geo(utcoffset: utcoffset)

        return OpenRTB.Device(
            ua: environment.userAgent.userAgent ?? "ua",
            lmt: environment.appTracking.isLimitAdTrackingEnabled.intValue,
            devicetype: environment.device.deviceType == .iPhone ? .phone : .tablet,
            make: environment.device.deviceMake,
            model: environment.device.deviceModel,
            os: environment.device.osName,
            osv: environment.device.osVersion,
            h: Int(environment.screen.screenHeight),
            w: Int(environment.screen.screenWidth),
            pxratio: environment.screen.pixelRatio,
            language: environment.userSettings.languageCode,
            carrier: environment.telephonyNetwork.carrierName,
            mccmnc: mccmnc,
            connectiontype: OpenRTB.Device.ConnectionType(rawValue: environment.telephonyNetwork.connectionType.rawValue) ?? .unknown,
            ifa: environment.appTracking.idfa,
            geo: geo,
            ext: ext
        )
    }

    private func makeImpression(request: InternalAdLoadRequest) -> OpenRTB.Impression {
        let size = request.adSize?.size ?? CGSize(
            width: environment.screen.screenWidth,
            height: environment.screen.screenHeight
        )

        let video = OpenRTB.Impression.Video(
            mimes: ["video/mp4"],
            w: Int(size.width),
            h: Int(size.height),
            placement: request.adFormat.isBanner ? .inBanner : .interstitialSliderOrFloating,
            pos: request.adFormat.isBanner ? .footer : .fullScreen,
            companiontype: [.staticResource, .htmlResource],
            ext: OpenRTB.Impression.Video.Extension(placementtype: request.adFormat.rawValue)
        )

        let banner = OpenRTB.Impression.Banner(
            w: Int(size.width),
            h: Int(size.height),
            pos: request.adFormat.isBanner ? .footer : .fullScreen,
            topframe: 1, // 1 == top
            ext: OpenRTB.Impression.Banner.Extension(placementtype: request.adFormat.rawValue)
        )

        return OpenRTB.Impression(
            displaymanager: environment.sdk.sdkName,
            displaymanagerver: environment.sdk.sdkVersion,
            instl: (!request.adFormat.isBanner).intValue,
            tagid: request.mediationPlacement,
            secure: true.intValue,
            video: video,
            banner: banner
        )
    }

    private func makeRegulations() -> OpenRTB.Regulations {
        .init(
            coppa: consentSettings.isUserUnderage ? 1 : 0,
            ext: .init(
                gdpr: consentSettings.gdprApplies == true ? 1 : 0,
                us_privacy: consentSettings.consents[ConsentKeys.usp]
            )
        )
    }

    private func makeUser(request: InternalAdLoadRequest) -> OpenRTB.User {
        let impdepth: Int
        switch request.adFormat {
        case .banner, .adaptiveBanner:
            impdepth = environment.impressionCounter.bannerImpressionCount
        case .interstitial:
            impdepth = environment.impressionCounter.interstitialImpressionCount
        case .rewarded, .rewardedInterstitial:
            impdepth = environment.impressionCounter.rewardedImpressionCount
        }

        let consent: String?
        switch consentSettings.consents[ConsentKeys.gdprConsentGiven] {
        case ConsentValues.granted: consent = "1"
        case ConsentValues.denied: consent = "0"
        default: consent = nil
        }

        let ext = OpenRTB.User.Extension(
            consent: consent,
            sessionduration: UInt(environment.session.elapsedSessionDuration),
            impdepth: UInt(impdepth),
            keywords: request.keywords,
            publisher_user_id: environment.userIDProvider.publisherUserID
        )

        return OpenRTB.User(
            id: environment.userIDProvider.userID,
            consent: consentSettings.consents[ConsentKeys.tcf],
            ext: ext
        )
    }

    private func makeExtension(request: InternalAdLoadRequest, bidderInformation: BidderInformation) -> OpenRTB.BidRequest.Extension {
        let skadn = OpenRTB.BidRequest.StoreKitAdNetworks(
            version: environment.skAdNetwork.skAdNetworkVersion,
            skadnetids: environment.skAdNetwork.skAdNetworkIDs
        )
        return OpenRTB.BidRequest.Extension(
            bidders: bidderInformation,
            helium_sdk_request_id: request.loadID,
            skadn: skadn
        )
    }
}

extension Bool {
    fileprivate var intValue: Int { self ? 1 : 0 }
}
