// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import UIKit

/// A repository that provides ads.
protocol AdRepository: AnyObject {
    /// Fetches an ad.
    /// - parameter request: Info about the ad to load.
    /// - parameter viewController: A view controller to load the ad with. Applies to banners.
    /// - parameter delegate: The delegate object that will receive ad life-cycle events.
    /// - parameter completion: A handler to be executed when the operation finishes.
    func loadAd(
        request: InternalAdLoadRequest,
        viewController: UIViewController?,
        delegate: PartnerAdDelegate,
        completion: @escaping (InternalAdLoadResult) -> Void
    )
}

/// A repository that obtains ads through a backend-side auction where the resulting bids are locally fulfilled through partner adapters.
final class AuctionAdRepository: AdRepository {
    @Injected(\.auctionService) private var auctionService
    @Injected(\.bidFulfillOperationFactory) private var bidFulfillOperationFactory
    @Injected(\.metrics) private var metrics
    @Injected(\.backgroundTimeMonitor) private var backgroundTimeMonitor

    func loadAd(
        request: InternalAdLoadRequest,
        viewController: UIViewController?,
        delegate: PartnerAdDelegate,
        completion: @escaping (InternalAdLoadResult) -> Void
    ) {
        let backgroundMonitoringOperation = backgroundTimeMonitor.startMonitoringOperation()
        let start = Date()

        // Start backend-side auction
        auctionService.startAuction(request: request) { [weak self, backgroundMonitoringOperation] response in
            guard let self else { return }
            switch response.result {
            case .success(let bids):
                // Try to fulfill bids until we have a viable one
                // Note we keep the bid fulfill operation alive during the whole operation by capturing it in its own completion.
                let bidFulfillOperation = self.bidFulfillOperationFactory.makeBidFulfillOperation(
                    bids: bids,
                    request: request,
                    viewController: viewController,
                    delegate: delegate
                )
                bidFulfillOperation.run { [weak self, bidFulfillOperation, backgroundMonitoringOperation] result in
                    guard let self else { return }

                    // dumb statement just to explicitly capture the bidFulfillOperation in the closure capture group without warnings
                    _ = bidFulfillOperation

                    let backgroundTime = backgroundMonitoringOperation.backgroundTimeUntilNow()

                    // Log metrics
                    let rawMetrics = self.metrics.logLoad(
                        auctionID: response.auctionID ?? "",
                        loadID: request.loadID,
                        events: result.loadEvents,
                        error: result.result.error,
                        adFormat: request.adFormat,
                        size: request.adSize?.size,
                        start: start,
                        backgroundDuration: backgroundTime,
                        queueID: request.queueID
                    )
                    // in a success path, the auctionID is always available from the response header, or from the bid json content
                    assert(response.auctionID != nil)

                    // Return with a loaded ad or an error
                    switch result.result {
                    case .success((let winningBid, let partnerAd, let adSize)):
                        // Log auction complete
                        self.metrics.logAuctionCompleted(
                            with: bids,
                            winner: winningBid,
                            loadID: request.loadID,
                            adFormat: request.adFormat,
                            // The size should be the ad size returned by the adapter, not the size
                            // that was returned in the bid.
                            // Fall back to the requested size if the size returned by the adapter
                            // is nil.
                            size: adSize?.size ?? request.adSize?.size
                        )
                        // Finish successfully
                        let loadedAd = self.makeLoadedAd(
                            bids: bids,
                            winner: winningBid,
                            partnerAd: partnerAd,
                            adSize: adSize,
                            request: request
                        )
                        completion(InternalAdLoadResult(result: .success(loadedAd), metrics: rawMetrics))
                    case .failure(let error):
                        // Finish with failure
                        completion(InternalAdLoadResult(result: .failure(error), metrics: rawMetrics))
                    }
                }
            case .failure(let error):
                // Log metrics, unless the error happened before the sending of the auctions request
                // (we don't want to spam backend with these events)
                let rawMetrics: RawMetrics?
                if let auctionID = response.auctionID {
                    let backgroundTime = backgroundMonitoringOperation.backgroundTimeUntilNow()
                    rawMetrics = self.metrics.logLoad(
                        auctionID: auctionID,
                        loadID: request.loadID,
                        events: [],
                        error: error,
                        adFormat: request.adFormat,
                        size: request.adSize?.size,
                        start: start,
                        backgroundDuration: backgroundTime,
                        queueID: request.queueID
                    )
                } else {
                    rawMetrics = nil
                }

                // No bids
                completion(InternalAdLoadResult(result: .failure(error), metrics: rawMetrics))
            }
        }
    }
}

// MARK: - Helpers

extension AuctionAdRepository {
    // Mappings from bid information into `LoadedAd` and related models

    private func makeLoadedAd(
        bids: [Bid],
        winner: Bid,
        partnerAd: PartnerAd,
        adSize: BannerSize?,
        request: InternalAdLoadRequest
    ) -> LoadedAd {
        LoadedAd(
            bids: bids,
            winner: winner,
            bidInfo: makeBidInfo(bid: winner),
            partnerAd: partnerAd,
            bannerSize: adSize,
            request: request
        )
    }

    private func makeBidInfo(bid: Bid) -> [String: Any] {
        var info: [String: Any] = [:]
        info["auction_id"] = bid.auctionID
        info["partner_id"] = bid.partnerID
        info["price"] = bid.cpmPrice
        info["line_item_id"] = bid.lineItemIdentifier
        // The `line_item_name` is only present in the ILRD.
        info["line_item_name"] = bid.ilrd?["line_item_name"] as? String // explicit casting unwraps the double optional
        return info
    }
}
