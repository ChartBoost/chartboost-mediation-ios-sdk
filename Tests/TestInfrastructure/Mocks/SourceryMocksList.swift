// Copyright 2024-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK

// List of protocols which we want to autogenerate mocks for using Sourcery.
//
// See the repository README.md for more info on our Sourcery integration.
//
// In order to change how mocks are generated you have to modify the `mockable.stencil` file.
// See the Sourcery docs on modifying templates: https://krzysztofzablocki.github.io/Sourcery/writing-templates.html
//
// Sourcery mockable syntax:
/*
// sourcery: mockable
// sourcery: <variable name> = "<default variable value>"
// sourcery: <function name>ReturnValue = "<default return value>"
extension <YourProtocol> {}
*/
// Note doube quotes may be omitted only if there are no whitespaces in the assigned value statement.
// In order to assign a String value use double quotes twice, or single quotes.
// E.g. ""ABCD"" and 'ABCD' will translate into "ABCD" when assigned to a default variable value.

// sourcery: mockable
extension AdAuctionService {}

// sourcery: mockable
// sourcery: showTimeout = 4.2
extension AdControllerConfiguration {}

// sourcery: mockable
extension AdControllerDelegate {}

// sourcery: mockable
// sourcery: makeAdControllerReturnValue = AdControllerMock()
extension AdControllerFactory {}

// sourcery: mockable
// sourcery: isReadyToShowAd = false
// sourcery: clearLoadedAdReturnValue = true
// sourcery: clearShowingAdReturnValue = nil
extension AdController {}

// sourcery: mockable
// sourcery: adControllerReturnValue = AdControllerMock()
extension AdControllerRepository {}

// sourcery: mockable
// sourcery: makeFullscreenAdReturnValue = FullscreenAd.test()
// sourcery: makeBannerControllerReturnValue = BannerControllerProtocolMock()
// sourcery: makeBannerSwapControllerReturnValue = BannerSwapControllerProtocolMock()
extension AdFactory {}

// sourcery: mockable
extension AdRepository {}

// sourcery: mockable
extension AppConfigurationServiceProtocol {}

// sourcery: mockable
// sourcery: chartboostAppID = String.random()
// sourcery: appVersion = "Bool.random() ? String.random() : nil"
// sourcery: bundleID = "Bool.random() ? String.random() : nil"
// sourcery: gameEngineName = "Bool.random() ? String.random() : nil"
// sourcery: gameEngineVersion = "Bool.random() ? String.random() : nil"
extension AppInfoProviding {}

// sourcery: mockable
// sourcery: trackingAuthorizationStatus = ".init(rawValue: UInt.random(in: 0...3)) ?? .notDetermined"
// sourcery: idfa = "Bool.random() ? String.random() : nil"
// sourcery: idfv = "Bool.random() ? String.random() : nil"
// sourcery: isLimitAdTrackingEnabled = "Bool.random()"
extension AppTrackingInfoProviding {}

// sourcery: mockable
extension ApplicationConfigurationController {}

// sourcery: mockable
extension ApplicationConfiguration {}

// sourcery: mockable
// sourcery: state = .inactive
extension Application {}

// sourcery: mockable
// sourcery: audioInputTypes = "String.randomArray()"
// sourcery: audioOutputTypes = "String.randomArray()"
// sourcery: audioVolume = "Double(UInt.random(in: 1...100))"
extension AudioInfoProviding {}

// sourcery: mockable
extension AuctionsHTTPRequestFactory {}

// sourcery: mockable
// sourcery: startMonitoringOperationReturnValue = BackgroundTimeMonitorOperatorMock()
extension BackgroundTimeMonitoring {}

// sourcery: mockable
// sourcery: backgroundTimeUntilNowReturnValue = "0.0"
extension BackgroundTimeMonitorOperator {}

// sourcery: mockable
// sourcery: autoRefreshRateReturnValue = 35.5
// sourcery: normalLoadRetryRateReturnValue = 23.5
// sourcery: penaltyLoadRetryRate = 14.5
// sourcery: penaltyLoadRetryCount = 3
// sourcery: bannerSizeEventDelay = 1
extension BannerControllerConfiguration {}

// sourcery: mockable
extension BannerControllerDelegate {}

// sourcery: mockable
// sourcery: loadAdReturnValue = ""some request id""
// sourcery: clearAdReturnValue = true
// sourcery: isPaused = false
// sourcery: request = ".init(placement: "placement", size: .standard)"
extension BannerControllerProtocol {}

// sourcery: mockable
extension BannerSwapControllerDelegate {}

// sourcery: mockable
extension BannerSwapControllerProtocol {}

// sourcery: mockable
extension BannerAdViewDelegate {}

// sourcery: mockable
// sourcery: fullscreenLoadTimeout = 23
// sourcery: bannerLoadTimeout = 12
extension BidFulfillOperationConfiguration {}

// sourcery: mockable
// sourcery: makeBidFulfillOperationReturnValue = BidFulfillOperationMock()
extension BidFulfillOperationFactory {}

