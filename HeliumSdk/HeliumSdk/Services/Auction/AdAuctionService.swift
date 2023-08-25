// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

typealias BidderInformation = [PartnerIdentifier : [String : String]]

/// The response of an ad auction.
struct AdAuctionResponse {
    let result: Result<[Bid], ChartboostMediationError>
    let auctionID: AuctionID?
}

/// A service to make ad auctions.
protocol AdAuctionService {
    /// Starts an auction obtaining a list of sorted bids.
    func startAuction(request: HeliumAdLoadRequest, completion: @escaping (AdAuctionResponse) -> Void)
}

/// A server-backed ad auction service.
final class NetworkAdAuctionService: AdAuctionService {
    
    @Injected(\.environment) private var environment
    @Injected(\.partnerController) private var partnerController
    @Injected(\.networkManager) private var networkManager
    @Injected(\.loadRateLimiter) private var loadRateLimiter
    
    /// Starts an auction obtaining a list of sorted bids from our server.
    func startAuction(request: HeliumAdLoadRequest, completion: @escaping (AdAuctionResponse) -> Void) {
        // Fail immediately if the load should be rate limited
        if environment.testMode.isRateLimitingEnabled {
            let timeUntilNextLoadIsAllowed = loadRateLimiter.timeUntilNextLoadIsAllowed(placement: request.heliumPlacement)
            guard timeUntilNextLoadIsAllowed <= 0 else {
                let error = ChartboostMediationError(
                    code: .loadFailureRateLimited,
                    description: "\(request.heliumPlacement) has been rate limited. Please try again in \(String(format: "%.03f", timeUntilNextLoadIsAllowed)) seconds."
                )
                logger.error("Failed to start auction with error: \(error)")
                completion(
                    AdAuctionResponse(
                        result: .failure(error),
                        auctionID: nil
                    )
                )
                return
            }
        }
        
        // Fetch bidder tokens and partner info to attach to the bid request
        let preBidRequest = PreBidRequest(
            chartboostPlacement: request.heliumPlacement,
            format: request.adFormat,
            loadID: request.loadID
        )
        partnerController.routeFetchBidderInformation(request: preBidRequest) { [weak self] bidderTokens in
            self?.requestBid(loadRequest: request, bidderTokens: bidderTokens, completion: completion)
        }
    }
    
    private func requestBid(loadRequest: HeliumAdLoadRequest, bidderTokens: BidderTokens, completion: @escaping (AdAuctionResponse) -> Void) {
        let auctionsRequest = AuctionsHTTPRequest(
            bidRequest: makeBidRequest(request: loadRequest, bidderTokens: bidderTokens),
            loadRateLimit: Int(loadRateLimiter.loadRateLimit(placement: loadRequest.heliumPlacement)),
            loadID: loadRequest.loadID
        )
        logger.debug("Sending auction request")
        networkManager.send(auctionsRequest) { [weak self] result in
            switch result {
            case .success(let response):
                if let newLoadRateLimit = response.httpURLResponse.rateLimitReset {
                    self?.loadRateLimiter.setLoadRateLimit(TimeInterval(newLoadRateLimit), placement: loadRequest.heliumPlacement)
                }
                logger.debug("Auction request succeeded")
                completion(response.asAdAuctionResponse(placement: loadRequest.heliumPlacement))

            case .failure(let requestError):
                logger.error("Auction request failed with error: \(requestError)")
                completion(requestError.asAdAuctionResponse)
            }
        }
    }
}

// MARK: - Helpers

private extension NetworkAdAuctionService {

    func makeBidRequest(request: HeliumAdLoadRequest, bidderTokens: BidderTokens) -> OpenRTB.BidRequest {
        let bidderInformation = makeBiddersInformation(tokens: bidderTokens, adaptersInfo: partnerController.initializedAdapterInfo)
        let bidRequest = OpenRTB.BidRequest.make(request: request, bidderInformation: bidderInformation)
        return bidRequest
    }
    
