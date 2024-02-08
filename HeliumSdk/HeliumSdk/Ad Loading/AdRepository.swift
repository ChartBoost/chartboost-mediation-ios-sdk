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
        request: AdLoadRequest,
        viewController: UIViewController?,
        delegate: PartnerAdDelegate,
        completion: @escaping (AdLoadResult) -> Void
    )
}

/// A repository that obtains ads through a backend-side auction where the resulting bids are locally fulfilled through partner adapters.
final class AuctionAdRepository: AdRepository {
    @Injected(\.auctionService) private var auctionService
    @Injected(\.bidFulfillOperationFactory) private var bidFulfillOperationFactory
    @Injected(\.metrics) private var metrics
    @Injected(\.backgroundTimeMonitor) private var backgroundTimeMonitor

    func loadAd(
        request: AdLoadRequest,
        viewController: UIViewController?,
        delegate: PartnerAdDelegate,
        completion: @escaping (AdLoadResult) -> Void
    ) {
        let operation = backgroundTimeMonitor.startMonitoringOperation()

        // Start backend-side auction
        auctionService.startAuction(request: request) { [weak self] response in
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
                bidFulfillOperation.run { [weak self, bidFulfillOperation] result in
                    guard let self else { return }

                    let backgroundTime = operation.backgroundTimeUntilNow()

                    // dumb statement just to explicitly capture the bidFulfillOperation in the closure capture group without warnings
                    _ = bidFulfillOperation

                    // Log metrics
                    let rawMetrics = self.metrics.logLoad(
                        auctionID: response.auctionID ?? "",
                        loadID: request.loadID,
                        events: result.loadEvents,
                        error: result.result.error,
                        adFormat: request.adFormat,
                        size: request.adSize?.size,
                        backgroundDuration: backgroundTime
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
                            bid: winningBid,
                            partnerAd: partnerAd,
                            adSize: adSize,
                            request: request
                        )
                        completion(AdLoadResult(result: .success(loadedAd), metrics: rawMetrics))
                    case .failure(let error):
                        // Finish with failure
                        completion(AdLoadResult(result: .failure(error), metrics: rawMetrics))
                    }
                }
            case .failure(let error):
                // Log metrics, unless the error happened before the sending of the auctions request
                // (we don't want to spam backend with these events)
                let rawMetrics: RawMetrics?
                if let auctionID = response.auctionID {
                    let backgroundTime = operation.backgroundTimeUntilNow()
                    rawMetrics = self.metrics.logLoad(
                        auctionID: auctionID,
                        loadID: request.loadID,
                        events: [],
                        error: error,
                        adFormat: request.adFormat,
                        size: request.adSize?.size,
                        backgroundDuration: backgroundTime
                    )
                } else {
                    rawMetrics = nil
                }

                // No bids
                completion(AdLoadResult(result: .failure(error), metrics: rawMetrics))
            }
        }
    }
}

// MARK: - Helpers

extension AuctionAdRepository {
    // Mappings from bid information into `LoadedAd` and related models

    private func makeLoadedAd(
        bid: Bid,
        partnerAd: PartnerAd,
        adSize: ChartboostMediationBannerSize?,
        request: AdLoadRequest
    ) -> LoadedAd {
        LoadedAd(
            bid: bid,
            bidInfo: makeBidInfo(bid: bid),
            partnerAd: partnerAd,
            adSize: adSize,
            request: request
        )
    }

    private func makeBidInfo(bid: Bid) -> [String: Any] {
        var info: [String: Any] = [:]
        info["auction-id"] = bid.auctionIdentifier
        info["partner-id"] = bid.partnerIdentifier
        info["price"] = bid.cpmPrice
        info["line_item_id"] = bid.lineItemIdentifier
        // The `line_item_name` is only present in the ILRD.
        info["line_item_name"] = bid.ilrd?["line_item_name"] as? String // explicit casting unwraps the double optional
        return info
    }
}
