// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

typealias BidderTokens = [PartnerIdentifier: [String: String]]

/// Configuration for a PartnerController.
protocol PartnerControllerConfiguration {
    /// The amount of seconds to wait for all partner networks to fetch the token used for the ad request auction.
    var prebidFetchTimeout: TimeInterval { get }
    /// The timeout before posting initialization metrics.  Defaults to 5.0.
    var initMetricsPostTimeout: TimeInterval { get }
}

/// PartnerController implementation that communicates with partner networks via PartnerAdapter objects.
final class PartnerAdapterController: PartnerController {
    
    /// Initialized partner adapters.
    private var initializedAdapters: [PartnerIdentifier: PartnerAdapter] = [:]
    /// Indicates if the controller has been set up.
    private var isInitialized = false
    /// Storage objects that hold on to partner ads created by adapters.
    private var adaptersStorage: [PartnerIdentifier: MutablePartnerAdapterStorage] = [:]
    
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
    
    var initializedAdapterInfo: [PartnerIdentifier: PartnerAdapterInfo] {
        initializedAdapters.mapValues {
            PartnerAdapterInfo(
                partnerVersion: $0.partnerSDKVersion,
                adapterVersion: $0.adapterVersion,
                partnerIdentifier: $0.partnerIdentifier,
                partnerDisplayName: $0.partnerDisplayName
            )
        }
    }
    
    // We assume this method will be called only once.
    func setUpAdapters(
        configurations: [PartnerIdentifier: PartnerConfiguration],
        adapterClasses: Set<String>,
        skipping partnerIdentifiersToSkip: Set<PartnerIdentifier>,
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
                guard let configuration = configurations[adapter.partnerIdentifier] else {
                    continue
                }
                
                // Intentionally skip initialization of the adapter
                guard !partnerIdentifiersToSkip.contains(adapter.partnerIdentifier) else {
                    initEvents.append(MetricsEvent(start: start,
                                                   error: ChartboostMediationError(code: .initializationSkipped),
                                                   partnerIdentifier: adapter.partnerIdentifier,
                                                   partnerSDKVersion: adapter.partnerSDKVersion,
                                                   partnerAdapterVersion: adapter.adapterVersion))
                    continue
                }
                                
                adaptersStorage[adapter.partnerIdentifier] = storage
                
                group.add { finished in
                    adapter.setUp(with: configuration) { [weak self, adapter] error in  // the closure itself holds a strong reference to the adapter keeping it alive until it is executed
                        guard let self = self else { return }
                        self.taskDispatcher.async(on: .background) {
                            if let error = error {
                                let chartboostMediationError = error as? ChartboostMediationError ?? .init(code: adapter.mapSetUpError(error) ?? .initializationFailureUnknown, error: error)
                                initEvents.append(MetricsEvent(start: start,
                                                               error: chartboostMediationError,
                                                               partnerIdentifier: adapter.partnerIdentifier,
                                                               partnerSDKVersion: adapter.partnerSDKVersion,
                                                               partnerAdapterVersion: adapter.adapterVersion))
                            } else {
                                self.initializedAdapters[adapter.partnerIdentifier] = adapter
                                self.setAlreadySetConsents(on: adapter)
                                initEvents.append(MetricsEvent(start: start,
                                                               partnerIdentifier: adapter.partnerIdentifier,
                                                               partnerSDKVersion: adapter.partnerSDKVersion,
                                                               partnerAdapterVersion: adapter.adapterVersion))
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
                    !initEvents.contains(where: { $0.partnerIdentifier == adapter.partnerIdentifier })
                }
                // Post event to user
                initResultsEventPublisher.postInitResultsEvent(InitResultsEvent(
                    sessionId: environment.session.sessionID.uuidString,
                    skipped: Array(partnerIdentifiersToSkip),
                    success: initEvents.filter { $0.error == nil },
                    failure: initEvents.filter { $0.error != nil },
                    inProgress: pendingAdapters.map { .init(partner: $0.partnerIdentifier, start: start) }
                ))
                
                // Mark all pending partners as timed out
                for adapter in pendingAdapters {
                    initEvents.append(MetricsEvent(start: start,
                                                   error: ChartboostMediationError(code: .initializationFailureTimeout),
                                                   partnerIdentifier: adapter.partnerIdentifier,
                                                   partnerSDKVersion: adapter.partnerSDKVersion,
                                                   partnerAdapterVersion: adapter.adapterVersion))
                }
                // Log metrics
                completion(initEvents)
            }
        }
    }
    
    func routeFetchBidderInformation(request: PreBidRequest, completion: @escaping ([PartnerIdentifier: [String: String]]) -> Void) {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Routing bidder info fetch to all adapters with placement \(request.chartboostPlacement) and load ID \(request.loadID)")
            // Resulting partner information used in the RTB request.
            var aggregatedTokens: BidderTokens = [:]
            // Create a dispatch group to asynchronously fetch bidding tokens and wait until
            // all partners have given back their bidding information, or the timeout elapses.
            let group = taskDispatcher.group(on: .background)
            // Prebid metric events
            var prebidEvents: [MetricsEvent] = []
            // Iterate over all partner networks and obtain information to be sent up in
            // the auction request.
            for (partnerIdentifier, adapter) in initializedAdapters {
                group.add { finished in     // this adds the following closure as a task to the group
                    // Capture current timestamp to evaluate how long the token fetch takes
                    let fetchStart = Date()
                    adapter.fetchBidderInformation(request: request) { [weak self] info in
                        self?.taskDispatcher.async(on: .background) {
                            // Conclude the prebid event
                            prebidEvents.append(MetricsEvent(start: fetchStart, partnerIdentifier: partnerIdentifier))
                            // Add the fetched tokens
                            aggregatedTokens[partnerIdentifier] = info
                            // Mark the group task as finished
                            finished()
                        }
                    }
                }
            }
            // Wait for all responses up to the timeout.
            group.onAllFinished(timeout: configuration.prebidFetchTimeout) { [weak self] in
                // Post the prebid events
                self?.metrics.logPrebid(loadID: request.loadID, events: prebidEvents)
                // Return the tokens
                logger.debug("Received bidder info from adapters with placement \(request.chartboostPlacement) and load ID \(request.loadID)")
                completion(aggregatedTokens)
            }
        }
    }
    
