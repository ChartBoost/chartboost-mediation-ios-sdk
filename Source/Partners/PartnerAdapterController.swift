// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK
import Foundation

typealias BidderTokens = [PartnerID: [String: String]]

/// Configuration for a PartnerController.
protocol PartnerControllerConfiguration {
    /// The amount of seconds to wait for all partner networks to fetch the token used for the ad request auction.
    var prebidFetchTimeout: TimeInterval { get }
    /// The timeout before posting initialization metrics. Defaults to 5.0.
    var initMetricsPostTimeout: TimeInterval { get }
}

/// PartnerController implementation that communicates with partner networks via PartnerAdapter objects.
final class PartnerAdapterController: PartnerController {
    /// Initialized partner adapters.
    private var initializedAdapters: [PartnerID: PartnerAdapter] = [:]
    /// Indicates if the controller has been set up.
    private var isInitialized = false
    /// Storage objects that hold on to partner ads created by adapters.
    private var adaptersStorage: [PartnerID: MutablePartnerAdapterStorage] = [:]

    /// Factory to obtain partner adapter instances.
    @Injected(\.adapterFactory) private var adapterFactory
    /// Used to dispatch work asynchronously and in a thread-safe way.
    @OptionalInjected(\.customTaskDispatcher, default: .serialBackgroundQueue(name: "partnercontroller")) private var taskDispatcher
    @Injected(\.environment) private var environment
    /// Used to access configuration values.
    @Injected(\.partnerControllerConfiguration) private var configuration
    /// Used to log metrics events
    @Injected(\.metrics) private var metrics
    /// Used to post init events
    @Injected(\.initResultsEventPublisher) private var initResultsEventPublisher
    /// The user privacy consent settings manager
    @Injected(\.consentSettings) private var consentSettings

    init() {
        // Start listening to consent changes
        assert(consentSettings.delegate == nil, "there should be only one consent settings delegate")
        consentSettings.delegate = self
    }

    // MARK: - PartnerController

    var initializedAdapterInfo: [PartnerID: InternalPartnerAdapterInfo] {
        initializedAdapters.mapValues {
            InternalPartnerAdapterInfo(
                partnerVersion: $0.configuration.partnerSDKVersion,
                adapterVersion: $0.configuration.adapterVersion,
                partnerID: $0.configuration.partnerID,
                partnerDisplayName: $0.configuration.partnerDisplayName
            )
        }
    }

