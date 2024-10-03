// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
import ChartboostCoreSDK
@testable import ChartboostMediationSDK

class AuctionsHTTPRequestFactoryTests: ChartboostMediationTestCase {

    lazy var factory = MediationAuctionsHTTPRequestFactory()
    let utcoffset = NSTimeZone.local.secondsFromGMT(for: Date()) / 60

    func testInterstitialBidRequestUsingDefaultMockData() throws {
        let adLoadRequest = InternalAdLoadRequest.test(
            adSize: BannerSize(size: CGSize(width: 50, height: 50), type: .fixed),
            adFormat: .interstitial,
            keywords: [:]
        )
        let loadRateLimit: TimeInterval = 4
        let request = try makeRequest(loadRequest: adLoadRequest, bidderInformation: [:], loadRateLimit: loadRateLimit)
        let body = request.body

        // imp
        XCTAssertEqual(1, body.imp.count)
        let impression = body.imp[0]
        XCTAssertEqual(mocks.environment.sdk.sdkName, impression.displaymanager)
        XCTAssertEqual(mocks.environment.sdk.sdkVersion, impression.displaymanagerver)
        XCTAssertEqual(1, impression.instl)
        XCTAssertEqual(adLoadRequest.mediationPlacement, impression.tagid)
        XCTAssertEqual(1, impression.secure)
        XCTAssertNotNil(impression.video)
        if let video = impression.video {
            XCTAssertEqual("video/mp4", video.mimes[0])
            XCTAssertEqual(Int(adLoadRequest.adSize?.size.width ?? 0), video.w)
            XCTAssertEqual(Int(adLoadRequest.adSize?.size.height ?? 0), video.h)
            XCTAssertEqual(OpenRTB.Impression.Video.VideoPlacementType.interstitialSliderOrFloating, video.placement)
            XCTAssertEqual(OpenRTB.AdPosition.fullScreen, video.pos)
            XCTAssertNotNil(video.companiontype)
            if let companionTypes = video.companiontype {
                XCTAssertEqual(2, companionTypes.count)
                if companionTypes.count == 2 {
                    XCTAssertTrue(companionTypes.contains(.staticResource))
                    XCTAssertTrue(companionTypes.contains(.htmlResource))
                }
            }
            XCTAssertNotNil(video.ext)
            if let ext = video.ext {
                XCTAssertEqual(adLoadRequest.adFormat.rawValue, ext.placementtype)
            }
        }
        XCTAssertNotNil(impression.banner)
        if let banner = impression.banner {
            XCTAssertEqual(Int(adLoadRequest.adSize?.size.width ?? 0), banner.w)
            XCTAssertEqual(Int(adLoadRequest.adSize?.size.height ?? 0), banner.h)
            XCTAssertEqual(OpenRTB.AdPosition.fullScreen, banner.pos)
            XCTAssertEqual(1, banner.topframe)
            XCTAssertNotNil(banner.ext)
            if let ext = banner.ext {
                XCTAssertEqual(adLoadRequest.adFormat.rawValue, ext.placementtype)
            }
        }

        // app
        XCTAssertNotNil(body.app)
        if let app = body.app {
            XCTAssertEqual(mocks.environment.app.chartboostAppID, app.id)
            XCTAssertEqual(mocks.environment.app.bundleID, app.bundle)
            XCTAssertEqual(mocks.environment.app.appVersion, app.ver)
            if mocks.environment.app.gameEngineName != nil
                || mocks.environment.app.gameEngineVersion != nil
            {
                XCTAssertEqual(mocks.environment.app.gameEngineName, app.ext?.game_engine_name)
                XCTAssertEqual(mocks.environment.app.gameEngineVersion, app.ext?.game_engine_version)
            } else {
                XCTAssertNil(app.ext)
            }
        }

        // device
        XCTAssertNotNil(body.device)
        if let device = body.device {
            XCTAssertEqual(mocks.environment.userAgent.userAgent, device.ua)
            XCTAssertEqual(0, device.lmt)
            XCTAssertEqual(mocks.environment.device.deviceType.asOpenRTBDeviceType, device.devicetype)
            XCTAssertEqual(mocks.environment.device.deviceMake, device.make)
            XCTAssertEqual(mocks.environment.device.deviceModel, device.model)
            XCTAssertEqual(mocks.environment.device.osName, device.os)
            XCTAssertEqual(mocks.environment.device.osVersion, device.osv)
            XCTAssertEqual(Int(mocks.environment.screen.screenHeight), device.h)
            XCTAssertEqual(Int(mocks.environment.screen.screenWidth), device.w)
            XCTAssertEqual(mocks.environment.screen.pixelRatio, device.pxratio)
            XCTAssertEqual(mocks.environment.userSettings.languageCode, device.language)
            XCTAssertEqual(mocks.environment.telephonyNetwork.carrierName, device.carrier)
            if let mobileCountryCode = mocks.environment.telephonyNetwork.mobileCountryCode, let mobileNetworkCode = mocks.environment.telephonyNetwork.mobileNetworkCode {
                XCTAssertEqual("\(mobileCountryCode)-\(mobileNetworkCode)", device.mccmnc)
            } else {
                XCTAssertNil(device.mccmnc)
            }
            XCTAssertEqual(OpenRTB.Device.ConnectionType(rawValue: mocks.environment.telephonyNetwork.connectionType.rawValue) ?? .unknown, device.connectiontype)
            XCTAssertEqual(mocks.environment.appTracking.idfa, device.ifa)
            XCTAssertEqual(utcoffset, device.geo?.utcoffset)
            XCTAssertNotNil(device.ext)
            if let ext = device.ext {
                XCTAssertEqual(mocks.environment.appTracking.idfv, ext.ifv)
                XCTAssertEqual(mocks.environment.appTracking.appTransparencyAuthStatus, ext.atts)
                XCTAssertEqual(mocks.environment.userSettings.inputLanguages, ext.inputLanguage)
                XCTAssertEqual(mocks.environment.telephonyNetwork.networkTypes, ext.networktype)
                XCTAssertEqual(mocks.environment.audio.audioOutputTypes, ext.audiooutputtype)
                XCTAssertEqual(mocks.environment.audio.audioInputTypes, ext.audioinputtype)
                XCTAssertEqual(mocks.environment.audio.audioVolume, ext.audiovolume)
                XCTAssertEqual(mocks.environment.screen.screenBrightness, ext.screenbright)
                XCTAssertEqual(mocks.environment.device.batteryLevel, ext.batterylevel)
                XCTAssertEqual(mocks.environment.device.isBatteryCharging ? 1 : 0, ext.charging)
                XCTAssertEqual(mocks.environment.screen.isDarkModeEnabled ? 1 : 0, ext.darkmode)
                XCTAssertEqual(mocks.environment.device.totalDiskSpace, ext.totaldisk)
                XCTAssertEqual(mocks.environment.device.freeDiskSpace, ext.diskspace)
                XCTAssertEqual(mocks.environment.userSettings.textSize, ext.textsize)
                XCTAssertEqual(mocks.environment.userSettings.isBoldTextEnabled ? 1 : 0, ext.boldtext)
            }
        }

        // user
        XCTAssertNotNil(body.user)
        if let user = body.user {
            XCTAssertEqual(mocks.environment.userIDProvider.userID, user.id)
            XCTAssertNil(user.consent)
            XCTAssertNotNil(user.ext)
            if let ext = user.ext {
                XCTAssertNil(ext.consent)
                XCTAssertEqual(UInt(mocks.environment.session.elapsedSessionDuration), ext.sessionduration)
                XCTAssertEqual(UInt(mocks.environment.impressionCounter.interstitialImpressionCount), ext.impdepth)
                XCTAssertEqual(0, ext.keywords?.count ?? 0)
                XCTAssertEqual(mocks.environment.userIDProvider.publisherUserID, ext.publisher_user_id)
            }
        }

        // regs
        XCTAssertNotNil(body.regs)
        if let regs = body.regs {
            XCTAssertEqual(mocks.consentSettings.isUserUnderage ? 1 : 0, regs.coppa)
            XCTAssertNotNil(regs.ext)
            if let ext = regs.ext {
                XCTAssertEqual((mocks.consentSettings.gdprApplies ?? false) ? 1 : 0, ext.gdpr)
                XCTAssertEqual(mocks.consentSettings.consents[ConsentKeys.usp], ext.us_privacy)
            }
        }

        // ext
        XCTAssertNotNil(body.ext)
        if let ext = body.ext {
            XCTAssertEqual(0, ext.bidders?.count ?? 0)
            XCTAssertEqual(adLoadRequest.loadID, ext.helium_sdk_request_id)
            XCTAssertNotNil(ext.skadn)
            if let skadn = ext.skadn {
                XCTAssertNotNil(mocks.environment.skAdNetwork.skAdNetworkVersion, skadn.version)
                XCTAssertEqual(mocks.environment.skAdNetwork.skAdNetworkIDs, skadn.skadnetids)
            }
        }

        // test
        XCTAssertEqual(mocks.environment.testMode.isTestModeEnabled ? 1 : 0, body.test)

        // Check headers
        XCTAssertJSONEqual(
            request.customHeaders,
            ["x-mediation-ad-type": adLoadRequest.adFormat.rawValue,
             "x-mediation-load-id": adLoadRequest.loadID,
             "x-mediation-ratelimit-reset": "\(Int(loadRateLimit))"]
        )
    }

