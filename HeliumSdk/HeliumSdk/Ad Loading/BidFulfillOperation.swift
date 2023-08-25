// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// When asked to fulfill it goes bid by bid, asking the corresponding partner to fulfill the bid by loading an ad, and returns the first bid that was able to get fulfilled.
protocol BidFulfillOperation {
    /// Performs the fulfill operation. Should be only called once.
    func run(completion: @escaping (BidFulfillOperationResult) -> Void)
}

/// The result of a bid fulfill operation.
struct BidFulfillOperationResult {
    let result: Result<(winningBid: Bid, loadedAd: PartnerAd), ChartboostMediationError>
    let loadEvents: [MetricsEvent]
}

/// Configuration settings for BidFulfillOperation.
protocol BidFulfillOperationConfiguration {
    /// The amount of seconds to wait for a partner to load a fullscreen ad bid.
    var fullscreenLoadTimeout: TimeInterval { get }
    /// The amount of seconds to wait for a partner to load a banner ad bid.
    var bannerLoadTimeout: TimeInterval { get }
}

extension BidFulfillOperationConfiguration {
    /// The amount of seconds to wait for a partner to load an ad bid with the specified format.
    func loadTimeout(for adFormat: AdFormat) -> TimeInterval {
        switch adFormat {
        case .interstitial, .rewarded, .rewardedInterstitial:
            return fullscreenLoadTimeout
        case .banner:
            return bannerLoadTimeout
        }
    }
}

/// An BidFulfillOperation that uses PartnerController to fulfill the bids.
final class PartnerControllerBidFulfillOperation: BidFulfillOperation {
    
    /// The remaining bids to evaluate.
    private var bids: [Bid] = []
    /// The currently evaluated bid, waiting for the partnerController to finish a load.
    private var loadingBid: Bid?
    /// Load metrics events corresponding to each partner load attempt.
    private var loadEvents: [MetricsEvent] = []
    /// The load request that triggered the fulfill operation.
    private let request: HeliumAdLoadRequest
    /// The completion to be executed at the end of a fulfill operation.
    private var completion: ((BidFulfillOperationResult) -> Void)?
    /// Indicates if the `run()` method has already been called.
    private var hasRun = false
    /// The view controller used to load partner ads. Needed for banners. Will be nil for full-screen ads.
    private weak var viewController: UIViewController?
    /// The ad delegate passed on load that will receive ad life-cycle events.
    private weak var delegate: PartnerAdDelegate?
    /// A dispatch task scheduled when a partner is asked to load, which fires after the timeoutInterval to finish a load that takes too long.
    private var timeoutTask: DispatchTask?
    /// A closure to be executed in order to cancel the ongoing load operation on the partner controller side.
    private var cancelLoad: PartnerController.CancelAction?
    /// Configuration.
    @Injected(\.bidFulfillOperationConfiguration) private var configuration
    /// Task dispatcher.
    @Injected(\.taskDispatcher) private var taskDispatcher
    /// Partner controller, in charge of forwarding loads to the partners.
    @Injected(\.partnerController) private var partnerController
    
    init(bids: [Bid], request: HeliumAdLoadRequest, viewController: UIViewController?, delegate: PartnerAdDelegate) {
        self.bids = bids
        self.request = request
        self.viewController = viewController
        self.delegate = delegate
    }
    
    /// Tries to fulfill the bids one by one, asking PartnerController to load an ad with the info of each bid.
    /// It should be only called once.
    func run(completion: @escaping (BidFulfillOperationResult) -> Void) {
        taskDispatcher.async(on: .background) { [self] in
            logger.debug("Bid fulfill operation started with load ID \(request.loadID)")
            
            // Fail early if trying to run the same operation twice.
            guard !hasRun else {
                completion(
                    BidFulfillOperationResult(
                        result: .failure(ChartboostMediationError(code: .loadFailureUnknown, description: "Fullfill operation already run")),
                        loadEvents: []
                    )
                )
                return
            }
            
            self.hasRun = true
            self.completion = completion
            fulfillNextBid()
        }
    }
    
