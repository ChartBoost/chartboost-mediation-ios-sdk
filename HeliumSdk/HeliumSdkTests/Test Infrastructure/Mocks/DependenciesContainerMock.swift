// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class DependenciesContainerMock: DependenciesContainer {
    
    let mocks = MocksContainer()
    
    var adControllerFactory: AdControllerFactory { mocks.adControllerFactory }
    var adControllerConfiguration: AdControllerConfiguration { mocks.adControllerConfiguration }
    var adapterFactory: PartnerAdapterFactory { mocks.adapterFactory }
    var adLoaderConfiguration: FullscreenAdLoaderConfiguration { mocks.adLoaderConfiguration }
    var appConfigurationController: ApplicationConfigurationController { mocks.appConfigurationController }
    var appConfiguration: ApplicationConfiguration { mocks.appConfiguration }
    var application: Application { mocks.application }
    var adRepository: AdRepository { mocks.adRepository }
    var bannerControllerConfiguration: BannerControllerConfiguration { mocks.bannerControllerConfiguration }
    var bidFulfillOperationConfiguration: BidFulfillOperationConfiguration { mocks.bidFulfillOperationConfiguration }
    var bidFulfillOperationFactory: BidFulfillOperationFactory { mocks.bidFulfillOperationFactory }
    var cbUserDefaultsStorage: UserDefaultsStorage { mocks.userDefaultsStorage }
    var credentialsValidator: SDKCredentialsValidator { mocks.credentialsValidator }
    var jsonSerializer: JSONSerializer { SafeJSONSerializer() }
    var taskDispatcher: AsynchronousTaskDispatcher { mocks.taskDispatcher }
    var customTaskDispatcher: TaskDispatcher? { mocks.taskDispatcher }
    var adControllerRepository: AdControllerRepository { mocks.adControllerRepository }
    var multipleAdControllerRepository: AdControllerRepository { mocks.adControllerRepository }
    var partnerController: PartnerController { mocks.partnerController }
    var partnerControllerConfiguration: PartnerControllerConfiguration { mocks.partnerControllerConfiguration }
    var auctionService: AdAuctionService { mocks.auctionService }
    var initializationStatusProvider: HeliumInitializationStatusProvider { mocks.initializationStatusProvider }
    var metrics: MetricsEventLogging { mocks.metrics }
    var metricsConfiguration: MetricsEventLoggerConfiguration { mocks.metricsConfiguration }
    var fileStorage: FileStorage { mocks.fileStorage }
    var fullScreenAdShowCoordinator: FullScreenAdShowCoordinator { mocks.fullScreenAdShowCoordinator }
    var fullScreenAdShowObserver: FullScreenAdShowObserver { mocks.fullScreenAdShowObserver }
    var ilrdEventPublisher: ILRDEventPublisher { mocks.ilrdEventPublisher }
    var impressionTracker: ImpressionTracker { mocks.impressionTracker }
    var initResultsEventPublisher: InitResultsEventPublisher { mocks.initResultsEventPublisher }
    var userDefaultsStorage: UserDefaultsStorage { mocks.userDefaultsStorage }
    var visibilityTrackerConfiguration: VisibilityTrackerConfiguration { mocks.visibilityTrackerConfiguration }
    var sdkInitializerConfiguration: SDKInitializerConfiguration { mocks.sdkInitializerConfiguration }
    var loadRateLimiter: LoadRateLimiting { mocks.loadRateLimiter }
    var instanceIdentifierProvider: InstanceIdentifierProviding { fatalError("Not implemented") }
    var reachability: NetworkStatusProviding { mocks.reachability }
    var adFactory: AdFactory { mocks.adFactory }
    var sdkInitializer: SDKInitializer { mocks.sdkInitializer }
    var impressionCounter: ImpressionCounter { mocks.impressionCounter }
    var appConfigurationService: AppConfigurationServiceProtocol { mocks.appConfigurationService }
    var environment: EnvironmentProviding { mocks.environment }
    var networkManager: NetworkManagerProtocol { mocks.networkManager }
    var adLoader: FullscreenAdLoader { mocks.adLoader }
    var consentSettings: ConsentSettings { mocks.consentSettings }
    var chartboostIDProvider: ChartboostIDProviding { mocks.chartboostIDProvider }
    var bundleInfo: BundleInfoProviding { mocks.bundleInfo }
    var infoPlist: InfoPlistProviding { mocks.infoPlist }
    var appTrackingInfo: AppTrackingInfoProviding { mocks.appTrackingInfo }
    var appTrackingInfoDependency: AppTrackingInfoProviderDependency { mocks.appTrackingInfoProviderDependency }
    var consoleLoggerConfiguration: ConsoleLoggerConfiguration { mocks.consoleLoggerConfigurationDependency }
    var privacyConfiguration: PrivacyConfiguration { mocks.privacyConfigurationDependency }
}
