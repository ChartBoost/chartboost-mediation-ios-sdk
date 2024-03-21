// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Application-wide FullscreenAdQueue settings
protocol FullscreenAdQueueConfiguration {
    /// Time, in seconds, to wait before retrying a failed load.
    var queueLoadTimeout: TimeInterval { get }
    /// The largest capacity allowed for queues. Should never be overridden.
    var maxQueueSize: Int { get }
    /// The default size for new queues that don't haven't been configured to any specific capacity on the dashboard.
    var defaultQueueSize: Int { get }
    /// The time (in seconds) that a loaded ad is allowed to wait in the queue before being expired.
    var queuedAdTtl: TimeInterval { get }
    /// The correct queue size for a particular placement.
    func queueSize(for: String) -> Int
}

/// Manages the pre-loading of fullscreen ads. Each `FullscreenAdQueue` manages ads for one placement.
@objcMembers
@objc(ChartboostMediationFullscreenAdQueue)
public class FullscreenAdQueue: NSObject {
    @Injected(\.adLoader) private var adLoader
    @Injected(\.environment) private static var environment
    @Injected(\.fullscreenAdQueueConfiguration) private static var configuration
    @Injected(\.initializationStatusProvider) private var initializationStatusProvider
    @Injected(\.loadRateLimiter) private var loadRateLimiter
    @Injected(\.metrics) private var metrics

    // A static TaskDispatcher needs to be available to the static queue(forPlacement:) constructor
    @OptionalInjected(
        \.customTaskDispatcher,
         default: .serialBackgroundQueue(name: "fullscreenAdQueueStatic")
    ) private static var staticTaskDispatcher
    // Yes, there's already a class-level TaskDispatcher, but lets not make all the instances share.
    @OptionalInjected(
        \.customTaskDispatcher,
         default: .serialBackgroundQueue(name: "fullscreenAdQueueInstance")
    ) private var instanceTaskDispatcher

    private typealias QueuedAd = (fullscreenAd: ChartboostMediationFullscreenAd, expirationTime: DispatchTask)

    private enum LoadingState {
        case idle
        case waitingToRetry(waitTask: DispatchTask)
        case loading
    }

    private enum QueueState {
        case stopped
        case running
        case waitingForSDKInit(observer: NSObjectProtocol)
    }

    private class QueuedAdDelegate: ChartboostMediationFullscreenAdDelegate {
        weak var fullscreenAdQueue: FullscreenAdQueue?

        init(fullscreenAdQueue: FullscreenAdQueue) {
            self.fullscreenAdQueue = fullscreenAdQueue
        }

        func didExpire(ad: ChartboostMediationFullscreenAd) {
            guard let fullscreenAdQueue else { return }
            fullscreenAdQueue.instanceTaskDispatcher.async(on: .background) { [weak self] in
                guard self != nil else { return }
                // If the ad is still in the queue, remove it
                if let expiredAdIndex = fullscreenAdQueue.queue.firstIndex(where: { $0.fullscreenAd === ad }) {
                    fullscreenAdQueue.queue.remove(at: expiredAdIndex)
                }
                // Log the expiration event
                let auctionID = ad.winningBidInfo[LoadedAd.auctionIDKey] as? String ?? ""
                fullscreenAdQueue.metrics.logExpiration(
                    auctionID: auctionID,
                    loadID: ad.loadID
                )
                // If the ad queue has a delegate, notify it about this deletion
                fullscreenAdQueue.instanceTaskDispatcher.async(on: .main) {
                    fullscreenAdQueue.delegate?.fullscreenAdQueueDidRemoveExpiredAd?(
                        fullscreenAdQueue,
                        numberOfAdsReady: fullscreenAdQueue.numberOfAdsReady
                    )
                }
                // If the queue is running, we want to make sure the expired ad gets replaced
                fullscreenAdQueue.updateLoadingState()
            }
        }
    }

