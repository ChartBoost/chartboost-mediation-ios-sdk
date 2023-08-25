// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import UIKit

/// A repository that provides ads.
protocol AdRepository: AnyObject {
    /// Fetches a Helium ad.
    /// - parameter request: Info about the ad to load.
    /// - parameter viewController: A view controller to load the ad with. Applies to banners.
    /// - parameter delegate: The delegate object that will receive ad life-cycle events.
    /// - parameter completion: A handler to be executed when the operation finishes.
    func loadAd(request: HeliumAdLoadRequest, viewController: UIViewController?, delegate: PartnerAdDelegate, completion: @escaping (AdLoadResult) -> Void)
}

/// A repository that obtains ads through a backend-side auction where the resulting bids are locally fulfilled through partner adapters.
final class AuctionAdRepository: AdRepository {
    
    @Injected(\.auctionService) private var auctionService
    @Injected(\.bidFulfillOperationFactory) private var bidFulfillOperationFactory
    @Injected(\.metrics) private var metrics
    
    func loadAd(request: HeliumAdLoadRequest, viewController: UIViewController?, delegate: PartnerAdDelegate, completion: @escaping (AdLoadResult) -> Void) {
        // Start backend-side auction
        auctionService.startAuction(request: request) { [weak self] response in
            guard let self = self else { return }
            switch response.result {
            case .success(let bids):
                // Try to fulfill bids until we have a viable one
                // Note we keep the bid fulfill operation alive during the whole operation by capturing it in its own completion.
                let bidFulfillOperation = self.bidFulfillOperationFactory.makeBidFulfillOperation(bids: bids, request: request, viewController: viewController, delegate: delegate)
                bidFulfillOperation.run { [weak self, bidFulfillOperation] result in
                    guard let self = self else { return }
                    _ = bidFulfillOperation    // dumb statement just to explicitly capture the bidFulfillOperation in the closure capture group without warnings
                    
                    // Log metrics
                    let rawMetrics = self.metrics.logLoad(
                        auctionID: response.auctionID ?? "",
                        loadID: request.loadID,
                        events: result.loadEvents,
                        error: result.result.error
                    )
                    assert(response.auctionID != nil)   // in a success path, the auctionID is always available from the response header, or from the bid json content
                    
                    // Return with a Helium ad or an error
                    switch result.result {
                    case .success((let winningBid, let loadedAd)):
                        // Log auction complete
                        self.metrics.logAuctionCompleted(with: bids, winner: winningBid, loadID: request.loadID)
                        // Finish successfully
                        let heliumAd = self.makeHeliumAd(bid: winningBid, partnerAd: loadedAd, request: request)
                        completion(AdLoadResult(result: .success(heliumAd), metrics: rawMetrics))
                    case .failure(let error):
                        // Finish with failure
                        completion(AdLoadResult(result: .failure(error), metrics: rawMetrics))
                    }
                }
            case .failure(let error):
                // Log metrics, unless the error happened before the sending of the auctions request (we don't want to spam backend with these events)
                let rawMetrics: RawMetrics?
                if let auctionID = response.auctionID {
                    rawMetrics = self.metrics.logLoad(auctionID: auctionID, loadID: request.loadID, events: [], error: error)
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

private extension AuctionAdRepository {
    
    // Mappings from bid information into HeliumAd and related models
    
    func makeHeliumAd(bid: Bid, partnerAd: PartnerAd, request: HeliumAdLoadRequest) -> HeliumAd {
        HeliumAd(
            bid: bid,
            bidInfo: makeBidInfo(bid: bid),
            partnerAd: partnerAd,
            request: request
        )
    }
    
    func makeBidInfo(bid: Bid) -> [String: Any] {
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
