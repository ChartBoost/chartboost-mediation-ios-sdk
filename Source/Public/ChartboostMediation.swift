// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK
import Foundation

/// The main interface to the Chartboost Mediation SDK that provides some configuration options.
///
/// In order to initialize the SDK, see `ChartboostCore`.
/// To start loading ads, check the ad type classes like ``FullscreenAd``, ``BannerAdView``, and ``FullscreenAdQueue``.
@objc
@objcMembers
public final class ChartboostMediation: NSObject {
    /// The module ID of the `ChartboostCoreSDK` module that represents `ChartboostMediationSDK`.
    /// `ChartboostCoreSDK.initializeSDK()` initializes `ChartboostMediationSDK` by default. In order to skip
    /// `ChartboostMediationSDK` initialization, provide this module ID to `ChartboostCoreSDK.SDKConfiguration.skippedModuleIDs`
    /// when calling `ChartboostCoreSDK.initializeSDK()`.
    public static let coreModuleID = "chartboost_mediation"

    @Injected(\.adFactory) private static var adFactory
    @Injected(\.consentSettings) private static var consentSettings
    @Injected(\.environment) private static var environment
    @Injected(\.partnerController) private static var partnerController
    @Injected(\.sdkInitializer) private static var sdkInitializer
    @Injected(\.taskDispatcher) private static var taskDispatcher

    override private init() {}

    /// Set the SDK preinitialization configuration.
    /// This method should be called before any attempt to initialize the SDK, otherwise the provided configuration is discarded,
    /// and a ``ChartboostMediationError`` is returned.
    @discardableResult
    public static func setPreinitializationConfiguration(_ configuration: PreinitializationConfiguration?) -> ChartboostMediationError? {
        sdkInitializer.setPreinitializationConfiguration(configuration)
    }

    /// Set the logging level.
    ///
    /// This property can be called at any time, however it ideally should be called before initializing the SDK.
    /// Defaults to `.info`.
    public static var logLevel: LogLevel {
        get {
            return ConsoleLogHandler.mediation.clientSideLogLevel
        }
        set {
            ConsoleLogHandler.mediation.clientSideLogLevel = newValue
        }
    }

    /// The Chartboost Mediation SDK version.
    /// The value is a semantic versioning compliant string.
    public static var sdkVersion: String {
        environment.sdk.sdkVersion
    }

    /// An array of all initialized adapters, or an empty array if the SDK is not initialized.
    public static var initializedAdapterInfo: [PartnerAdapterInfo] {
        partnerController.initializedAdapterInfo.values.map { PartnerAdapterInfo(partnerAdapterInfo: $0) }
    }

    /// Boolean value indicating that ads returned from adapters that are larger than the requested size should be discarded.
    ///
    /// An ad is defined as too large if either the width or the height of the resulting ad is larger than the requested ad size
    /// (unless the height of the requested ad size is 0, as is the case when using
    /// ``BannerSize/adaptive(width:)``). In this case,
    /// a ``ChartboostMediationError/Code/loadFailureAdTooLarge`` error will be returned.
    /// This currently only applies to banners. Defaults to `false`.
    public static var discardOversizedAds: Bool {
        get { environment.sdkSettings.discardOversizedAds }
        set { environment.sdkSettings.discardOversizedAds = newValue }
    }

    /// A Boolean flag for setting test mode in this SDK.
    ///
    /// - Warning: Do not enable test mode in production builds.
    public static var isTestModeEnabled: Bool {
        get { environment.testMode.isTestModeEnabled }
        set { environment.testMode.isTestModeEnabled = newValue }
    }
}
