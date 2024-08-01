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

    var environment: EnvironmentMock {
        mocks.environment
    }

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
        XCTAssertEqual(environment.sdk.sdkName, impression.displaymanager)
        XCTAssertEqual(environment.sdk.sdkVersion, impression.displaymanagerver)
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
            XCTAssertEqual(environment.app.chartboostAppID, app.id)
            XCTAssertEqual(environment.app.bundleID, app.bundle)
            XCTAssertEqual(environment.app.appVersion, app.ver)
            XCTAssertNil(app.ext)
        }

        // device
        XCTAssertNotNil(body.device)
        if let device = body.device {
            XCTAssertEqual(environment.userAgent.userAgent, device.ua)
            XCTAssertEqual(0, device.lmt)
            XCTAssertEqual(OpenRTB.Device.DeviceType.phone, device.devicetype)
            XCTAssertEqual(environment.device.deviceMake, device.make)
            XCTAssertEqual(environment.device.deviceModel, device.model)
            XCTAssertEqual(environment.device.osName, device.os)
            XCTAssertEqual(environment.device.osVersion, device.osv)
            XCTAssertEqual(Int(environment.screen.screenHeight), device.h)
            XCTAssertEqual(Int(environment.screen.screenWidth), device.w)
            XCTAssertEqual(environment.screen.pixelRatio, device.pxratio)
            XCTAssertEqual(environment.userSettings.languageCode, device.language)
            XCTAssertEqual(environment.telephonyNetwork.carrierName, device.carrier)
            XCTAssertNil(device.mccmnc)
            XCTAssertEqual(OpenRTB.Device.ConnectionType.unknown, device.connectiontype)
            XCTAssertEqual(environment.appTracking.idfa, device.ifa)
            XCTAssertEqual(utcoffset, device.geo?.utcoffset)
            XCTAssertNotNil(device.ext)
            if let ext = device.ext {
                XCTAssertEqual(environment.appTracking.idfv, ext.ifv)
                XCTAssertEqual(environment.appTracking.appTransparencyAuthStatus, ext.atts)
                XCTAssertEqual(environment.userSettings.inputLanguages, ext.inputLanguage)
                XCTAssertEqual(environment.telephonyNetwork.networkTypes, ext.networktype)
                XCTAssertEqual(environment.audio.audioOutputTypes, ext.audiooutputtype)
                XCTAssertEqual(environment.audio.audioInputTypes, ext.audioinputtype)
                XCTAssertEqual(environment.audio.audioVolume, ext.audiovolume)
                XCTAssertEqual(environment.screen.screenBrightness, ext.screenbright)
                XCTAssertEqual(environment.device.batteryLevel, ext.batterylevel)
                XCTAssertEqual(environment.device.isBatteryCharging ? 1 : 0, ext.charging)
                XCTAssertEqual(environment.screen.isDarkModeEnabled ? 1 : 0, ext.darkmode)
                XCTAssertEqual(environment.device.totalDiskSpace, ext.totaldisk)
                XCTAssertEqual(environment.device.freeDiskSpace, ext.diskspace)
                XCTAssertEqual(environment.userSettings.textSize, ext.textsize)
                XCTAssertEqual(environment.userSettings.isBoldTextEnabled ? 1 : 0, ext.boldtext)
            }
        }

        // user
        XCTAssertNotNil(body.user)
        if let user = body.user {
            XCTAssertEqual(environment.userIDProvider.userID, user.id)
            XCTAssertNil(user.consent)
            XCTAssertNotNil(user.ext)
            if let ext = user.ext {
                XCTAssertNil(ext.consent)
                XCTAssertEqual(UInt(environment.session.elapsedSessionDuration), ext.sessionduration)
                XCTAssertEqual(UInt(environment.impressionCounter.interstitialImpressionCount), ext.impdepth)
                XCTAssertEqual(0, ext.keywords?.count ?? 0)
                XCTAssertEqual(environment.userIDProvider.publisherUserID, ext.publisher_user_id)
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
                XCTAssertNotNil(environment.skAdNetwork.skAdNetworkVersion, skadn.version)
                XCTAssertEqual(environment.skAdNetwork.skAdNetworkIDs, skadn.skadnetids)
            }
        }

        // test
        XCTAssertEqual(environment.testMode.isTestModeEnabled ? 1 : 0, body.test)

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
                mocks.environment.randomizeAll()
                mocks.consentSettings.consents = [
                    "key1": "value1",
                    ConsentKeys.tcf: "asdfb",
                    ConsentKeys.usp: "12345",
                    ConsentKeys.gpp: "gpp12345",
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
                XCTAssertEqual(environment.sdk.sdkName, impression.displaymanager)
                XCTAssertEqual(environment.sdk.sdkVersion, impression.displaymanagerver)
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
                    XCTAssertEqual(environment.app.chartboostAppID, app.id)
                    XCTAssertEqual(environment.app.bundleID, app.bundle)
                    XCTAssertEqual(environment.app.appVersion, app.ver)
                    if let gameEngineName = environment.app.gameEngineName {
                        XCTAssertNotNil(app.ext)
                        if let ext = app.ext {
                            XCTAssertEqual(gameEngineName, ext.game_engine_name)
                        }
                    }
                    if let gameEngineVersion = environment.app.gameEngineVersion {
                        XCTAssertNotNil(app.ext)
                        if let ext = app.ext {
                            XCTAssertEqual(gameEngineVersion, ext.game_engine_version)
                        }

                    }
                    if environment.app.gameEngineName == nil, environment.app.gameEngineVersion == nil {
                        XCTAssertNil(app.ext)
                    }
                }

                // device
                XCTAssertNotNil(request.device)
                if let device = request.device {
                    XCTAssertEqual(environment.userAgent.userAgent, device.ua)
                    XCTAssertEqual(environment.appTracking.isLimitAdTrackingEnabled ? 1 : 0, device.lmt)
                    XCTAssertEqual(environment.device.deviceType.asOpenRTBDeviceType, device.devicetype)
                    XCTAssertEqual(environment.device.deviceMake, device.make)
                    XCTAssertEqual(environment.device.deviceModel, device.model)
                    XCTAssertEqual(environment.device.osName, device.os)
                    XCTAssertEqual(environment.device.osVersion, device.osv)
                    XCTAssertEqual(Int(environment.screen.screenHeight), device.h)
                    XCTAssertEqual(Int(environment.screen.screenWidth), device.w)
                    XCTAssertEqual(environment.screen.pixelRatio, device.pxratio)
                    XCTAssertEqual(environment.userSettings.languageCode, device.language)
                    XCTAssertEqual(environment.telephonyNetwork.carrierName, device.carrier)
                    if let mobileCountryCode = environment.telephonyNetwork.mobileCountryCode, let mobileNetworkCode = environment.telephonyNetwork.mobileNetworkCode {
                        XCTAssertEqual("\(mobileCountryCode)-\(mobileNetworkCode)", device.mccmnc)
                    } else {
                        XCTAssertNil(device.mccmnc)
                    }
                    XCTAssertEqual(OpenRTB.Device.ConnectionType(rawValue: environment.telephonyNetwork.connectionType.rawValue), device.connectiontype)
                    XCTAssertEqual(environment.appTracking.idfa, device.ifa)
                    XCTAssertEqual(utcoffset, device.geo?.utcoffset)
                    XCTAssertNotNil(device.ext)
                    if let ext = device.ext {
                        XCTAssertEqual(environment.appTracking.idfv, ext.ifv)
                        XCTAssertEqual(environment.appTracking.appTransparencyAuthStatus, ext.atts)
                        XCTAssertEqual(environment.userSettings.inputLanguages, ext.inputLanguage)
                        XCTAssertEqual(environment.telephonyNetwork.networkTypes, ext.networktype)
                        XCTAssertEqual(environment.audio.audioOutputTypes, ext.audiooutputtype)
                        XCTAssertEqual(environment.audio.audioInputTypes, ext.audioinputtype)
                        XCTAssertEqual(environment.audio.audioVolume, ext.audiovolume)
                        XCTAssertEqual(environment.screen.screenBrightness, ext.screenbright)
                        XCTAssertEqual(environment.device.batteryLevel, ext.batterylevel)
                        XCTAssertEqual(environment.device.isBatteryCharging ? 1 : 0, ext.charging)
                        XCTAssertEqual(environment.screen.isDarkModeEnabled ? 1 : 0, ext.darkmode)
                        XCTAssertEqual(environment.device.totalDiskSpace, ext.totaldisk)
                        XCTAssertEqual(environment.device.freeDiskSpace, ext.diskspace)
                        XCTAssertEqual(environment.userSettings.textSize, ext.textsize)
                        XCTAssertEqual(environment.userSettings.isBoldTextEnabled ? 1 : 0, ext.boldtext)
                    }
                }

                // user
                XCTAssertNotNil(request.user)
                if let user = request.user {
                    XCTAssertEqual(environment.userIDProvider.userID, user.id)
                    XCTAssertEqual(mocks.consentSettings.consents[ConsentKeys.tcf], user.consent)
                    XCTAssertNotNil(user.ext)
                    if let ext = user.ext {
                        XCTAssertEqual(mocks.consentSettings.expectedConsentValue, ext.consent)
                        XCTAssertEqual(UInt(environment.session.elapsedSessionDuration), ext.sessionduration)
                        switch adFormat {
                        case .banner, .adaptiveBanner:
                            XCTAssertEqual(UInt(environment.impressionCounter.bannerImpressionCount), ext.impdepth)
                        case .interstitial:
                            XCTAssertEqual(UInt(environment.impressionCounter.interstitialImpressionCount), ext.impdepth)
                        case .rewarded, .rewardedInterstitial:
                            XCTAssertEqual(UInt(environment.impressionCounter.rewardedImpressionCount), ext.impdepth)
                        }
                        XCTAssertEqual(keywords?.count ?? 0, ext.keywords?.count ?? 0)
                        if let keywords = keywords, keywords.count > 0 {
                            XCTAssertEqual(keywords.keys, ext.keywords?.keys)
                            for keyword in keywords {
                                XCTAssertEqual(keywords[keyword.key], ext.keywords?[keyword.key])
                            }
                        }
                        XCTAssertEqual(environment.userIDProvider.publisherUserID, ext.publisher_user_id)
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
                        XCTAssertNotNil(environment.skAdNetwork.skAdNetworkVersion, skadn.version)
                        XCTAssertEqual(environment.skAdNetwork.skAdNetworkIDs.count, skadn.skadnetids.count)
                    }
                }

                // test
                XCTAssertEqual(environment.testMode.isTestModeEnabled ? 1 : 0, request.test)
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
