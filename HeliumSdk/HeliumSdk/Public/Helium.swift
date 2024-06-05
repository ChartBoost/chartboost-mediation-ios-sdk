// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// The main interface to the Chartboost Mediation SDK.
@objc
@objcMembers
public final class Helium: NSObject {
    /// Shared instance of the Chartboost Mediation SDK.
    /// - Returns: Shared instance of the Chartboost Mediation SDK.
    @objc(sharedHelium)
    public static func shared() -> Helium { _shared }
    private static let _shared = Helium()

    private weak var delegate: HeliumSdkDelegate?

    @Injected(\.adFactory) private var adFactory
    @Injected(\.adLoader) private var adLoader
    @Injected(\.consentSettings) private var consentSettings
    @Injected(\.environment) private var environment
    @Injected(\.partnerController) private var partnerController
    @Injected(\.sdkInitializer) private var sdkInitializer
    @Injected(\.taskDispatcher) private var taskDispatcher

    override private init() {}

    // MARK: - Initialization

    /// Initializes the Chartboost Mediation SDK.
    /// This method must be called before ads can be served.
    /// - Parameter appId: Application identifier from the Chartboost dashboard.
    /// - Parameter options: Optional initialization options.
    /// - Parameter delegate: Optional delegate used to listen for the SDK initialization callback.
    public func start(
        withAppId appId: String,
        options: HeliumInitializationOptions?,
        delegate: HeliumSdkDelegate?
    ) {
        // Set delegate to notify later
        self.delegate = delegate

        // Initialize the SDK through the initializer.
        // It will take care of edge cases like SDK already initialized or initializing.
        sdkInitializer.initialize(
            appIdentifier: appId,
            partnerIdentifiersToSkipInitialization: options?.skippedPartnerIdentifiers ?? []
        ) { [weak self] cmError in
            // Make no assumption on `sdkInitializer` and ensure the delegate is called on main thread
            self?.taskDispatcher.async(on: .main) {
                self?.delegate?.heliumDidStartWithError(cmError)
            }
        }
    }

    /// Deprecated.
    /// Initializes the Chartboost Mediation SDK.
    /// This method must be called before ads can be served.
    /// - Parameter appId: Application identifier from the Chartboost dashboard.
    /// - Parameter appSignature: Application signature from the Chartboost dashboard.
    /// - Parameter options: Optional initialization options.
    /// - Parameter delegate: Optional delegate used to listen for the SDK initialization callback.
    @available(*, deprecated, message: "Use start(withAppId:options:delegate:) instead.")
    public func start(
        withAppId appId: String,
        andAppSignature appSignature: String,
        options: HeliumInitializationOptions?,
        delegate: HeliumSdkDelegate?
    ) {
        start(withAppId: appId, options: options, delegate: delegate)
    }

    // MARK: - Logging

    /// Set the logging level.
    ///
    /// This property can be called at any time, however it ideally should be called before
    /// ``Helium/start(withAppId:andAppSignature:options:delegate:)``.
    /// Defaults to ``LogLevel/info``.
    public var logLevel: LogLevel {
        get {
            return ConsoleLogHandler.logLevel
        }
        set {
            ConsoleLogHandler.logLevel = newValue
        }
    }

    /// Attach a custom logger handler to the logging system.
    /// - Parameter handler: A custom class that conforms to the ``LogHandler`` protocol.
    public func attachLogHandler(_ handler: LogHandler) {
        Logger.attachHandler(handler)
    }

    /// Detatch a custom logger handler to the logging system.
    /// - Parameter handler: A custom class that conforms to the ``LogHandler`` protocol.
    public func detachLogHandler(_ handler: LogHandler) {
        Logger.detachHandler(handler)
    }

    // MARK: - Ad Providers

    /// Factory method to create a ``HeliumInterstitialAd`` which will be used to load and show interstitial ads.
    /// - Parameter delegate: Delegate to receive interstitial ad callbacks.
    /// - Parameter placementName: Interstitial ad placement from the Chartboost dashboard.
    /// - Returns: The interstitial ad provider if successful; otherwise `nil` will be returned.
    @available(*, deprecated, message: "Use loadFullscreenAd(with:completion:) for the most comprehensive fullscreen ad experience.")
    @objc(interstitialAdProviderWithDelegate:andPlacementName:)
    public func interstitialAdProvider(
        with delegate: CHBHeliumInterstitialAdDelegate?,
        andPlacementName placementName: String
    ) -> HeliumInterstitialAd? {
        adFactory.makeInterstitialAd(placement: placementName, delegate: delegate)
    }

    /// Factory method to create a ``HeliumRewardedAd`` which will be used to load and show rewarded ads.
    /// - Parameter delegate: Delegate to receive rewarded ad callbacks.
    /// - Parameter placementName: Rewarded ad placement from the Chartboost dashboard.
    /// - Returns: The rewarded ad provider if successful; otherwise `nil` will be returned.
    @available(*, deprecated, message: "Use loadFullscreenAd(with:completion:) for the most comprehensive fullscreen ad experience.")
    @objc(rewardedAdProviderWithDelegate:andPlacementName:)
    public func rewardedAdProvider(
        with delegate: CHBHeliumRewardedAdDelegate?,
        andPlacementName placementName: String
    ) -> HeliumRewardedAd? {
        adFactory.makeRewardedAd(placement: placementName, delegate: delegate)
    }