    // References to all queues we've created so far, so that if someone tries to create a second
    // queue with a previously used placement ID we can simply return the original instance
    private static var instances: [String: FullscreenAdQueue] = [:]

    /// Returns a FullscreenAdQueue. Queue will not begin loading ads until `startRunning()` is called.
    /// Calling `FullscreenAdQueue.queue(forPlacement:)` more than once with the same placement ID
    /// returns the same object each time.
    /// - parameter forPlacement: Identifier for the Chartboost placement this queue should load ads from.
    public static func queue(forPlacement placement: String) -> FullscreenAdQueue {
        // Must strongly capture self because return type is non-optional so
        // we can't guard against self being nil
        staticTaskDispatcher.sync(on: .background) { [self] in
            if let existingInstance = instances[placement] {
                return existingInstance
            } else {
                let newQueue = FullscreenAdQueue(placement: placement)
                instances[placement] = newQueue
                return newQueue
            }
        }
    }
    // Swiftlint doesn't know that lazy vars can't be weak.
    // I made the reference to the FullscreenAdQueue inside QueuedAdDelegate weak instead.
    // swiftlint:disable weak_delegate
    private lazy var fullscreenAdDelegate: QueuedAdDelegate = {
        return QueuedAdDelegate(fullscreenAdQueue: self)
    }()
    // swiftlint:enable weak_delegate
    private var isFull: Bool {
        return numberOfAdsReady >= queueCapacity
    }
    private var loadingState: LoadingState = .idle {
        didSet {
            loadingStateDidTransition(from: oldValue, to: loadingState)
        }
    }
    internal let maxQueueSize: Int
    internal let placement: String
    @Atomic private var queue: [QueuedAd] = []
    private (set) var queueID = ""
    private var queueState: QueueState = .stopped {
        didSet {
            queueStateDidTransition(from: oldValue, to: queueState)
        }
    }

    /// The delegate is notified each time an ad load completes and each time a queued ad expires.
    public weak var delegate: FullscreenAdQueueDelegate?
    /// `true` when calling `getNextAd()` would return a `ChartboostMediationFullscreenAd`
    public var hasNextAd: Bool {
        // Thread-safe because queue is @Atomic
        !queue.isEmpty
    }
    /// When the queue is running it will attempt to pre-load more ads any time `numberOfAdsReady` < `queueCapacity`
    public var isRunning: Bool {
        instanceTaskDispatcher.sync(on: .background) { [self] in
            switch self.queueState {
            case .running:
                return true
            default:
                return false
            }
        }
    }
    @Atomic private var _keywords: [String: String] = [:]
    /// This keyword dictionary is used in each `ChartboostMediationAdLoadRequest` sent by the queue.
    public var keywords: [String: String] {
        get {
            _keywords
        }
        set {
            _keywords = newValue
        }
    }
    /// Number of ready-to-show ads that can currently be retrieved with `getNextAd()`
    public var numberOfAdsReady: Int {
        // Thread-safe because queue is @Atomic
            return self.queue.count
    }
    // `queueCapacity` is implemented like this in order to prevent an auto-generated setter for
    // Objective C from being created, because it would be named `setQueueCapacity` and conflict
    // with the `setQueueCapacity` method that already exists on this class.
    @Atomic private var _queueCapacity: Int
    /// Maximum number of loaded ads the queue can hold at one time.
    public var queueCapacity: Int {
        // Thread-safe because _queueCapacity is @Atomic
            _queueCapacity
    }