    func routeLoad(request: PartnerAdLoadRequest, viewController: UIViewController?, delegate: PartnerAdDelegate, completion: @escaping (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void) -> CancelAction {
        taskDispatcher.sync(on: .background) { [self] in    // sync operation so we can return the cancel action with info about the created ad
            logger.debug("Routing load to \(request.partnerIdentifier) for \(request.format) ad with placement \(request.partnerPlacement)")
            // Fail early if adapter is not initialized
            guard let adapter = initializedAdapters[request.partnerIdentifier] else {
                logger.error("Routing load failed for uninitialized partner \(request.partnerIdentifier)")
                completion(.failure(ChartboostMediationError(code: .loadFailurePartnerNotInitialized)))
                return {}
            }
            do {
                // Create partner ad and store it. Banners are handled on the main thread since they generally make use of UIKit
                let makeAd = { try adapter.makeAd(request: request, delegate: delegate) }
                let ad = request.format.isBanner
                    ? try taskDispatcher.sync(on: .main, execute: makeAd)
                    : try makeAd()
                addToStorage(ad)
                
                // Partner load. Banners are handled on the main thread since they generally make use of UIKit
                taskDispatcher.async(on: request.format.isBanner ? .main : .background) {     // here we switch to async to make sure we are not clogging the UI thread with the previous sync
                    ad.load(with: viewController) { [weak self, weak ad] result in
                        self?.taskDispatcher.async(on: .background) {
                            // If ad is nil or not in storage that means it was invalidated and the load result should be ignored
                            guard let ad = ad, self?.isInStorage(ad) == true else {
                                logger.warning("Discarding load result for invalidated \(request.partnerIdentifier) ad with placement \(request.partnerPlacement)")
                                return
                            }
                            switch result {
                            case .success(let partnerDetails):
                                // On success report back with a loaded partner ad
                                logger.info("Received load success from \(request.partnerIdentifier) for \(request.format) ad with placement \(request.partnerPlacement)")
                                completion(.success((ad, partnerDetails)))
                            case .failure(let error):
                                // On failure we dispose of the partner ad and report back with error
                                logger.error("Received load failure from \(request.partnerIdentifier) for \(request.format) ad with placement \(request.partnerPlacement) and error: \(error)")
                                self?.routeInvalidate(ad) { _ in }
                                completion(.failure(error as? ChartboostMediationError ?? .init(code: adapter.mapLoadError(error) ?? .loadFailureUnknown, error: error)))
                            }
                        }
                    }
                }
                /// Return the cancel action that invalidates the created ad when executed
                return { [weak self] in
                    logger.debug("Load cancelled on \(request.partnerIdentifier) for \(request.format) ad with placement \(request.partnerPlacement)")
                    self?.routeInvalidate(ad, completion: { _ in })
                }
            } catch {
                // Failed to create the partner ad
                logger.error("Routing load failed with error: \(error)")
                completion(.failure(error as? ChartboostMediationError ?? .init(code: adapter.mapLoadError(error) ?? .loadFailureUnknown, error: error)))
                return {}
            }
        }
    }
    
    func routeShow(_ ad: PartnerAd, viewController: UIViewController, completion: @escaping (ChartboostMediationError?) -> Void) {
        taskDispatcher.async(on: .main) {
            logger.debug("Routing show to \(ad.request.partnerIdentifier) for \(ad.request.format) ad with placement \(ad.request.partnerPlacement)")
            // Partner show
            ad.show(with: viewController) { [weak ad] result in
                let error = result.error.map { $0 as? ChartboostMediationError ?? .init(code: ad?.adapter.mapShowError($0) ?? .showFailureUnknown, error: $0) }
                if let error {
                    logger.error("Received show failure from \(ad?.request.partnerIdentifier ?? "nil") for \(ad?.request.format.rawValue ?? "nil") ad with placement \(ad?.request.partnerPlacement ?? "nil") and error: \(error)")
                } else {
                    logger.info("Received show success from \(ad?.request.partnerIdentifier ?? "nil") for \(ad?.request.format.rawValue ?? "nil") ad with placement \(ad?.request.partnerPlacement ?? "nil")")
                }
                // We ignore the details parameter for now
                completion(error)
            }
        }
    }

    func routeInvalidate(_ ad: PartnerAd, completion: @escaping (ChartboostMediationError?) -> Void) {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Routing invalidate to \(ad.request.partnerIdentifier) for \(ad.request.format) ad with placement \(ad.request.partnerPlacement)")
            
            // Remove the partner ad from storage
            removeFromStorage(ad)
            
            // Partner invalidate
            do {
                try ad.invalidate()
                completion(nil)
            } catch {
                completion(error as? ChartboostMediationError ?? .init(code: ad.adapter.mapInvalidateError(error) ?? .invalidateFailureUnknown, error: error))
            }
        }
    }
    
