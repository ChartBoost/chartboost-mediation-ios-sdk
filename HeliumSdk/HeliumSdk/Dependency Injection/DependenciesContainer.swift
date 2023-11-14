// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Holds references to foundational objects to be used as dependencies for the creation of other objects.
protocol DependenciesContainer {
    var adControllerConfiguration: AdControllerConfiguration { get }
    var adControllerFactory: AdControllerFactory { get }
    var adControllerRepository: AdControllerRepository { get }
    var adFactory: AdFactory { get }
    var adLoader: FullscreenAdLoader { get }
    var adLoaderConfiguration: FullscreenAdLoaderConfiguration { get }
    var adRepository: AdRepository { get }
    var adapterFactory: PartnerAdapterFactory { get }
    var appConfiguration: ApplicationConfiguration { get }
    var appConfigurationController: ApplicationConfigurationController { get }
    var appConfigurationService: AppConfigurationServiceProtocol { get }
    var appTrackingInfo: AppTrackingInfoProviding { get }
    var appTrackingInfoDependency: AppTrackingInfoProviderDependency { get }
    var application: Application { get }
    var auctionService: AdAuctionService {  get }
    var bannerControllerConfiguration: BannerControllerConfiguration { get }
    var bidFulfillOperationConfiguration: BidFulfillOperationConfiguration { get }
    var bidFulfillOperationFactory: BidFulfillOperationFactory { get }
    var bundleInfo: BundleInfoProviding { get }
    var cbUserDefaultsStorage: UserDefaultsStorage { get }
    var chartboostIDProvider: ChartboostIDProviding { get }
    var consentSettings: ConsentSettings { get }
    var credentialsValidator: SDKCredentialsValidator { get }
    var customTaskDispatcher: TaskDispatcher? { get }
    var environment: EnvironmentProviding { get }
    var fileStorage: FileStorage { get }
    var fullScreenAdShowCoordinator: FullScreenAdShowCoordinator { get }
    var fullScreenAdShowObserver: FullScreenAdShowObserver { get }
    var ilrdEventPublisher: ILRDEventPublisher { get }
    var impressionCounter: ImpressionCounter { get }
    var impressionTracker: ImpressionTracker { get }
    var infoPlist: InfoPlistProviding { get }
    var initResultsEventPublisher: InitResultsEventPublisher { get }
    var initializationStatusProvider: HeliumInitializationStatusProvider { get }
    var instanceIdentifierProvider: InstanceIdentifierProviding { get }
    var jsonSerializer: JSONSerializer { get }
    var loadRateLimiter: LoadRateLimiting { get }
    var metrics: MetricsEventLogging { get }
    var metricsConfiguration: MetricsEventLoggerConfiguration { get }
    var networkManager: NetworkManagerProtocol { get }
    var partnerController: PartnerController { get }
    var partnerControllerConfiguration: PartnerControllerConfiguration { get }
    var reachability: NetworkStatusProviding { get }
    var sdkInitializer: SDKInitializer { get }
    var sdkInitializerConfiguration: SDKInitializerConfiguration { get }
    var taskDispatcher: AsynchronousTaskDispatcher { get }
    var userDefaultsStorage: UserDefaultsStorage { get }
    var visibilityTrackerConfiguration: VisibilityTrackerConfiguration { get }
    var consoleLoggerConfiguration: ConsoleLoggerConfiguration { get }
    var privacyConfiguration: PrivacyConfiguration { get }
}

/// Dependencies container for Helium SDK objects.
/// Note that as a rule of thumb properties should be `let` and not `lazy var`, because lazy properties are not thread-safe (see https://docs.swift.org/swift-book/documentation/the-swift-programming-language/properties/#Lazy-Stored-Properties).
final class HeliumDependenciesContainer: DependenciesContainer {

    private let configuration = UpdatableApplicationConfiguration()