    private init(placement: String) {
        // If a test value for maxQueueSize has been set, use it. Otherwise, use the value that is set in the app config.
        maxQueueSize = FullscreenAdQueue.environment.testMode.fullscreenAdQueueMaxSize ??
            FullscreenAdQueue.configuration.maxQueueSize
        // If a test value for queue size has been set, use it. Otherwise, use the value that is set in the app config.
        let placementQueueSize = FullscreenAdQueue.environment.testMode.fullscreenAdQueueRequestedSize ??
            FullscreenAdQueue.configuration.queueSize(for: placement)
        // maxQueueSize needs to override ALL larger queue size settings.
        _queueCapacity = min(placementQueueSize, maxQueueSize)
        if placementQueueSize > maxQueueSize {
            logger.error("Queue size setting of \(placementQueueSize) exceedes maximum. Setting queue size to maximum allowed value of \(maxQueueSize)")
        }
        self.placement = placement
    }

    private func adLoadCompletion(fullscreenAdLoadResult: ChartboostMediationFullscreenAdLoadResult) {
        func sendDelegateAdLoadResult(fullscreenAdLoadResult: ChartboostMediationFullscreenAdLoadResult) {
            // This is done so that we don't return a pointer to a queued ad after successful loads.
            // ChartboostMediationFullscreenAdLoadResult contains a reference to the ad, but
            // ChartboostMediationAdLoadResult does not.
            // Upcasting the original object leaves open the possiblity that someone could re-cast it
            // to access the ad, so we'll create a new ChartboostMediationAdLoadResult instead.
            let adLoadResult = ChartboostMediationAdLoadResult(
                error: fullscreenAdLoadResult.error,
                loadID: fullscreenAdLoadResult.loadID,
                metrics: fullscreenAdLoadResult.metrics
            )

            instanceTaskDispatcher.async(on: .main) { [weak self] in
                guard let self else { return }
                self.delegate?.fullscreenAdQueue?(
                    self,
                    didFinishLoadingWithResult: adLoadResult,
                    numberOfAdsReady: self.numberOfAdsReady
                )
            }
        }

        if let ad = fullscreenAdLoadResult.ad {
            // Set ourselves as the delegate so that we're notified if the ad expires
            ad.delegate = fullscreenAdDelegate

            // Start expiration timer
            // If a test value for queuedAdTtl has been set, use it. Otherwise, use the value that is set in the app config.
            let lifespanInSeconds = FullscreenAdQueue.environment.testMode.fullscreenAdQueueTTL ??
                FullscreenAdQueue.configuration.queuedAdTtl
            let expirationTask = instanceTaskDispatcher.async(
                on: .background,
                delay: lifespanInSeconds
            ) { [weak self] in
                guard let self else { return }
                self.fullscreenAdDelegate.didExpire(ad: ad)
            }
            // Save the ad and expiration timer
            let queueableItem = QueuedAd(ad, expirationTask)
            queue.append(queueableItem)
            sendDelegateAdLoadResult(fullscreenAdLoadResult: fullscreenAdLoadResult)
            loadingState = .idle
            self.updateLoadingState()
        } else {
            logger.debug("Failed to load ad for placement \(placement)")
            sendDelegateAdLoadResult(fullscreenAdLoadResult: fullscreenAdLoadResult)
            let configuredRateLimit = loadRateLimiter.timeUntilNextLoadIsAllowed(placement: placement)
            let delay = max(FullscreenAdQueue.configuration.queueLoadTimeout, configuredRateLimit)
            logger.debug("Pausing load attempts for \(delay) seconds")
            let waitTask = instanceTaskDispatcher.async(
                on: .background,
                delay: delay
            ) { [weak self] in
                guard let self else { return }
                self.loadingState = .idle
                self.updateLoadingState()
            }
            loadingState = .waitingToRetry(waitTask: waitTask)
        }
    }

    private func updateLoadingState() {
        // Whether or not to start a load depends on three things:
        // 1. Is the queue running?
        // 2. Are we already in the middle of a load?
        // 3. Does the queue need more ads than it currently has?
        instanceTaskDispatcher.async(on: .background) { [weak self] in
            guard let self else { return }
            // (1) Continue only if we're running.
            switch self.queueState {
            case .stopped, .waitingForSDKInit:
                return
            case .running:
                break
            }
            // (2) Continue only if we're not in the middle of loading.
            switch self.loadingState {
            case .waitingToRetry, .loading:
                return
            case .idle:
                break
            }
            // (3) Don't load any more ads if we're already full
            guard self.numberOfAdsReady < self.queueCapacity else {
                return
            }
            // Now we know that we should load an ad.
            self.loadingState = .loading
        }
    }

