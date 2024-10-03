// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

/// A wrapper over all the possible mocks.
/// Any new mock used by a test should be added here and accessed through the `ChartboostMediationTestCase.mocks` property.
/// This will ensure that the mock value is used for dependency injection on Mediation SDK classes.
class MocksContainer {
    var bidFulfillOperationConfiguration = BidFulfillOperationConfigurationMock()
    var adControllerFactory = AdControllerFactoryMock()
    var adControllerConfiguration = AdControllerConfigurationMock()
    var adapterFactory = PartnerAdapterFactoryMock()
    var adLoaderConfiguration = FullscreenAdLoaderConfigurationMock()
    var appConfigurationController = ApplicationConfigurationControllerMock()
    var appConfiguration = ApplicationConfigurationMock()
    var application = ApplicationMock()
    var auctionRequestFactory = AuctionsHTTPRequestFactoryMock()
    var backgroundTimeMonitor = BackgroundTimeMonitoringMock()
    var bannerControllerConfiguration = BannerControllerConfigurationMock()
    var credentialsValidator = SDKCredentialsValidatorMock()
    var taskDispatcher = TaskDispatcherMock()
    var adControllerRepository = AdControllerRepositoryMock()
    var partnerController = PartnerControllerMock()
    var partnerControllerConfiguration = PartnerControllerConfigurationMock()
    var auctionService = AdAuctionServiceMock()
    var initializationStatusProvider = MediationInitializationStatusProviderMock()
    var metrics = MetricsEventLoggingMock()
    var metricsConfiguration = MetricsEventLoggerConfigurationMock()
    var fileStorage = FileStorageMock()
    var fullScreenAdShowCoordinator = FullScreenAdShowCoordinatorMock()
    var fullScreenAdShowObserver = FullScreenAdShowObserverMock()
    var ilrdEventPublisher = ILRDEventPublisherMock()
    var impressionTracker = ImpressionTrackerMock()
    var initResultsEventPublisher = InitResultsEventPublisherMock()
    var userDefaultsStorage = UserDefaultsStorageMock()
    var visibilityTrackerConfiguration = VisibilityTrackerConfigurationMock()
    var sdkInitRequestFactory = SDKInitHTTPRequestFactoryMock()
    var sdkInitializerConfiguration = SDKInitializerConfigurationMock()
    var adFactory = AdFactoryMock()
    var sdkInitializer = SDKInitializerMock()
    var environment = Environment(
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
    var impressionCounter = ImpressionCounterMock()
    var appConfigurationService = AppConfigurationServiceProtocolMock()
    var bidFulfillOperationFactory = BidFulfillOperationFactoryMock()
    var bannerAdViewDelegate = BannerAdViewDelegateMock()
    var bannerControllerDelegate = BannerControllerDelegateMock()
    var bannerSwapControllerDelegate = BannerSwapControllerDelegateMock()
    var adController = AdControllerMock()
    var visibilityTracker = VisibilityTrackerMock()
    var adControllerDelegate = AdControllerDelegateMock()
    var adRepository = AdRepositoryMock()
    var bannerController = BannerControllerProtocolMock()
    var bannerSwapController = BannerSwapControllerProtocolMock()
    var adLoader = FullscreenAdLoaderMock()
    var fullscreenAdDelegate = FullscreenAdDelegateMock()
    var consentSettings = ConsentSettingsMock()
    var consentSettingsDelegate = ConsentSettingsDelegateMock()
    var loadRateLimiter = LoadRateLimitingMock()
    var networkManager: NetworkManagerProtocol = NetworkManagerProtocolMock()
    var bundleInfo = BundleInfoProvidingMock()
    var appTrackingInfo = AppTrackingInfoProviderMock()
    var chartboostIDProvider = ChartboostIDProvidingMock()
    var infoPlist = InfoPlistProvidingMock()
    var reachability = ReachabilityMock()
    var consoleLogHandlerConfiguration = MediationConsoleLogHandlerConfigurationMock()
    var privacyConfigurationDependency = PrivacyConfigurationMock()
    var fullscreenAdQueueConfiguration = FullscreenAdQueueConfigurationMock()
}