    // MARK: - ConsentSettingsDelegate
    
    func didChangeGDPR() {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Routing GDPR consent change to all adapters")
            for adapter in initializedAdapters.values {
                setGDPRConsent(on: adapter)
            }
        }
    }
    
    func didChangeCCPA() {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Routing CCPA consent change to all adapters")
            for adapter in initializedAdapters.values {
                setCCPAConsent(on: adapter)
            }
        }
    }
    
    func didChangeCOPPA() {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Routing COPPA consent change to all adapters")
            for adapter in initializedAdapters.values {
                setCOPPAConsent(on: adapter)
            }
        }
    }
}

// MARK: - Helpers

private extension PartnerAdapterController {
    
    func addToStorage(_ ad: PartnerAd) {
        adaptersStorage[ad.adapter.partnerIdentifier]?.ads.append(ad)
    }
    
    func removeFromStorage(_ ad: PartnerAd) {
        adaptersStorage[ad.adapter.partnerIdentifier]?.ads.removeAll(where: { $0 === ad })
    }
    
    func isInStorage(_ ad: PartnerAd) -> Bool {
        adaptersStorage[ad.adapter.partnerIdentifier]?.ads.contains(where: { $0 === ad }) ?? false
    }
    
    func setAlreadySetConsents(on adapter: PartnerAdapter) {
        setGDPRConsent(on: adapter)
        setCCPAConsent(on: adapter)
        setCOPPAConsent(on: adapter)
    }
    
    func setGDPRConsent(on adapter: PartnerAdapter) {
        if consentSettings.isSubjectToGDPR != nil || consentSettings.gdprConsent != .unknown {
            adapter.setGDPR(applies: consentSettings.isSubjectToGDPR, status: consentSettings.gdprConsent)
        }
    }
    
    func setCCPAConsent(on adapter: PartnerAdapter) {
        if let ccpaConsent = consentSettings.ccpaConsent, let ccpaPrivacyString = consentSettings.ccpaPrivacyString {
            adapter.setCCPA(hasGivenConsent: ccpaConsent, privacyString: ccpaPrivacyString)
        }
    }
    
    func setCOPPAConsent(on adapter: PartnerAdapter) {
        if let coppaIsChildDirected = consentSettings.isSubjectToCOPPA {
            adapter.setCOPPA(isChildDirected: coppaIsChildDirected)
        }
    }
}
