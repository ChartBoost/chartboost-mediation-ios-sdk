// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

extension OpenRTB.BidRequest {
    @Injected(\.environment) private static var environment

    static func make(request: HeliumAdLoadRequest, bidderInformation: BidderInformation) -> Self {
        .init(
            imp: [.make(request: request)],
            app: .make(),
            device: .make(),
            user: .make(request: request),
            regs: .make(),
            ext: .make(request: request, bidderInformation: bidderInformation),
            test: environment.testMode.isTestModeEnabled.intValue
        )
    }
}

extension OpenRTB.App {
    @Injected(\.environment) private static var environment

    static func make() -> Self {
        var ext: Extension? = nil
        if environment.app.gameEngineName != nil || environment.app.gameEngineVersion != nil {
            ext = OpenRTB.App.Extension(
                game_engine_name: environment.app.gameEngineName,
                game_engine_version: environment.app.gameEngineVersion
            )
        }
        return OpenRTB.App(
            id: environment.app.appID,
            bundle: environment.app.bundleID,
            ver: environment.app.appVersion,
            ext: ext
        )
    }
}

extension OpenRTB.Device {
    @Injected(\.environment) private static var environment
    @Injected(\.consentSettings) private static var consentSettings

    static func make() -> Self {
        let ext = Extension(
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

        var mccmnc: String? = nil
        if let mobileCountryCode = environment.telephonyNetwork.mobileCountryCode,
           !mobileCountryCode.isEmpty,
           let mobileNetworkCode = environment.telephonyNetwork.mobileNetworkCode,
           !mobileNetworkCode.isEmpty {
            mccmnc = "\(mobileCountryCode)-\(mobileNetworkCode)"
        }

        let utcoffset = NSTimeZone.local.secondsFromGMT(for: Date()) / 60
        let geo = Geo(utcoffset: utcoffset)

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
            connectiontype: ConnectionType(rawValue: environment.telephonyNetwork.connectionType.rawValue) ?? .unknown,
            ifa: consentSettings.isSubjectToCOPPA == true ? nil : environment.appTracking.idfa,
            geo: geo,
            ext: ext
        )
    }
}

extension OpenRTB.Impression {
    @Injected(\.environment) private static var environment
    @Injected(\.consentSettings) private static var consentSettings

    static func make(request: HeliumAdLoadRequest) -> Self {

        let size = request.adSize ?? CGSize(
            width: environment.screen.screenWidth,
            height: environment.screen.screenHeight
        )

        let video = Video(
            mimes: ["video/mp4"],
            w: Int(size.width),
            h: Int(size.height),
            placement: request.adFormat == .banner ? .inBanner : .interstitialSliderOrFloating,
            pos: request.adFormat == .banner ? .footer : .fullScreen,
            companiontype: [.staticResource, .htmlResource],
            ext: Video.Extension(placementtype: request.adFormat.rawValue)
        )

        let banner = Banner(
            w: Int(size.width),
            h: Int(size.height),
            pos: request.adFormat == .banner ? .footer : .fullScreen,
            topframe: 1, // 1 == top
            ext: Banner.Extension(placementtype: request.adFormat.rawValue)
        )

        return OpenRTB.Impression(
            displaymanager: environment.sdk.sdkName,
            displaymanagerver: environment.sdk.sdkVersion,
            instl: (request.adFormat != .banner).intValue,
            tagid: request.heliumPlacement,
            secure: true.intValue,
            video: video,
            banner: banner
        )
    }
}

extension OpenRTB.Regulations {
    @Injected(\.environment) private static var environment
    @Injected(\.consentSettings) private static var consentSettings

    static func make() -> OpenRTB.Regulations {
        let ext = Extension(
            gdpr: consentSettings.isSubjectToGDPR?.intValue ?? 0,
            us_privacy: consentSettings.ccpaPrivacyString
        )
        let coppa = consentSettings.isSubjectToCOPPA == true ? 1 : 0

        return OpenRTB.Regulations(
            coppa: coppa,
            ext: ext
        )
    }
}

extension OpenRTB.User {
    @Injected(\.environment) private static var environment
    @Injected(\.consentSettings) private static var consentSettings

    static func make(request: HeliumAdLoadRequest) -> Self {

        let impdepth: Int
        switch request.adFormat {
        case .banner:
            impdepth = environment.impressionCounter.bannerImpressionCount
        case .interstitial:
            impdepth = environment.impressionCounter.interstitialImpressionCount
        case .rewarded, .rewardedInterstitial:
            impdepth = environment.impressionCounter.rewardedImpressionCount
        }
        
        let consent: String?
        switch consentSettings.gdprConsent {
        case .granted: consent = "1"
        case .denied: consent = "0"
        case .unknown: consent = nil
        }
        
        let ext = Extension(
            consent: consent,
            sessionduration: UInt(environment.session.elapsedSessionDuration),
            impdepth: UInt(impdepth),
            keywords: request.keywords,
            publisher_user_id: environment.userIDProvider.publisherUserID
        )

        return OpenRTB.User(
            id: environment.userIDProvider.userID,
            consent: consentSettings.gdprTCString,
            ext: ext
        )
    }
}

extension OpenRTB.BidRequest.Extension {
    @Injected(\.environment) private static var environment
    @Injected(\.consentSettings) private static var consentSettings

    static func make(request: HeliumAdLoadRequest, bidderInformation: BidderInformation) -> Self {
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

private extension Bool {
    var intValue: Int { self ? 1 : 0 }
}