    func testAllAdFormatsWithRandomizedData() throws {
        let allAdFormats = AdFormat.allCases
        for adFormat in allAdFormats {
            let loopCount = Int.random(in: 5...10)
            for _ in 0..<loopCount {
                // randomization of input data
                randomizeEnvironmentData()
                mocks.consentSettings.consents = [
                    "key1": "value1",
                    ConsentKeys.tcf: "asdfb",
                    ConsentKeys.usp: "12345",
                    ConsentKeys.gpp: "gpp1245",
                    ConsentKeys.ccpaOptIn: ConsentValues.granted
                ]
                mocks.consentSettings.isUserUnderage = true
                let keywords = randomKeywords
                let bidderInformation = randomBidderInformation

                let adLoadRequest = InternalAdLoadRequest.test(adFormat: adFormat, keywords: keywords)
                let request = try makeRequest(loadRequest: adLoadRequest, bidderInformation: bidderInformation).body

                // imp
                XCTAssertEqual(1, request.imp.count)
                let impression = request.imp[0]
                XCTAssertEqual(mocks.environment.sdk.sdkName, impression.displaymanager)
                XCTAssertEqual(mocks.environment.sdk.sdkVersion, impression.displaymanagerver)
                switch adFormat {
                case .banner, .adaptiveBanner:
                    XCTAssertEqual(0, impression.instl)
                default:
                    XCTAssertEqual(1, impression.instl)
                }
                XCTAssertEqual(adLoadRequest.mediationPlacement, impression.tagid)
                XCTAssertEqual(1, impression.secure)
                XCTAssertNotNil(impression.video)
                if let video = impression.video {
                    XCTAssertEqual("video/mp4", video.mimes[0])
                    XCTAssertEqual(Int(mocks.environment.screen.screenWidth), video.w)
                    XCTAssertEqual(Int(mocks.environment.screen.screenHeight), video.h)
                    switch adFormat {
                    case .banner, .adaptiveBanner:
                        XCTAssertEqual(OpenRTB.Impression.Video.VideoPlacementType.inBanner, video.placement)
                        XCTAssertEqual(OpenRTB.AdPosition.footer, video.pos)
                    default:
                        XCTAssertEqual(OpenRTB.Impression.Video.VideoPlacementType.interstitialSliderOrFloating, video.placement)
                        XCTAssertEqual(OpenRTB.AdPosition.fullScreen, video.pos)
                    }
                    XCTAssertNotNil(video.companiontype)
                    if let companionTypes = video.companiontype {
                        XCTAssertEqual(2, companionTypes.count)
                        if companionTypes.count == 2 {
                            XCTAssertTrue(companionTypes.contains(.staticResource))
                            XCTAssertTrue(companionTypes.contains(.htmlResource))
                        }
                    }
                    XCTAssertNotNil(video.ext)
                    if let ext = video.ext {
                        XCTAssertEqual(adLoadRequest.adFormat.rawValue, ext.placementtype)
                    }
                }
                XCTAssertNotNil(impression.banner)
                if let banner = impression.banner {
                    XCTAssertEqual(Int(mocks.environment.screen.screenWidth), banner.w)
                    XCTAssertEqual(Int(mocks.environment.screen.screenHeight), banner.h)
                    switch adFormat {
                    case .banner, .adaptiveBanner:
                        XCTAssertEqual(OpenRTB.AdPosition.footer, banner.pos)
                    default:
                        XCTAssertEqual(OpenRTB.AdPosition.fullScreen, banner.pos)
                    }
                    XCTAssertEqual(1, banner.topframe)
                    XCTAssertNotNil(banner.ext)
                    if let ext = banner.ext {
                        XCTAssertEqual(adLoadRequest.adFormat.rawValue, ext.placementtype)
                    }
                }

                // app
                XCTAssertNotNil(request.app)
                if let app = request.app {
                    XCTAssertEqual(mocks.environment.app.chartboostAppID, app.id)
                    XCTAssertEqual(mocks.environment.app.bundleID, app.bundle)
                    XCTAssertEqual(mocks.environment.app.appVersion, app.ver)
                    if let gameEngineName = mocks.environment.app.gameEngineName {
                        XCTAssertNotNil(app.ext)
                        if let ext = app.ext {
                            XCTAssertEqual(gameEngineName, ext.game_engine_name)
                        }
                    }
                    if let gameEngineVersion = mocks.environment.app.gameEngineVersion {
                        XCTAssertNotNil(app.ext)
                        if let ext = app.ext {
                            XCTAssertEqual(gameEngineVersion, ext.game_engine_version)
                        }

                    }
                    if mocks.environment.app.gameEngineName == nil, mocks.environment.app.gameEngineVersion == nil {
                        XCTAssertNil(app.ext)
                    }
                }

                // device
                XCTAssertNotNil(request.device)
                if let device = request.device {
                    XCTAssertEqual(mocks.environment.userAgent.userAgent, device.ua)
                    XCTAssertEqual(mocks.environment.appTracking.isLimitAdTrackingEnabled ? 1 : 0, device.lmt)
                    XCTAssertEqual(mocks.environment.device.deviceType.asOpenRTBDeviceType, device.devicetype)
                    XCTAssertEqual(mocks.environment.device.deviceMake, device.make)
                    XCTAssertEqual(mocks.environment.device.deviceModel, device.model)
                    XCTAssertEqual(mocks.environment.device.osName, device.os)
                    XCTAssertEqual(mocks.environment.device.osVersion, device.osv)
                    XCTAssertEqual(Int(mocks.environment.screen.screenHeight), device.h)
                    XCTAssertEqual(Int(mocks.environment.screen.screenWidth), device.w)
                    XCTAssertEqual(mocks.environment.screen.pixelRatio, device.pxratio)
                    XCTAssertEqual(mocks.environment.userSettings.languageCode, device.language)
                    XCTAssertEqual(mocks.environment.telephonyNetwork.carrierName, device.carrier)
                    if let mobileCountryCode = mocks.environment.telephonyNetwork.mobileCountryCode, let mobileNetworkCode = mocks.environment.telephonyNetwork.mobileNetworkCode {
                        XCTAssertEqual("\(mobileCountryCode)-\(mobileNetworkCode)", device.mccmnc)
                    } else {
                        XCTAssertNil(device.mccmnc)
                    }
                    XCTAssertEqual(OpenRTB.Device.ConnectionType(rawValue: mocks.environment.telephonyNetwork.connectionType.rawValue), device.connectiontype)
                    XCTAssertEqual(mocks.environment.appTracking.idfa, device.ifa)
                    XCTAssertEqual(utcoffset, device.geo?.utcoffset)
                    XCTAssertNotNil(device.ext)
                    if let ext = device.ext {
                        XCTAssertEqual(mocks.environment.appTracking.idfv, ext.ifv)
                        XCTAssertEqual(mocks.environment.appTracking.appTransparencyAuthStatus, ext.atts)
                        XCTAssertEqual(mocks.environment.userSettings.inputLanguages, ext.inputLanguage)
                        XCTAssertEqual(mocks.environment.telephonyNetwork.networkTypes, ext.networktype)
                        XCTAssertEqual(mocks.environment.audio.audioOutputTypes, ext.audiooutputtype)
                        XCTAssertEqual(mocks.environment.audio.audioInputTypes, ext.audioinputtype)
                        XCTAssertEqual(mocks.environment.audio.audioVolume, ext.audiovolume)
                        XCTAssertEqual(mocks.environment.screen.screenBrightness, ext.screenbright)
                        XCTAssertEqual(mocks.environment.device.batteryLevel, ext.batterylevel)
                        XCTAssertEqual(mocks.environment.device.isBatteryCharging ? 1 : 0, ext.charging)
                        XCTAssertEqual(mocks.environment.screen.isDarkModeEnabled ? 1 : 0, ext.darkmode)
                        XCTAssertEqual(mocks.environment.device.totalDiskSpace, ext.totaldisk)
                        XCTAssertEqual(mocks.environment.device.freeDiskSpace, ext.diskspace)
                        XCTAssertEqual(mocks.environment.userSettings.textSize, ext.textsize)
                        XCTAssertEqual(mocks.environment.userSettings.isBoldTextEnabled ? 1 : 0, ext.boldtext)
                    }
                }

                // user
                XCTAssertNotNil(request.user)
                if let user = request.user {
                    XCTAssertEqual(mocks.environment.userIDProvider.userID, user.id)
                    XCTAssertEqual(mocks.consentSettings.consents[ConsentKeys.tcf], user.consent)
                    XCTAssertNotNil(user.ext)
                    if let ext = user.ext {
                        XCTAssertEqual(mocks.consentSettings.expectedConsentValue, ext.consent)
                        XCTAssertEqual(UInt(mocks.environment.session.elapsedSessionDuration), ext.sessionduration)
                        switch adFormat {
                        case .banner, .adaptiveBanner:
                            XCTAssertEqual(UInt(mocks.environment.impressionCounter.bannerImpressionCount), ext.impdepth)
                        case .interstitial:
                            XCTAssertEqual(UInt(mocks.environment.impressionCounter.interstitialImpressionCount), ext.impdepth)
                        case .rewarded, .rewardedInterstitial:
                            XCTAssertEqual(UInt(mocks.environment.impressionCounter.rewardedImpressionCount), ext.impdepth)
                        }
                        XCTAssertEqual(keywords?.count ?? 0, ext.keywords?.count ?? 0)
                        if let keywords = keywords, keywords.count > 0 {
                            XCTAssertEqual(keywords.keys, ext.keywords?.keys)
                            for keyword in keywords {
                                XCTAssertEqual(keywords[keyword.key], ext.keywords?[keyword.key])
                            }
                        }
                        XCTAssertEqual(mocks.environment.userIDProvider.publisherUserID, ext.publisher_user_id)
                    }
                }

                // regs
                XCTAssertNotNil(request.regs)
                if let regs = request.regs {
                    XCTAssertEqual(mocks.consentSettings.isUserUnderage ? 1 : 0, regs.coppa)
                    XCTAssertNotNil(regs.ext)
                    if let ext = regs.ext {
                        XCTAssertEqual((mocks.consentSettings.gdprApplies ?? false) ? 1 : 0, ext.gdpr)
                        XCTAssertEqual(mocks.consentSettings.consents[ConsentKeys.usp], ext.us_privacy)
                    }
                }

                // ext
                XCTAssertNotNil(request.ext)
                if let ext = request.ext {
                    XCTAssertEqual(bidderInformation.count, ext.bidders?.count ?? 0)
                    XCTAssertEqual(bidderInformation.keys, ext.bidders?.keys)
                    for bidderKey in bidderInformation.keys {
                        XCTAssertEqual(bidderInformation[bidderKey]?.keys, ext.bidders?[bidderKey]?.keys)
                        if let innerKeys = bidderInformation[bidderKey]?.keys {
                            for innerKey in innerKeys {
                                XCTAssertEqual(bidderInformation[bidderKey]?[innerKey], ext.bidders?[bidderKey]?[innerKey])
                            }
                        }
                    }
                    XCTAssertEqual(adLoadRequest.loadID, ext.helium_sdk_request_id)
                    XCTAssertNotNil(ext.skadn)
                    if let skadn = ext.skadn {
                        XCTAssertNotNil(mocks.environment.skAdNetwork.skAdNetworkVersion, skadn.version)
                        XCTAssertEqual(mocks.environment.skAdNetwork.skAdNetworkIDs.count, skadn.skadnetids.count)
                    }
                }

                // test
                XCTAssertEqual(mocks.environment.testMode.isTestModeEnabled ? 1 : 0, request.test)
            }
        }
    }