    // We assume this method will be called only once.
    func setUpAdapters(
        credentials: [PartnerID: [String: Any]],
        adapterClasses: Set<String>,
        skipping partnerIDsToSkip: Set<PartnerID>,
        completion: @escaping ([MetricsEvent]) -> Void
    ) {
        taskDispatcher.async(on: .background) { [self] in
            // We allow to set up only once. This is only a safeguard in case we call setUpAdapters() twice due to a mistake.
            // If we ever want to allow multiple set ups we will need to review the implementation below.
            guard !isInitialized else {
                logger.error("Failed to initialize adapters: initialization already happened")
                return
            }
            isInitialized = true

            logger.debug("Initializing partner adapters")

            // Create adapters
            let adapters = adapterFactory.adapters(fromClassNames: adapterClasses)

            // Create a dispatch group to asynchronously set up adapters and wait until they are all done or the timeout hits.
            let group = taskDispatcher.group(on: .background)
            var initEvents: [MetricsEvent] = []
            let start = Date()

            // Set up adapters
            for (adapter, storage) in adapters {
                guard let partnerCredentials = credentials[adapter.configuration.partnerID] else {
                    continue
                }
                let configuration = PartnerConfiguration(
                    credentials: partnerCredentials,
                    consents: consentSettings.consents,
                    isUserUnderage: consentSettings.isUserUnderage
                )

                // Intentionally skip initialization of the adapter
                guard !partnerIDsToSkip.contains(adapter.configuration.partnerID) else {
                    initEvents.append(
                        MetricsEvent(
                            start: start,
                            error: ChartboostMediationError(code: .initializationSkipped),
                            partnerID: adapter.configuration.partnerID,
                            partnerSDKVersion: adapter.configuration.partnerSDKVersion,
                            partnerAdapterVersion: adapter.configuration.adapterVersion
                        )
                    )
                    continue
                }

                adaptersStorage[adapter.configuration.partnerID] = storage

                group.add { finished in
                    // the closure itself holds a strong reference to the adapter keeping it alive until it is executed
                    adapter.setUp(with: configuration) { [weak self, adapter] result in
                        guard let self else { return }
                        self.taskDispatcher.async(on: .background) {
                            switch result {
                            case .success:   // we ignore the details parameter for now
                                self.initializedAdapters[adapter.configuration.partnerID] = adapter
                                self.applyConsentChanges(to: adapter, initialConsents: configuration.consents)
                                initEvents.append(
                                    MetricsEvent(
                                        start: start,
                                        partnerID: adapter.configuration.partnerID,
                                        partnerSDKVersion: adapter.configuration.partnerSDKVersion,
                                        partnerAdapterVersion: adapter.configuration.adapterVersion
                                    )
                                )
                            case .failure(let error):
                                let chartboostMediationError = error as? ChartboostMediationError
                                    ?? .init(code: adapter.mapSetUpError(error) ?? .initializationFailureUnknown, error: error)
                                initEvents.append(
                                    MetricsEvent(
                                        start: start,
                                        error: chartboostMediationError,
                                        partnerID: adapter.configuration.partnerID,
                                        partnerSDKVersion: adapter.configuration.partnerSDKVersion,
                                        partnerAdapterVersion: adapter.configuration.adapterVersion
                                    )
                                )
                            }
                            finished()
                        }
                    }
                }
            }

            // Wait for all responses up to the timeout.
            group.onAllFinished(timeout: configuration.initMetricsPostTimeout) { [self] in
                // Get list of pending adapters
                let pendingAdapters = adapters.map(\.0).filter { adapter in
                    !initEvents.contains(where: { $0.partnerID == adapter.configuration.partnerID })
                }
                // Post event to user
                initResultsEventPublisher.postInitResultsEvent(InitResultsEvent(
                    sessionId: environment.session.sessionID,
                    skipped: Array(partnerIDsToSkip),
                    success: initEvents.filter { $0.error == nil },
                    failure: initEvents.filter { $0.error != nil },
                    inProgress: pendingAdapters.map { .init(partner: $0.configuration.partnerID, start: start) }
                ))

                // Mark all pending partners as timed out
                for adapter in pendingAdapters {
                    initEvents.append(
                        MetricsEvent(
                            start: start,
                            error: ChartboostMediationError(code: .initializationFailureTimeout),
                            partnerID: adapter.configuration.partnerID,
                            partnerSDKVersion: adapter.configuration.partnerSDKVersion,
                            partnerAdapterVersion: adapter.configuration.adapterVersion
                        )
                    )
                }
                // Log metrics
                completion(initEvents)
            }
        }
    }