    /// Returns the oldest ad in the queue, or `nil` if the queue is empty
    public func getNextAd() -> ChartboostMediationFullscreenAd? {
        instanceTaskDispatcher.sync(on: .background) { [weak self] in
            guard let self else { return nil }
            guard !self.queue.isEmpty else { return nil }
            let nextQueuedItem = self.queue.removeFirst()
            // Need to call this method whenever an ad has been removed from the queue
            self.updateLoadingState()
            // Decompose tuple
            let (ad, expirationTask) = nextQueuedItem
            expirationTask.cancel()
            // Ads in-queue have the queue set as a delegate so we can catch expirations.
            // Ads being handed to the caller should not have a delegate set.
            ad.delegate = nil
            return ad
        }
    }

    /// Request a new queue size. If the number of ad slots requested is larger than the maximum configured by the dashboard.
    /// this method will log an error and return `nil`
    /// - parameter requestedMaximum: The most loaded ads the queue should be able to hold at once.
    public func setQueueCapacity(_ requestedMaximum: Int) {
        instanceTaskDispatcher.async(on: .background) { [weak self] in
            guard let self else { return }
            if requestedMaximum > self.maxQueueSize {
                logger.error(
                    "Attempt to set queue size of \(requestedMaximum) failed. Setting queue size to maximum allowed value of \(self.maxQueueSize)"
                )
                self._queueCapacity = self.maxQueueSize
            } else if requestedMaximum < 1 {
                logger.error(
                    "Attempt to set queue size of \(requestedMaximum) failed. Setting queue size to minimum allowed value of 1"
                )
                self._queueCapacity = 1
            } else {
                self._queueCapacity = requestedMaximum
            }
        }
    }

    /// Tell the queue to begin running. When running, the queue will load ads until it reaches full capacity. If ads are removed from
    /// a running queue, it will resume loading in order to replace them. To stop a running queue, call `stop()`.
    /// Calling `start()` on a running queue does nothing.
    public func start() {
        instanceTaskDispatcher.async(on: .background) { [weak self] in
            guard let self else { return }
            switch self.queueState {
            case .running:
                logger.info("Queue already running.")
            case .stopped:
                // This guard block covers the edge case where a publisher calls start() before
                // the SDK is done initializing. Queue should automatically start when the SDK
                // is ready, unless stop() has been called in the meantime.
                guard self.initializationStatusProvider.isInitialized else {
                    let observer = NotificationCenter.default.addObserver(
                        forName: .heliumDidFinishInitializing,
                        object: nil,
                        queue: nil
                    ) { _ in
                        switch self.queueState {
                        case .running:
                            // This case should be impossible.
                            break
                        case .stopped:
                            // stopQueue was called after earlier attempt to start queue. Do nothing.
                            break
                        case .waitingForSDKInit:
                            self.queueState = .running
                        }
                    }
                    self.queueState = .waitingForSDKInit(observer: observer)
                    return
                }
                // The expected case is simple.
                self.queueState = .running
            case .waitingForSDKInit:
                logger.info("Queue will run after Chartboost Mediation SDK has been initialized")
            }
        }
    }

    /// Stops a running queue so that it will not send any more ad load requests. One additional ad may be loaded into the queue after
    /// calling this if there is already a request "in flight". Calling `stop()` on a stopped queue does nothing.
    public func stop() {
        instanceTaskDispatcher.async(on: .background) { [weak self] in
            guard let self else { return }
            self.queueState = .stopped
        }
    }