    /// Returns a dictionary merging both standard adapter info and partner-specific info (bidding tokens and other custom bidding-related info)
    func makeBiddersInformation(tokens: BidderTokens, adaptersInfo: [PartnerIdentifier: PartnerAdapterInfo]) -> BidderInformation {
        var biddersInfo = tokens
        for (key, info) in adaptersInfo {
            biddersInfo[key] = biddersInfo[key, default: [:]].merging(dictionary(from: info), uniquingKeysWith: { first, _ in first })
        }
        return biddersInfo
    }
    
    func dictionary(from partnerInfo: PartnerAdapterInfo) -> [String: String] {
        ["version": partnerInfo.partnerVersion,
         "adapter_version": partnerInfo.adapterVersion]
    }
}

extension NetworkManager.RequestError {
    
    private var asCMErrorCode: ChartboostMediationError.Code {
        switch self {
        case .sdkNotInitialized:
            return .loadFailureChartboostMediationNotInitialized

        case .dataTaskError:
            return .loadFailureNetworkingError
            
        case .jsonDecodeError:
            return .loadFailureInvalidBidResponse
            
        case .nilNetworkManagerBeforeSendError,
             .urlRequestCreationError,
             .notHTTPURLResponseError,
             .responseStatusCodeOutOfRangeError,
             .responseWithEmptyDataError,
             .nilNetworkManagerBeforeRetryError:
            return .loadFailureException
        }
    }
    
    private var originalError: Error? {
        switch self {
        case .urlRequestCreationError( _, let originalError),
             .jsonDecodeError(_, _, _, let originalError),
             .dataTaskError(_, _, let originalError):
            return originalError
        case .nilNetworkManagerBeforeSendError,
             .sdkNotInitialized,
             .notHTTPURLResponseError,
             .responseStatusCodeOutOfRangeError,
             .responseWithEmptyDataError,
             .nilNetworkManagerBeforeRetryError:
            return nil
        }
    }
    
    fileprivate var asAdAuctionResponse: AdAuctionResponse {
        let rawData: Data?
        if case .jsonDecodeError(_, _, let data, _) = self {
            rawData = data
        } else {
            rawData = nil
        }
        let cmError = ChartboostMediationError(
            code: asCMErrorCode,
            description: localizedDescription,
            error: originalError,
            data: rawData
        )
        let auctionID = httpURLResponse?.allHeaderFields[HTTP.HeaderKey.auctionID.rawValue] as? String
        return AdAuctionResponse(result: .failure(cmError), auctionID: auctionID)
    }
}

extension NetworkManager.JSONResponse where T == OpenRTB.BidResponse {
    fileprivate func asAdAuctionResponse(placement: String) -> AdAuctionResponse {
        switch httpURLResponse.statusCode {
        case 200:
            guard let responseData = responseData else {
                return AdAuctionResponse(
                    result: .failure(ChartboostMediationError(
                        code: .loadFailureInvalidBidResponse,
                        data: responseData?.rawData)
                    ),
                    auctionID: httpURLResponse.auctionID
                )
            }

            let bids = Bid.makeBids(response: responseData.decodedData, placement: placement)
            guard !bids.isEmpty else {
                return AdAuctionResponse(
                    result: .failure(ChartboostMediationError(
                        code: .loadFailureInvalidBidResponse,
                        data: responseData.rawData)
                    ),
                    auctionID: httpURLResponse.auctionID
                )
            }
            return AdAuctionResponse(
                result: .success(bids),
                auctionID: httpURLResponse.auctionID ?? bids.first?.auctionIdentifier // all bids should have the same auction identifier
            )

        case 204:
            return AdAuctionResponse(
                result: .failure(ChartboostMediationError(code: .loadFailureAuctionNoBid)),
                auctionID: httpURLResponse.auctionID
            )

        default:
            return AdAuctionResponse(
                result: .failure(ChartboostMediationError(code: .loadFailureInvalidBidResponse)),
                auctionID: httpURLResponse.auctionID
            )
        }
    }
}

extension HTTPURLResponse {
    fileprivate var auctionID: AuctionID? {
        allHeaderFields[HTTP.HeaderKey.auctionID.rawValue] as? AuctionID
    }

    fileprivate var rateLimitReset: Int? {
        guard
            let stringValue = allHeaderFields[HTTP.HeaderKey.rateLimitReset.rawValue] as? String,
            let intValue = Int(stringValue)
        else {
            return nil
        }
        return intValue
    }
}
