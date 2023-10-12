// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

/// A wrapper over all the possible mocks.
/// Any new mock used by a test should be added here and accessed through the `HeliumTestCase.mocks` property.
/// This will ensure that the mock value is used for dependency injection on Helium SDK classes.
class MocksContainer {
    var bidFulfillOperationConfiguration = BidFulfillOperationConfigurationMock()
    var adControllerFactory = AdControllerFactoryMock()
    var adControllerConfiguration = AdControllerConfigurationMock()
    var adapterFactory = PartnerAdapterFactoryMock()
    var adLoaderConfiguration = FullscreenAdLoaderConfigurationMock()
    var appConfigurationController = ApplicationConfigurationControllerMock()
    var appConfiguration = ApplicationConfigurationMock()
    var application = ApplicationMock()
    var bannerControllerConfiguration = BannerControllerConfigurationMock()
    var credentialsValidator = SDKCredentialsValidatorMock()
    var taskDispatcher = TaskDispatcherMock()
    var adControllerRepository = AdControllerRepositoryMock()
    var partnerController = PartnerControllerMock()
    var partnerControllerConfiguration = PartnerControllerConfigurationMock()
    var auctionService = AdAuctionServiceMock()
    var initializationStatusProvider = HeliumInitializationStatusProviderMock()
    var metrics = MetricsEventLoggerMock()
    var metricsConfiguration = MetricsEventLoggerConfigurationMock()
    var fileStorage = FileStorageMock()
    var fullScreenAdShowCoordinator = FullScreenAdShowCoordinatorMock()
    var fullScreenAdShowObserver = FullScreenAdShowObserverMock()
    var ilrdEventPublisher = ILRDEventPublisherMock()
    var impressionTracker = ImpressionTrackerMock()
    var initResultsEventPublisher = InitResultsEventPublisherMock()
    var userDefaultsStorage = UserDefaultsStorageMock()
    var visibilityTrackerConfiguration = VisibilityTrackerConfigurationMock()
    var sdkInitializerConfiguration = SDKInitializerConfigurationMock()
    var adFactory = AdFactoryMock()
    var sdkInitializer = SDKInitializerMock()
    var environment = EnvironmentMock()
    var impressionCounter = ImpressionCounterMock()
    var appConfigurationService = AppConfigurationServiceMock()
    var bidFulfillOperationFactory = BidFulfillOperationFactoryMock()
    var interstitialDelegate = HeliumInterstitialAdDelegateMock()
    var rewardedDelegate = HeliumRewardedAdDelegateMock()
    var bannerDelegate = HeliumBannerAdDelegateMock()
    var chartboostMediationBannerViewDelegate = ChartboostMediationBannerViewDelegateMock()
    var bannerControllerDelegate = BannerControllerDelegateMock()
    var bannerSwapControllerDelegate = BannerSwapControllerDelegateMock()
    var adController = AdControllerMock()
    var visibilityTracker = VisibilityTrackerMock()
    var adControllerDelegate = AdControllerDelegateMock()
    var adRepository = AdRepositoryMock()
    var bannerController = BannerControllerMock()
    var bannerSwapController = BannerSwapControllerMock()
    var adLoader = FullscreenAdLoaderMock()
    var fullscreenAdDelegate = ChartboostMediationFullscreenAdDelegateMock()
    var consentSettings = ConsentSettingsMock()
    var consentSettingsDelegate = ConsentSettingsDelegateMock()
    var loadRateLimiter = LoadRateLimiterMock()
    var networkManager: NetworkManagerProtocol = NetworkManagerMock()
    var bundleInfo = BundleInfoProviderMock()
    var appTrackingInfo = AppTrackingInfoProviderMock()
    var appTrackingInfoProviderDependency = AppTrackingInfoProviderDependencyMock()
    var chartboostIDProvider = ChartboostIDProviderMock()
    var infoPlist = InfoPlistMock()
    var reachability = ReachabilityMock()
    var consoleLoggerConfigurationDependency = ConsoleLoggerConfigurationDependencyMock()
    var privacyConfigurationDependency = PrivacyConfigurationDependencyMock()
}