    /// Factory method to create a ``HeliumBannerView`` which will be used to load and show banner ads.
    /// - Parameter delegate: Delegate to receive banner ad callbacks.
    /// - Parameter placementName: Banner ad placement from the Chartboost dashboard.
    /// - Parameter bannerSize: Size of the banner to request.
    /// - Returns: The banner ad provider if successful; otherwise `nil` will be returned.
    @available(*, deprecated, message: "Use ChartboostMediationBannerView for the most comprehensive banner ad experience.")
    @objc(bannerProviderWithDelegate:andPlacementName:andSize:)
    public func bannerProvider(
        with delegate: HeliumBannerAdDelegate?,
        andPlacementName placementName: String,
        andSize bannerSize: CHBHBannerSize
    ) -> HeliumBannerView? {
        adFactory.makeBannerAd(placement: placementName, size: bannerSize, delegate: delegate)
    }

    /// Loads a Chartboost Mediation fullscreen ad using the information provided in the request.
    ///
    /// Chartboost Mediation may return the same ad from a previous successful load if it was never shown nor invalidated
    /// before it got discarded.
    /// - Parameter request: A request containing the information used to load the ad.
    /// - Parameter completion: A closure executed when the load operation is done.
    @objc(loadFullscreenAdWithRequest:completion:)
    public func loadFullscreenAd(
        with request: ChartboostMediationAdLoadRequest,
        completion: @escaping (ChartboostMediationFullscreenAdLoadResult) -> Void
    ) {
        adLoader.loadFullscreenAd(with: request, completion: completion)
    }

    // MARK: - COPPA and Consent

    /// Indicates that the user is subject to COPPA.
    ///
    /// For more information about COPPA, see [Chartboost Support](https://answers.chartboost.com/en-us/articles/115001488494).
    /// - Parameter isSubject: User is subject to COPPA.
    public func setSubjectToCoppa(_ isSubject: Bool) {
        consentSettings.isSubjectToCOPPA = isSubject
    }

    /// Indicates that the user is subject to GDPR.
    ///
    /// For more information about GDPR, see [Chartboost Support](https://answers.chartboost.com/en-us/articles/115001489613).
    /// - Parameter isSubject: User is subject to GDPR.
    public func setSubjectToGDPR(_ isSubject: Bool) {
        consentSettings.isSubjectToGDPR = isSubject
    }

    /// Indicates that the GDPR-applicable user has granted consent to the collection of Personally Identifiable Information.
    ///
    /// For more information about GDPR, see [Chartboost Support](https://answers.chartboost.com/en-us/articles/115001489613).
    /// - Parameter hasGivenConsent: GDPR-applicable user has granted consent.
    public func setUserHasGivenConsent(_ hasGivenConsent: Bool) {
        consentSettings.gdprConsent = hasGivenConsent ? .granted : .denied
    }

    /// Indicates that the CCPA-applicable user has granted consent to the collection of Personally Identifiable Information.
    ///
    /// For more information about CCPA, see  [Chartboost Support](https://answers.chartboost.com/en-us/articles/115001490031).
    /// - Parameter hasGivenConsent: CCPA-applicable user has granted consent.
    public func setCCPAConsent(_ hasGivenConsent: Bool) {
        consentSettings.ccpaConsent = hasGivenConsent
    }

    /// Allows to set user consent for a specific partner.
    ///
    /// Use this when you want to inform of a user consent that applies to specific partners instead of to all of them.
    /// When a consent value for a partner is not present in this dictionary then general signals provided by calls to
    /// ``setUserHasGivenConsent(_:)`` and ``setCCPAConsent(_:)`` are used as fallback.
    public var partnerConsents: [PartnerIdentifier: Bool] {
        get {
            consentSettings.partnerConsents
        }
        set {
            consentSettings.partnerConsents = newValue
        }
    }

    // MARK: - User Information

    /// Optional user identifier sent on every ad request.
    public var userIdentifier: String? {
        get {
            environment.userIDProvider.publisherUserID
        }
        set {
            environment.userIDProvider.publisherUserID = newValue
        }
    }

    // MARK: - Game Engine

    /// Specifies to the Chartboost Mediation SDK the game engine environment that it is running in.
    /// This method should be called before loading ads.
    /// - Parameter name: Game engine name.
    /// - Parameter version: Game engine version.
    public func setGameEngineName(_ name: String?, version: String?) {
        environment.app.gameEngineName = name
        environment.app.gameEngineVersion = version
    }

    // MARK: - SDK Information

    /// The Chartboost Mediation SDK version.
    /// The value is a semantic versioning compliant string.
    public static var sdkVersion: String {
        _shared.environment.sdk.sdkVersion
    }

    // MARK: - Adapters

    /// An array of all initialized adapters, or an empty array if the SDK is not initialized.
    public var initializedAdapterInfo: [HeliumAdapterInfo] {
        partnerController.initializedAdapterInfo.values.map { HeliumAdapterInfo(partnerAdapterInfo: $0) }
    }

    // MARK: - Other Settings

    /// Boolean value indicating that ads returned from adapters that are larger than the requested size should be discarded.
    ///
    /// An ad is defined as too large if either the width or the height of the resulting ad is larger than the requested ad size
    /// (unless the height of the requested ad size is 0, as is the case when using
    /// ``ChartboostMediationBannerSize/adaptive(width:)``). In this case,
    /// a ``ChartboostMediationError/Code/loadFailureAdTooLarge`` error will be returned.
    /// This currently only applies to banners. Defaults to `false`.
    public var discardOversizedAds: Bool {
        get { environment.sdkSettings.discardOversizedAds }
        set { environment.sdkSettings.discardOversizedAds = newValue }
    }

    /// A Boolean flag for setting test mode in this SDK.
    ///
    /// - Warning: Do not enable test mode in production builds.
    public static var isTestModeEnabled: Bool {
        get { _shared.environment.testMode.isTestModeEnabled }
        set { _shared.environment.testMode.isTestModeEnabled = newValue }
    }
}