// sourcery: mockable
extension BidFulfillOperation {}

// sourcery: mockable
// sourcery: mainBundle = "Bundle(for: BundleInfoProvidingMock.self) // In unit tests `Bundle.main` is the XCTest driver bundle, not the unit test bundle."
extension BundleInfoProviding {}

// sourcery: mockable
extension ChartboostIDProviding {}

// sourcery: mockable
extension ConsentSettingsDelegate {}

// sourcery: mockable
// sourcery: isUserUnderage = false
// sourcery: gppSID = ""1_2_3_4""
extension ConsentSettings {}

// sourcery: mockable
// sourcery: batteryLevel = "Double(UInt.random(in: 1...100))"
// sourcery: deviceMake = "String.random()"
// sourcery: deviceModel = "String.random()"
// sourcery: deviceType = "Bool.random() ? .iPad : .iPhone"
// sourcery: freeDiskSpace = "UInt.random(in: 1...100000000)"
// sourcery: isBatteryCharging = "Bool.random()"
// sourcery: osName = "String.random()"
// sourcery: osVersion = "String.random()"
// sourcery: totalDiskSpace = "UInt.random(in: 1...100000000)"
extension DeviceInfoProviding {}

// sourcery: mockable
extension MediationConsoleLogHandlerConfiguration {}

// sourcery: mockable
// sourcery: state = .active
// sourcery: remainingTime = 0
extension DispatchTask {}

// sourcery: mockable
// sourcery: urlForSDKConfigurationDirectoryReturnValue = "try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)"
// sourcery: urlForChartboostIDFileReturnValue = "try? FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Chartboost/chartboost_identifier")"
// sourcery: fileExistsReturnValue = true
// sourcery: readDataReturnValue = "some content".data(using:.utf8)!
// sourcery: directoryExistsReturnValue = true
extension FileStorage {}

// sourcery: mockable
extension FullscreenAdDelegate {}

// sourcery: mockable
// sourcery: adFormatReturnValue = AdFormat.rewarded
extension FullscreenAdLoaderConfiguration {}

// sourcery: mockable
extension FullscreenAdLoader {}

// sourcery: mockable
// sourcery: queueSizeReturnValue = 5
// sourcery: maxQueueSize = 5
// sourcery: defaultQueueSize = 5
// sourcery: queuedAdTtl = 2
// sourcery: queueLoadTimeout =  1
extension FullscreenAdQueueConfiguration {}

// sourcery: mockable
extension FullscreenAdQueueDelegate {}

// sourcery: mockable
extension FullScreenAdShowCoordinator {}

// sourcery: mockable
extension FullScreenAdShowObserver {}

// sourcery: mockable
extension ILRDEventPublisher {}

// sourcery: mockable
// sourcery: interstitialImpressionCount = 0
// sourcery: bannerImpressionCount = 0
// sourcery: rewardedImpressionCount = 0
extension ImpressionCounter {}

// sourcery: mockable
extension ImpressionTracker {}

// sourcery: mockable
// sourcery: appVersion = ""1.2.3""
// sourcery: skAdNetworkIDs = []
extension InfoPlistProviding {}

// sourcery: mockable
extension InitResultsEventPublisher {}

// sourcery: mockable
// sourcery: timeUntilNextLoadIsAllowedReturnValue = "0.0"
// sourcery: loadRateLimitReturnValue = "0.0"
extension LoadRateLimiting {}

// sourcery: mockable
// sourcery: isInitialized = true
extension MediationInitializationStatusProvider {}

// sourcery: mockable
// sourcery: filter = MetricsEvent.EventType.allCases
// sourcery: country = ""some country""
// sourcery: testIdentifier = ""some test identifier""
extension MetricsEventLoggerConfiguration {}

// sourcery: mockable
// sourcery: logLoadReturnValue = nil
// sourcery: logShowReturnValue = nil
extension MetricsEventLogging {}

// sourcery: mockable
extension NetworkManagerProtocol {}

// sourcery: mockable
// sourcery: status = .reachableViaWiFi
extension NetworkStatusProviding {}

// sourcery: mockable
// sourcery: adaptersReturnValue = "[(PartnerAdapterMock(), MutablePartnerAdapterStorage())]"
extension PartnerAdapterFactory {}

// sourcery: mockable
// sourcery: makeBannerAdReturnValue = "PartnerBannerAdMock(adapter: self)"
// sourcery: makeFullscreenAdReturnValue = "PartnerFullscreenAdMock(adapter: self)"
// sourcery: configuration = PartnerAdapterConfigurationMock1.self
extension PartnerAdapter {}
extension PartnerAdapterMock {
    convenience init(configuration: PartnerAdapterConfiguration.Type = PartnerAdapterConfigurationMock1.self) {
        self.init(storage: MutablePartnerAdapterStorage())
        self.configuration = configuration
    }
}

// sourcery: mockable
extension PartnerAdDelegate {}