    private func fulfillNextBid() {
        taskDispatcher.async(on: .background) { [self] in
            // If no bids left we are done and we could not fulfill
            guard !bids.isEmpty else {
                finishFulfillment(
                    with: .failure(ChartboostMediationError(
                        code: .loadFailureWaterfallExhaustedNoFill,
                        errors: loadEvents.compactMap(\.error)
                    ))
                )
                return
            }
            guard let delegate = delegate else {
                finishFulfillment(with: .failure(ChartboostMediationError(code: .loadFailureAborted, description: "Associated ad was deallocated.")))
                return
            }
            // Process the next bid
            let bid = bids.removeFirst()
            loadingBid = bid
            let start = Date()
            
            // Start timeout before asking partner to load
            timeoutTask = taskDispatcher.async(on: .background, delay: configuration.loadTimeout(for: request.adFormat)) { [weak self] in
                guard let self = self else { return }
                // If loading bid is still the same that means we were still waiting for the partner to finish loading
                if self.loadingBid?.identifier == bid.identifier {
                    logger.warning("Partner load timed out with partner \(bid.partnerIdentifier) and placement \(bid.partnerPlacement)")
                    // Make partner controller cancel the partner load operation so its completion is not called and any associated memory is freed up
                    self.cancelLoad?()
                    // Finish the processing for this bid with a timeout error
                    self.processLoadedBid(bid, result: .failure(ChartboostMediationError(code: .loadFailureTimeout)), start: start)
                }
            }
            
            // Ask the partner to load an ad for this bid
            let partnerRequest = partnerAdLoadRequest(with: bid)
            cancelLoad = partnerController.routeLoad(request: partnerRequest, viewController: viewController, delegate: delegate) { [weak self] result in
                guard let self = self else { return }
                self.taskDispatcher.async(on: .background) {
                    // If loading bid is not the same that means it has timed out and we have moved on to the next bid
                    if self.loadingBid?.identifier == bid.identifier {
                        self.processLoadedBid(bid, result: result, start: start)
                    }
                    // In case of timeout we do nothing. The ad is invalidated in the timeoutTask.
                    // We invalidate ads on the moment of timeout and not when they finish loading. This ensures that ads that never complete loading
                    // are deallocated, and prevents inconsistencies with partners that cannot load multiple ads for the same placement where a load
                    // may still be ongoing from a previous auction and we request a new ad for that same placement in a new auction.
                }
            }
        }
    }
    
    private func processLoadedBid(_ bid: Bid, result: Result<PartnerAd, ChartboostMediationError>, start: Date) {
        // Cancel timeout task
        timeoutTask?.cancel()
        loadingBid = nil
        cancelLoad = nil
        // Sanitize result, failing if a banner is provided without an inline view to show
        var sanitizedResult = result
        if request.adFormat == .banner, let ad = try? result.get(), ad.inlineView == nil {
            logger.warning("Discarding \(ad.adapter.partnerDisplayName) banner ad without an inline view")
            sanitizedResult = .failure(ChartboostMediationError(code: .loadFailureNoInlineView))
            partnerController.routeInvalidate(ad) { _ in }
        }
        // Record the load event
        loadEvents.append(loadEvent(bid: bid, start: start, error: sanitizedResult.error))
        
        // If success we are done, otherwise we call fulfill() again to process the next bid
        switch sanitizedResult {
        case .success(let partnerAd):
            finishFulfillment(with: .success((bid, partnerAd)))
        case .failure(_):
            fulfillNextBid()
        }
    }
    
    private func finishFulfillment(with result: Result<(winningBid: Bid, loadedAd: PartnerAd), ChartboostMediationError>) {
        // Complete
        if let error = result.error {
            logger.error("Bid fulfill operation failed with load ID \(request.loadID) and error: \(error)")
        } else {
            logger.debug("Bid fulfill operation succeeded with load ID \(request.loadID)")
        }
        completion?(BidFulfillOperationResult(result: result, loadEvents: loadEvents))
        // Cleanup
        completion = nil
        loadingBid = nil
        loadEvents.removeAll()
    }
}

// MARK: - Helpers

private extension PartnerControllerBidFulfillOperation {
    
    func partnerAdLoadRequest(with bid: Bid) -> PartnerAdLoadRequest {
        PartnerAdLoadRequest(
            partnerIdentifier: bid.partnerIdentifier,
            chartboostPlacement: request.heliumPlacement,
            partnerPlacement: bid.partnerPlacement,
            format: request.adFormat,
            size: request.adSize,
            adm: bid.adm,
            partnerSettings: bid.partnerDetails ?? [:],
            identifier: request.loadID,
            auctionIdentifier: bid.auctionIdentifier
        )
    }
    
    func loadEvent(bid: Bid, start: Date, error: ChartboostMediationError?) -> MetricsEvent {
        MetricsEvent(
            start: start,
            error: error,
            partnerIdentifier: bid.partnerIdentifier,
            partnerPlacement: bid.partnerPlacement,
            networkType: bid.lineItemIdentifier != nil ? .mediation : .bidding,
            lineItemIdentifier: bid.lineItemIdentifier
        )
    }
}
