// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

typealias BidderInformation = [PartnerIdentifier: [String: String]]

/// The response of an ad auction.
struct AdAuctionResponse {
    let result: Result<[Bid], ChartboostMediationError>
    let auctionID: AuctionID?
}

/// A service to make ad auctions.
protocol AdAuctionService {
    /// Starts an auction obtaining a list of sorted bids.
    func startAuction(request: AdLoadRequest, completion: @escaping (AdAuctionResponse) -> Void)
}

/// A server-backed ad auction service.
final class NetworkAdAuctionService: AdAuctionService {
    @Injected(\.auctionRequestFactory) private var auctionRequestFactory
    @Injected(\.environment) private var environment
    @Injected(\.partnerController) private var partnerController
    @Injected(\.networkManager) private var networkManager
    @Injected(\.loadRateLimiter) private var loadRateLimiter

    /// Starts an auction obtaining a list of sorted bids from our server.
    func startAuction(request: AdLoadRequest, completion: @escaping (AdAuctionResponse) -> Void) {
        // Fail immediately if the load should be rate limited
        if environment.testMode.isRateLimitingEnabled {
            let timeUntilNextLoadIsAllowed = loadRateLimiter.timeUntilNextLoadIsAllowed(placement: request.mediationPlacement)
            guard timeUntilNextLoadIsAllowed <= 0 else {
                let error = ChartboostMediationError(
                    code: .loadFailureRateLimited,
                    description: "\(request.mediationPlacement) has been rate limited. Please try again in \(String(format: "%.03f", timeUntilNextLoadIsAllowed)) seconds."
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
            chartboostPlacement: request.mediationPlacement,
            format: request.adFormat,
            loadID: request.loadID
        )
        partnerController.routeFetchBidderInformation(request: preBidRequest) { [weak self] bidderTokens in
            self?.requestBid(loadRequest: request, bidderTokens: bidderTokens, completion: completion)
        }
    }

    private func requestBid(loadRequest: AdLoadRequest, bidderTokens: BidderTokens, completion: @escaping (AdAuctionResponse) -> Void) {
        logger.debug("Sending auction request")

        // Generate HTTP request
        makeAuctionRequest(
            request: loadRequest,
            bidderTokens: bidderTokens
        ) { [weak self] auctionRequest in
            guard let self else { return }

            // Send HTTP request
            self.networkManager.send(auctionRequest) { [weak self] result in
                // Parse HTTP response
                switch result {
                case .success(let response):
                    if let newLoadRateLimit = response.httpURLResponse.rateLimitReset {
                        self?.loadRateLimiter.setLoadRateLimit(TimeInterval(newLoadRateLimit), placement: loadRequest.mediationPlacement)
                    }
                    logger.debug("Auction request succeeded")
                    completion(response.asAdAuctionResponse(request: loadRequest))

                case .failure(let requestError):
                    logger.error("Auction request failed with error: \(requestError)")
                    completion(requestError.asAdAuctionResponse)
                }
            }
        }
    }
}

// MARK: - Helpers

extension NetworkAdAuctionService {
    private func makeAuctionRequest(
        request: AdLoadRequest,
        bidderTokens: BidderTokens,
        completion: @escaping (AuctionsHTTPRequest) -> Void
    ) {
        let bidderInformation = makeBiddersInformation(
            tokens: bidderTokens,
            adaptersInfo: partnerController.initializedAdapterInfo
        )
        auctionRequestFactory.makeRequest(
            request: request,
            loadRateLimit: loadRateLimiter.loadRateLimit(placement: request.mediationPlacement),
            bidderInformation: bidderInformation,
            completion: completion
        )
    }

    /// Returns a dictionary merging both standard adapter info and partner-specific info (bidding tokens and other custom bidding-related
    /// info)
    private func makeBiddersInformation(tokens: BidderTokens, adaptersInfo: [PartnerIdentifier: PartnerAdapterInfo]) -> BidderInformation {
        var biddersInfo = tokens
        for (key, info) in adaptersInfo {
            biddersInfo[key] = biddersInfo[key, default: [:]].merging(dictionary(from: info), uniquingKeysWith: { first, _ in first })
        }
        return biddersInfo
    }

    private func dictionary(from partnerInfo: PartnerAdapterInfo) -> [String: String] {
        [
            "version": partnerInfo.partnerVersion,
            "adapter_version": partnerInfo.adapterVersion,
        ]
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
    fileprivate func asAdAuctionResponse(request: AdLoadRequest) -> AdAuctionResponse {
        switch httpURLResponse.statusCode {
        case 200:
            guard let responseData else {
                return AdAuctionResponse(
                    result: .failure(
                        ChartboostMediationError(
                            code: .loadFailureInvalidBidResponse,
                            data: responseData?.rawData
                        )
                    ),
                    auctionID: httpURLResponse.auctionID
                )
            }

            let bids = Bid.makeBids(response: responseData.decodedData, request: request)
            guard !bids.isEmpty else {
                return AdAuctionResponse(
                    result: .failure(
                        ChartboostMediationError(
                            code: .loadFailureInvalidBidResponse,
                            data: responseData.rawData
                        )
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