    private func queueStateDidTransition(from oldState: QueueState, to newState: QueueState) {
        /*
        queueState can be changed by the start() and stop() methods on FullscreenAdQueue, or by
        the closure that is sometimes created inside start() and fires on completion of SDK init.
        loadingState cannot affect queueState, but changes to queueState sometimes initiate changes
        to loadingState.

        This function covers all valid state transitions. It is up to the code that sets queueState
        to only attempt valid transitions. To see a graph of valid state transitions, paste the
        follwing lines into a mermaid.js tool such as https://mermaid.live

        stateDiagram-v2
            Stopped --> PreInit
            Stopped --> Running
            PreInit --> Stopped
            PreInit --> Running
            Running --> Stopped
            Running --> Running
            Stopped --> Stopped
        */
        instanceTaskDispatcher.async(on: .background) { [weak self] in
            guard let self else { return }
            switch (oldState, newState) {
            case (.stopped, .waitingForSDKInit):
                break
            case (.stopped, .running):
                // Queue gets a new ID every time it starts.
                self.queueID = UUID().uuidString
                self.metrics.logStartQueue(self)
                // We may or may not need to begin loading.
                self.updateLoadingState()
            case (.waitingForSDKInit(let observer), .stopped):
                // Any time we leave the waiting state, remove the associated observer.
                NotificationCenter.default.removeObserver(observer)
            case (.waitingForSDKInit(let observer), .running):
                // Any time we leave the waiting state, remove the associated observer.
                NotificationCenter.default.removeObserver(observer)
                // Queue gets a new ID every time it starts.
                self.queueID = UUID().uuidString
                self.metrics.logStartQueue(self)
                // We'll want to start loading ads now.
                self.updateLoadingState()
            case (.running, .stopped):
                self.metrics.logEndQueue(self)
                // Cover valid self-transitions so that an error can be logged on all invalid transitions.
            case (.running, .running):
                break
            case (.stopped, .stopped):
                break
            default:
                logger.error("Invalid QueueState transition.")
            }
        }
    }

    private func loadingStateDidTransition(from oldState: LoadingState, to newState: LoadingState) {
        /*
         loadingState is only changed by updateLoadingState() and adLoadCompletion(), and
         updateLoadingState() checks queueState when deciding what to do so there's an indirect
         one-way connection from queueState to loadingState.

         This function covers all valid state transitions. It is up to the code that sets
         loadingState to only attempt valid transitions. To see a graph of valid state transitions,
         paste the follwing lines into a mermaid.js tool such as https://mermaid.live

         stateDiagram-v2
             idle --> loading
             loading --> waitingToRetry
             waitingToRetry --> idle
             loading --> idle
         */
        instanceTaskDispatcher.async(on: .background) { [weak self] in
            guard let self else { return }
            switch (oldState, newState) {
            case (.idle, .loading):
                // When going from idle to loading, initiate a load.
                let request = ChartboostMediationAdLoadRequest(
                    placement: self.placement,
                    keywords: self._keywords,
                    queueID: self.queueID
                )
                self.adLoader.loadFullscreenAd(with: request) { [weak self] cmFullscreenAdLoadResult in
                    guard let self else { return }
                    self.instanceTaskDispatcher.async(on: .background) { [weak self] in
                        guard let self else { return }
                        self.adLoadCompletion(fullscreenAdLoadResult: cmFullscreenAdLoadResult)
                    }
                }
            case (.loading, .waitingToRetry(_)):
                // This transition only happens in adLoadCompletion, which is responsible for
                // creating a task that will eventually cause a waitingToRetry->idle transition
                break
            case (.waitingToRetry(_), .idle):
                // The queue could have been stopped while we were waiting to retry, so we may or
                // may not need to continue attempting to load an ad.
                self.updateLoadingState()
            case (.loading, .idle):
                // When a load ends and the queue is full or has been stopped
                break
            default:
                logger.error("Invalid LoadingState transition.")
            }
        }
    }
}