    func routeFetchBidderInformation(request: PartnerAdPreBidRequest, completion: @escaping ([PartnerID: [String: String]]) -> Void) {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Routing bidder info fetch to all adapters with placement \(request.mediationPlacement) and load ID \(request.loadID)")
            // Resulting partner information used in the RTB request.
            var aggregatedTokens: BidderTokens = [:]
            // Create a dispatch group to asynchronously fetch bidding tokens and wait until
            // all partners have given back their bidding information, or the timeout elapses.
            let group = taskDispatcher.group(on: .background)
            // Prebid metric events
            var prebidEvents: [MetricsEvent] = []
            // Iterate over all partner networks and obtain information to be sent up in
            // the auction request.
            for (partnerID, adapter) in initializedAdapters {
                group.add { finished in     // this adds the following closure as a task to the group
                    // Capture current timestamp to evaluate how long the token fetch takes
                    let fetchStart = Date()
                    adapter.fetchBidderInformation(request: request) { [weak self] result in
                        self?.taskDispatcher.async(on: .background) {
                            // Conclude the prebid event
                            let error = result.error.map {
                                $0 as? ChartboostMediationError
                                    ?? .init(code: adapter.mapPrebidError($0) ?? .prebidFailureUnknown, error: $0)
                            }
                            prebidEvents.append(MetricsEvent(start: fetchStart, error: error, partnerID: partnerID))
                            // Add the fetched tokens
                            aggregatedTokens[partnerID] = try? result.get() // nil in case of failure
                            // Mark the group task as finished
                            finished()
                        }
                    }
                }
            }
            // Wait for all responses up to the timeout.
            group.onAllFinished(timeout: configuration.prebidFetchTimeout) { [weak self] in
                // Post the prebid events
                self?.metrics.logPrebid(for: request, events: prebidEvents)
                // Return the tokens
                logger.debug("Received bidder info from adapters with placement \(request.mediationPlacement) and load ID \(request.loadID)")
                completion(aggregatedTokens)
            }
        }
    }

    func routeLoad(
        request: PartnerAdLoadRequest,
        viewController: UIViewController?,
        delegate: PartnerAdDelegate,
        completion: @escaping (Result<PartnerAd, ChartboostMediationError>) -> Void
    ) -> CancelAction {
        // sync operation so we can return the cancel action with info about the created ad
        taskDispatcher.sync(on: .background) { [self] in
            logger.debug("Routing load to \(request.partnerID) for \(request.format) ad with placement \(request.partnerPlacement)")
            // Fail early if adapter is not initialized
            guard let adapter = initializedAdapters[request.partnerID] else {
                logger.error("Routing load failed for uninitialized partner \(request.partnerID)")
                completion(.failure(ChartboostMediationError(code: .loadFailurePartnerNotInitialized)))
                return {}
            }
            do {
                // Create partner ad and store it. Banners are handled on the main thread since they generally make use of UIKit
                let ad: PartnerAd
                if PartnerAdFormats.isBanner(request.format) {
                    ad = try taskDispatcher.sync(on: .main) {
                        try adapter.makeBannerAd(request: request, delegate: delegate)
                    }
                } else {
                    ad = try adapter.makeFullscreenAd(request: request, delegate: delegate)
                }
                addToStorage(ad)

                // Partner load. Banners are handled on the main thread since they generally make use of UIKit
                // here we switch to async to make sure we are not clogging the UI thread with the previous sync
                taskDispatcher.async(on: PartnerAdFormats.isBanner(request.format) ? .main : .background) {
                    ad.load(with: viewController) { [weak self, weak ad] optionalError in
                        self?.taskDispatcher.async(on: .background) {
                            // If ad is nil or not in storage that means it was invalidated and the load result should be ignored
                            guard let ad, self?.isInStorage(ad) == true else {
                                logger.warning("Discarding load result for invalidated \(request.partnerID) ad with placement \(request.partnerPlacement)")
                                return
                            }
                            if let error = optionalError {
                                // On failure we dispose of the partner ad and report back with error
                                logger.error("Received load failure from \(request.partnerID) for \(request.format) ad with placement \(request.partnerPlacement) and error: \(error)")
                                self?.routeInvalidate(ad) { _ in }
                                let chartboostMediationError = error as? ChartboostMediationError
                                    ?? .init(code: adapter.mapLoadError(error) ?? .loadFailureUnknown, error: error)
                                completion(.failure(chartboostMediationError))
                            } else {
                                // On success report back with a loaded partner ad
                                logger.info("Received load success from \(request.partnerID) for \(request.format) ad with placement \(request.partnerPlacement)")
                                completion(.success(ad))
                            }
                        }
                    }
                }
                // Return the cancel action that invalidates the created ad when executed
                return { [weak self] in
                    logger.debug("Load cancelled on \(request.partnerID) for \(request.format) ad with placement \(request.partnerPlacement)")
                    self?.routeInvalidate(ad, completion: { _ in })
                }
            } catch {
                // Failed to create the partner ad
                logger.error("Routing load failed with error: \(error)")
                let chartboostMediationError = error as? ChartboostMediationError
                    ?? .init(code: adapter.mapLoadError(error) ?? .loadFailureUnknown, error: error)
                completion(.failure(chartboostMediationError))
                return {}
            }
        }
    }

    func routeShow(_ ad: PartnerFullscreenAd, viewController: UIViewController, completion: @escaping (ChartboostMediationError?) -> Void) {
        taskDispatcher.async(on: .main) {
            logger.debug("Routing show to \(ad.request.partnerID) for \(ad.request.format) ad with placement \(ad.request.partnerPlacement)")
            // Partner show
            ad.show(with: viewController) { [weak ad] optionalError in
                if let error = optionalError {
                    let chartboostError =
                        (error as? ChartboostMediationError) ??
                        .init(
                            code: ad?.adapter.mapShowError(error) ?? .showFailureUnknown,
                            error: error
                    )
                    logger.error("Received show failure from \(ad?.request.partnerID ?? "nil") for \(ad?.request.format ?? "nil") ad with placement \(ad?.request.partnerPlacement ?? "nil") and error: \(error)")
                    completion(chartboostError)
                } else {
                    logger.info("Received show success from \(ad?.request.partnerID ?? "nil") for \(ad?.request.format ?? "nil") ad with placement \(ad?.request.partnerPlacement ?? "nil")")
                    completion(nil)
                }
            }
        }
    }

    func routeInvalidate(_ ad: PartnerAd, completion: @escaping (ChartboostMediationError?) -> Void) {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Routing invalidate to \(ad.request.partnerID) for \(ad.request.format) ad with placement \(ad.request.partnerPlacement)")

            // Remove the partner ad from storage
            removeFromStorage(ad)

            // Partner invalidate
            do {
                try ad.invalidate()
                completion(nil)
            } catch {
                let chartboostMediationError = error as? ChartboostMediationError
                    ?? .init(code: ad.adapter.mapInvalidateError(error) ?? .invalidateFailureUnknown, error: error)
                completion(chartboostMediationError)
            }
        }
    }
}