// sourcery: mockable
// sourcery: adapter = PartnerAdapterMock()
// sourcery: request = .test()
extension PartnerBannerAd {}
extension PartnerBannerAdMock {
    convenience init(
        adapter: PartnerAdapter = PartnerAdapterMock(),
        request: PartnerAdLoadRequest = .test(),
        view: UIView? = nil,
        size: PartnerBannerSize? = nil
    ) {
        self.init()
        self.adapter = adapter
        self.request = request
        self.view = view
        self.size = size
    }
}

// sourcery: mockable
// sourcery: adapter = PartnerAdapterMock()
// sourcery: request = .test()
extension PartnerFullscreenAd {}
extension PartnerFullscreenAdMock {
    convenience init(
        adapter: PartnerAdapter = PartnerAdapterMock(),
        request: PartnerAdLoadRequest = .test()
    ) {
        self.init()
        self.adapter = adapter
        self.request = request
    }
}

// sourcery: mockable
// sourcery: prebidFetchTimeout = 4.2
// sourcery: initMetricsPostTimeout = 5
extension PartnerControllerConfiguration {}

// sourcery: mockable
// sourcery: routeLoadReturnValue = "{} as CancelAction"
extension PartnerController {}

// sourcery: mockable
extension PrivacyConfiguration {}

// sourcery: mockable
// sourcery: status = .reachableViaWiFi
// sourcery: startNotifierReturnValue = true
extension Reachability {}

// sourcery: mockable
// sourcery: isDarkModeEnabled = "Bool.random()"
// sourcery: pixelRatio = "Double(UInt.random(in: 1...1000))"
// sourcery: screenBrightness = "Double(UInt.random(in: 1...1000))"
// sourcery: screenHeight = "Double(UInt.random(in: 1...1000))"
// sourcery: screenWidth = "Double(UInt.random(in: 1...1000))"
extension ScreenInfoProviding {}

// sourcery: mockable
// sourcery: validateReturnValue = nil
extension SDKCredentialsValidator {}

// sourcery: mockable
// sourcery: sdkName = String.random()
// sourcery: sdkVersion = String.random()
extension SDKInfoProviding {}

// sourcery: mockable
extension SDKInitHTTPRequestFactory {}

// sourcery: mockable
// sourcery: disableSDK = false
// sourcery: initTimeout = 1
// sourcery: partnerCredentials = [:]
// sourcery: partnerAdapterClassNames = []
extension SDKInitializerConfiguration {}

// sourcery: mockable
extension SDKInitializer {}

// sourcery: mockable
// sourcery: discardOversizedAds = false
extension SDKSettingsProviding {}

// sourcery: mockable
// sourcery: elapsedSessionDuration = "TimeInterval(UInt.random(in: 1...1000))"
// sourcery: sessionID = "UUID().uuidString"
extension SessionInfoProviding {}

// sourcery: mockable
// sourcery: skAdNetworkIDs = String.randomArray()
// sourcery: skAdNetworkVersion = String.random()
extension SKAdNetworkInfoProviding {}

// sourcery: mockable
// sourcery: carrierName = "String.random()"
// sourcery: connectionType = "NetworkConnectionType(rawValue: Int.random(in: 0...NetworkConnectionType.cellular5G.rawValue))!"
// sourcery: mobileCountryCode = "Bool.random() ? String.random() : nil"
// sourcery: mobileNetworkCode = "Bool.random() ? String.random() : nil"
// sourcery: networkTypes = "String.randomArray()"
extension TelephonyNetworkInfoProviding {}

// sourcery: mockable
// sourcery: fullscreenAdQueueTTL = nil
// sourcery: fullscreenAdQueueMaxSize = nil
// sourcery: fullscreenAdQueueRequestedSize = nil
// sourcery: isTestModeEnabled = false
// sourcery: isRateLimitingEnabled = true
// sourcery: sdkAPIHostOverride = nil
extension TestModeInfoProviding {}
// Not randomizing property values for this mock. Previous comment pasted here:
// "Setting them to random values might break existing tests randomly.
// These properties act as constants in Release builds because only
// automation and Debug builds should change them, thus treating
// them as constants in unit tests is sufficient."

// sourcery: mockable
// sourcery: publisherUserID = "Bool.random() ? String.random() : nil"
// sourcery: userID = "Bool.random() ? String.random() : nil"
extension UserIDProviding {}

// sourcery: mockable
// sourcery: inputLanguages = "String.randomArray()"
// sourcery: isBoldTextEnabled = "Bool.random()"
// sourcery: languageCode = "Bool.random() ? String.random() : nil"
// sourcery: textSize = "Double(UInt.random(in: 1...100))"
extension UserSettingsProviding {}

// sourcery: mockable
// sourcery: userAgent = String.random()
extension UserAgentProviding {}

// sourcery: mockable
// sourcery: minimumVisibleSeconds = 2.405
// sourcery: minimumVisiblePoints = 5
// sourcery: pollInterval = 0.1
// sourcery: traversalLimit = 25
extension VisibilityTrackerConfiguration {}

// sourcery: mockable
// sourcery: isTracking = false
extension VisibilityTracker {}
