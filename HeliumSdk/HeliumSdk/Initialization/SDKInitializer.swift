// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Provides the initialization status of the SDK.
protocol MediationInitializationStatusProvider {
    /// `true` if the Mediation SDK is initialized, `false` otherwise.
    var isInitialized: Bool { get }
}

/// Initializes the SDK by fetching the proper configuration, applying it, and initializing partner SDKs.
protocol SDKInitializer {
    /// Starts the initialization process.
    /// - parameter appIdentifier: User-provided Helium app identifier.
    /// - parameter partnerIdentifiersToSkipInitialization: Set of partner adapter identifiers to skip during partner adapter
    /// initialization.
    /// - parameter completion: Closure executed by the initializer when the initialization process finishes either successfully or with
    /// and error.
    func initialize(
        appIdentifier: String?,
        partnerIdentifiersToSkipInitialization: Set<PartnerIdentifier>,
        completion: @escaping (ChartboostMediationError?) -> Void
    )
}

/// Configuration settings for SDKInitializer.
protocol SDKInitializerConfiguration {
    /// The  timeout for all partner initializations. Defaults to 1.0.
    var initTimeout: TimeInterval { get }
    /// Partner-specific configurations to be used by partner SDKs on initialization. Keyed by partner identifier.
    var partnerCredentials: [PartnerIdentifier: [String: Any]] { get }
    /// List of registered adapter class names for our partners.
    var partnerAdapterClassNames: Set<String> { get }
}

/// Initializes the Mediation SDK by fetching the proper configuration, applying it, and initializing partner SDKs.
/// Provides access to the current initialization status.
final class MediationSDKInitializer: SDKInitializer, MediationInitializationStatusProvider {
    /// Initialization status
    private enum InitializationStatus {
        case uninitialized
        case initializing
        case initialized
    }

    @Injected(\.appConfigurationController) private var appConfigurationController
    @Injected(\.environment) private var environment
    @Injected(\.credentialsValidator) private var credentialsValidator
    @Injected(\.metrics) private var metrics
    @Injected(\.partnerController) private var partnerController
    @Injected(\.sdkInitializerConfiguration) private var configuration
    @OptionalInjected(\.customTaskDispatcher, default: .serialBackgroundQueue(name: "initializer")) private var taskDispatcher

    /// Indicates the current initialization status.
    private var initializationStatus: InitializationStatus = .uninitialized

    /// `true` if the Helium SDK is initialized, `false` otherwise.
    var isInitialized: Bool {
        taskDispatcher.sync(on: .background) {
            self.initializationStatus == .initialized
        }
    }

    /// Starts the initialization process.
    /// - Note: `completion` is called on the background thread. The caller is responsible for
    /// making calls on the main thread if necessary.
    func initialize(
        appIdentifier: String?,
        partnerIdentifiersToSkipInitialization: Set<PartnerIdentifier>,
        completion: @escaping (ChartboostMediationError?) -> Void
    ) {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Initialization started")

            // Finish early if already initialized or initializing
            guard initializationStatus == .uninitialized else {
                // If already initialized we report success
                if initializationStatus == .initialized {
                    logger.info("SDK already initialized")
                    completion(nil)
                } else {
                    // If already initializing we ignore silently (without calling completion).
                    // The ongoing process will finish at some point and call its completion, which should end up triggering one public
                    // delegate method call.
                    logger.info("Ignoring initialization attempt because there already is an ongoing initialization operation")
                }
                return
            }

            // Validate credentials before attempting to initialize
            if let error = credentialsValidator.validate(appIdentifier: appIdentifier) {
                logger.error("Initialization failed with error: \(error)")
                completion(error)
                return
            }

            // Save credentials to make them available to other components
            environment.app.appID = appIdentifier

            // Start fetching the user agent so it's available to pass on load requests when needed
            if environment.userAgent.userAgent == nil {
                environment.userAgent.updateUserAgent()
            }

            initializationStatus = .initializing

            // Fetch new app config from backend
            appConfigurationController.updateConfiguration { [weak self] appConfigSource, error in
                guard let self else { return }
                self.taskDispatcher.async(on: .background) {
                    // Even if we fail to update the configuration we report success, as long as we had a saved non-default
                    // configuration (one previously obtained from the backend and then persisted)
                    let sdkInitResult = SDKInitResult(appConfigSource: appConfigSource, hasError: error != nil)

                    guard sdkInitResult != .failure else {
                        // If config update failed and we have no persisted config we fail the initialization
                        self.initializationStatus = .uninitialized
                        self.metrics.logInitialization([], result: sdkInitResult, error: error)
                        logger.error("Initialization failed with error: \(error?.description ?? "nil")")
                        completion(error ?? ChartboostMediationError(code: .initializationFailureAborted))
                        return
                    }

                    // Initialize partner SDKs
                    self.partnerController.setUpAdapters(
                        configurations: self.configuration.partnerCredentials.mapValues(PartnerConfiguration.init),
                        adapterClasses: self.configuration.partnerAdapterClassNames,
                        skipping: partnerIdentifiersToSkipInitialization
                    ) { metricsEvents in
                        self.metrics.logInitialization(metricsEvents, result: sdkInitResult, error: error)
                    }
                    // Wait one second to give partners a bit of time to initialize, then report success
                    self.taskDispatcher.async(on: .background, after: self.configuration.initTimeout) {
                        self.initializationStatus = .initialized
                        logger.info("Initialization succeeded")
                        completion(nil)
                    }
                }
            }
        }
    }
}

extension SDKInitResult {
    fileprivate init(appConfigSource: ApplicationConfigurationSource, hasError: Bool) {
        switch appConfigSource {
        case .backend:
            self = .successWithFetchedConfig
        case .localCache:
            self = hasError ? .successWithCachedConfigAndError : .successWithCachedConfig
        case .hardcodedDefault:
            self = .failure
        }
    }
}