    let adControllerFactory: AdControllerFactory = ContainerAdControllerFactory()
    let adControllerRepository: AdControllerRepository = SingleControllerPerPlacementAdControllerRepository()
    let adFactory: AdFactory = ContainerAdFactory()
    let adLoader: FullscreenAdLoader = AdLoader()
    let adRepository: AdRepository = AuctionAdRepository()
    let adapterFactory: PartnerAdapterFactory = ContainerPartnerAdapterFactory()
    lazy var appConfigurationController: ApplicationConfigurationController = PersistingApplicationConfigurationController()    // lazy because it does some logic on init that requires access to other dependencies. Safe to make it lazy since it's used by only one component: the sdkInitializer.
    let appConfigurationService: AppConfigurationServiceProtocol = AppConfigurationService()
    let appTrackingInfo: AppTrackingInfoProviding = AppTrackingInfoProvider()
    let appTrackingInfoDependency: AppTrackingInfoProvider.Dependency = AppTrackingInfoProvider.SystemDependency()
    let auctionService: AdAuctionService = NetworkAdAuctionService()
    let bidFulfillOperationFactory: BidFulfillOperationFactory = ContainerBidFulfillOperationFactory()
    let bundleInfo: BundleInfoProviding = BundleInfoProvider()
    let cbUserDefaultsStorage: UserDefaultsStorage = HeliumUserDefaultsStorage(keyPrefix: "com.chartboost.helium.")
    let chartboostIDProvider: ChartboostIDProviding = ChartboostIDProvider()
    let consentSettingsManager = ConsentSettingsManager()
    let credentialsValidator: SDKCredentialsValidator = LengthSDKCredentialsValidator()
    let currentSessionImpressionTracker = CurrentSessionImpressionTracker()
    let environment: EnvironmentProviding = Environment()
    let fileStorage: FileStorage = FileSystemStorage()
    let heliumSDKInitializer = HeliumSDKInitializer()
    let ilrdEventPublisher: ILRDEventPublisher = NotificationCenterILRDEventPublisher()
    let infoPlist: InfoPlistProviding = InfoPlist()
    let initResultsEventPublisher: InitResultsEventPublisher = NotificationCenterInitResultsEventPublisher()
    let instanceIdentifierProvider: InstanceIdentifierProviding = InstanceIdentifierProvider()
    let jsonSerializer: JSONSerializer = SafeJSONSerializer()
    let loadRateLimiter: LoadRateLimiting = LoadRateLimiter()
    let metrics: MetricsEventLogging = MetricsEventLogger()
    let middleManFullScreenAdShowCoordinator = MiddleManFullScreenAdShowCoordinator()
    let networkManager: NetworkManagerProtocol = NetworkManager()
    lazy var partnerController: PartnerController = PartnerAdapterController()  // lazy because it accesses consentSettings on init. In theory this could be a thread-safety issue, in practice it should always be accessed first either by sdkInitializer or by Helium.
    lazy var reachability: NetworkStatusProviding = {
        let reachability = ReachabilityMonitor.make()
        reachability.startNotifier()
        return reachability
    }()     // lazy to avoid starting the notifier right on app launch. Safe to make it lazy since it's used by only one component: the environment.
    let taskDispatcher: AsynchronousTaskDispatcher = GCDTaskDispatcher.serialBackgroundQueue(name: "shared")
    let userDefaultsStorage: UserDefaultsStorage = HeliumUserDefaultsStorage(keyPrefix: "com.helium.")

    var adControllerConfiguration: AdControllerConfiguration { configuration }
    var adLoaderConfiguration: FullscreenAdLoaderConfiguration { configuration }
    var appConfiguration: ApplicationConfiguration { configuration }
    var application: Application { UIApplication.shared }
    var bannerControllerConfiguration: BannerControllerConfiguration { configuration }
    var bidFulfillOperationConfiguration: BidFulfillOperationConfiguration { configuration }
    var consentSettings: ConsentSettings { consentSettingsManager }
    var customTaskDispatcher: TaskDispatcher? { nil }   // Only for tests. Every component must provide their own task dispatcher with sync capabilities to reduce the risk of deadlocks
    var fullScreenAdShowCoordinator: FullScreenAdShowCoordinator { middleManFullScreenAdShowCoordinator }
    var fullScreenAdShowObserver: FullScreenAdShowObserver { middleManFullScreenAdShowCoordinator }
    var impressionCounter: ImpressionCounter { currentSessionImpressionTracker }
    var impressionTracker: ImpressionTracker { currentSessionImpressionTracker }
    var initializationStatusProvider: HeliumInitializationStatusProvider { heliumSDKInitializer }
    var metricsConfiguration: MetricsEventLoggerConfiguration { configuration }
    var partnerControllerConfiguration: PartnerControllerConfiguration { configuration }
    var sdkInitializer: SDKInitializer { heliumSDKInitializer }
    var sdkInitializerConfiguration: SDKInitializerConfiguration { configuration }
    var visibilityTrackerConfiguration: VisibilityTrackerConfiguration { configuration }
    var consoleLoggerConfiguration: ConsoleLoggerConfiguration { configuration }
    var privacyConfiguration: PrivacyConfiguration { configuration }
}