    func testPrivacyBanList() throws {
        let adLoadRequest = InternalAdLoadRequest.test(adFormat: .interstitial, keywords: [:])
        var request: OpenRTB.BidRequest
        
        if #available(iOS 17.0, *) {
            mocks.privacyConfigurationDependency.privacyBanList = [.timeZone]
            request = try makeRequest(loadRequest: adLoadRequest, bidderInformation: [:]).body
            XCTAssertNil(request.device?.geo?.utcoffset)

            mocks.privacyConfigurationDependency.privacyBanList = []
            request = try makeRequest(loadRequest: adLoadRequest, bidderInformation: [:]).body
            XCTAssertNotNil(request.device?.geo?.utcoffset)
        } else {
            mocks.privacyConfigurationDependency.privacyBanList = [.timeZone]
            request = try makeRequest(loadRequest: adLoadRequest, bidderInformation: [:]).body
            XCTAssertNotNil(request.device?.geo?.utcoffset)

            mocks.privacyConfigurationDependency.privacyBanList = []
            request = try makeRequest(loadRequest: adLoadRequest, bidderInformation: [:]).body
            XCTAssertNotNil(request.device?.geo?.utcoffset)
        }
    }

    func testRegsExt() throws {
        mocks.consentSettings.gdprApplies = true
        mocks.consentSettings.consents[ConsentKeys.usp] = "usp12345"
        mocks.consentSettings.consents[ConsentKeys.gpp] = "gpp12345"
        mocks.consentSettings.gppSID = "1_2_3_4"
        let adLoadRequest = InternalAdLoadRequest.test(adFormat: .interstitial, keywords: [:])

        let request = try makeRequest(loadRequest: adLoadRequest, bidderInformation: [:])

        XCTAssertEqual(request.body.regs?.ext?.gdpr, 1)
        XCTAssertEqual(request.body.regs?.ext?.us_privacy, "usp12345")
        XCTAssertEqual(request.body.regs?.ext?.gpp_sid, "1_2_3_4")
        XCTAssertEqual(request.body.regs?.ext?.gpp, "gpp12345")
    }

    func makeRequest(loadRequest: InternalAdLoadRequest, bidderInformation: BidderInformation, loadRateLimit: TimeInterval = 0) throws -> AuctionsHTTPRequest {
        var request: AuctionsHTTPRequest?
        factory.makeRequest(request: loadRequest, loadRateLimit: loadRateLimit, bidderInformation: bidderInformation) { httpRequest in
            request = httpRequest
        }
        if let request {
            return request
        } else {
            XCTFail("Factory completion not called")
            throw NSError(domain: "", code: 0)
        }
    }

    var randomKeywords: [String: String]? {
        var keywords: [String: String]?
        if Bool.random() {
            var randomKeywords: [String: String] = [:]
            let keyCount = Int.random(in: 1...10)
            for _ in 0..<keyCount {
                randomKeywords[String.random()] = String.random()
            }
            keywords = randomKeywords
        }
        return keywords
    }

    var randomBidderInformation: BidderInformation {
        var bidderInformation: [PartnerID: [String: String]] = [:]
        if Bool.random() {
            let partnerCount = Int.random(in: 1...10)
            for _ in 0..<partnerCount {
                let keyCount = Int.random(in: 0...10)
                var bidder: [String: String] = [:]
                for _ in 0..<keyCount {
                    bidder[String.random()] = String.random()
                }
                bidderInformation[String.random()] = bidder
            }
        }
        return bidderInformation
    }

    func randomizeEnvironmentData() {
        mocks.environment = Environment(
            app: AppInfoProvidingMock(),
            audio: AudioInfoProvidingMock(),
            device: DeviceInfoProvidingMock(),
            screen: ScreenInfoProvidingMock(),
            sdk: SDKInfoProvidingMock(),
            sdkSettings: SDKSettingsProvidingMock(),
            session: SessionInfoProvidingMock(),
            skAdNetwork: SKAdNetworkInfoProvidingMock(),
            telephonyNetwork: TelephonyNetworkInfoProvidingMock(),
            testMode: TestModeInfoProvidingMock(),
            userIDProvider: UserIDProvidingMock(),
            userSettings: UserSettingsProvidingMock(),
            userAgent: UserAgentProvidingMock()
        )
    }
}

fileprivate extension ConsentSettings {
    var expectedConsentValue: String? {
        switch consents[ConsentKeys.gdprConsentGiven] {
        case ConsentValues.granted: return "1"
        case ConsentValues.denied: return "0"
        default: return nil
        }
    }
}

fileprivate extension DeviceType {
    var asOpenRTBDeviceType: OpenRTB.Device.DeviceType? {
        switch self {
        case .iPhone:
            return .phone
        case .iPad:
            return .tablet
        }
    }
}