// MARK: - ConsentSettingsDelegate

extension PartnerAdapterController: ConsentSettingsDelegate {
    func setConsents(_ consents: [ConsentKey: ConsentValue], modifiedKeys: Set<ConsentKey>) {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Routing consent changes to all adapters")
            for adapter in initializedAdapters.values {
                adapter.setConsents(consents, modifiedKeys: modifiedKeys)
            }
        }
    }

    func setIsUserUnderage(_ isUserUnderage: Bool) {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Routing user underage changes to all adapters")
            for adapter in initializedAdapters.values {
                adapter.setIsUserUnderage(isUserUnderage)
            }
        }
    }
}

// MARK: - Helpers

extension PartnerAdapterController {
    private func addToStorage(_ ad: PartnerAd) {
        adaptersStorage[ad.adapter.configuration.partnerID]?.ads.append(ad)
    }

    private func removeFromStorage(_ ad: PartnerAd) {
        adaptersStorage[ad.adapter.configuration.partnerID]?.ads.removeAll(where: { $0 === ad })
    }

    private func isInStorage(_ ad: PartnerAd) -> Bool {
        adaptersStorage[ad.adapter.configuration.partnerID]?.ads.contains(where: { $0 === ad }) ?? false
    }

    private func applyConsentChanges(to adapter: PartnerAdapter, initialConsents: [ConsentKey: ConsentValue]) {
        // Calculate modified consent keys
        let currentConsents = consentSettings.consents
        var modifiedKeys = Set(initialConsents.keys.filter { key in
            currentConsents[key] != initialConsents[key]
        })   // consents that changed or were removed
        modifiedKeys.formUnion(currentConsents.keys.filter {
            initialConsents[$0] == nil
        })  // consents that were added
        // Notify adapter it any consent changed
        if !modifiedKeys.isEmpty {
            adapter.setConsents(currentConsents, modifiedKeys: modifiedKeys)
        }
    }
}
