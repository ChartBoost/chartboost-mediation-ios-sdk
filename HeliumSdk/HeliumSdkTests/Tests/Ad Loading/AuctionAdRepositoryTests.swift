// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class AuctionAdRepositoryTests: ChartboostMediationTestCase {
    
    lazy var adRepository = AuctionAdRepository()
    
    let loadID = "some load ID"
    
    /// Validates that loadAd() fails if the AuctionService completes with a failure
    func testLoadAdFailsIfAuctionServiceFails() {
        let request = AdLoadRequest.test()
        let viewController = UIViewController()
        let delegate = PartnerAdDelegateMock()
        let expectedError = ChartboostMediationError(code: .loadFailureAuctionNoBid)
        
        // Load ad
        var completed = false
        adRepository.loadAd(request: request, viewController: viewController, delegate: delegate) { result in
            if case .failure(let error) = result.result {
                XCTAssertEqual(error, expectedError)
            } else {
                XCTFail("Received unexpected successful result")
            }
            XCTAssertNil(result.metrics)
            completed = true
        }
        
        // Check we have not finished yet and AuctionService has been called
        XCTAssertFalse(completed)
        var auctionCompletion: (AdAuctionResponse) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.auctionService, .startAuction, parameters: [request, XCTMethodCaptureParameter { auctionCompletion = $0 }])
        
        // Make auction complete
        auctionCompletion(AdAuctionResponse(result: .failure(expectedError), auctionID: nil))
        
        // Check that we have finished with failure
        XCTAssertTrue(completed)
        
        // Check no metrics were logged
        XCTAssertNoMethodCalls(mocks.metrics)
    }
    
    /// Validates that loadAd() logs load metrics if the auction service fails but provides an auctionID, which means the error happened after the auctions request was sent
    func testLoadMetricsAreLoggedIfAuctionServiceFailsButAnAuctionIDIsAvailable() {
        let testStartedOn = Date()
        let request = AdLoadRequest.test()
        let viewController = UIViewController()
        let delegate = PartnerAdDelegateMock()
        let expectedError = ChartboostMediationError(code: .loadFailureAuctionNoBid)
        let expectedAuctionID = "some auction ID"
        let expectedMetrics: [String: Any] = ["hello": "123", "hi": 4321]
        mocks.metrics.setReturnValue(expectedMetrics, for: .logLoad)
        
        // Load ad
        var completed = false
        adRepository.loadAd(request: request, viewController: viewController, delegate: delegate) { result in
            XCTAssertAnyEqual(result.metrics, expectedMetrics)
            completed = true
        }
        
        // Make auction complete
        var auctionCompletion: (AdAuctionResponse) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.auctionService, .startAuction, parameters: [request, XCTMethodCaptureParameter { auctionCompletion = $0 }])
        auctionCompletion(AdAuctionResponse(result: .failure(expectedError), auctionID: expectedAuctionID))
                
        // Check metrics are logged, with the auctionID and error returned by the service
        XCTAssertMethodCalls(mocks.metrics, .logLoad, parameters: [
            expectedAuctionID,
            request.loadID,
            [MetricsEvent](),
            expectedError,
            request.adFormat,
            request.adSize?.size,
            XCTMethodSomeParameter<Date> {
                XCTAssertTrue($0 > testStartedOn)
                XCTAssertTrue($0 < Date())
            },
            XCTMethodSomeParameter<Date> {
                XCTAssertTrue($0 > testStartedOn)
                XCTAssertTrue($0 > self.mocks.metrics.recordedParameters[0][6] as! Date)
                XCTAssertTrue($0 < Date())
            },
            0.0
        ])
        
        // Check that we have finished with failure
        XCTAssertTrue(completed)
    }
    
    /// Validates that loadAd() fails if the BidFulfiller completes with a failure
    func testLoadAdFailsIfBidFulfillerFails() {
        let testStartedOn = Date()
        let request = AdLoadRequest.test(loadID: loadID)
        let viewController = UIViewController()
        let delegate = PartnerAdDelegateMock()
        let bids = [Bid.makeMock(), Bid.makeMock(), Bid.makeMock()]
        let expectedError = ChartboostMediationError(code: .loadFailureUnknown)
        let expectedResult = AdLoadResult(
            result: .failure(ChartboostMediationError(code: .loadFailureUnknown)),
            metrics: ["hello": 23, "babab": "asdasfd"]
        )
        let expectedAuctionID = "some auction ID"
        let expectedLoadEvents = [MetricsEvent.test(), MetricsEvent.test(), MetricsEvent.test(), MetricsEvent.test()]
        mocks.metrics.setReturnValue(expectedResult.metrics, for: .logLoad)
        
        // Load ad
        var completed = false
        adRepository.loadAd(request: request, viewController: viewController, delegate: delegate) { result in
            // Check the result is as expected and metrics correspond to those obtained from the metrics logger
            XCTAssertAnyEqual(result, expectedResult)
            completed = true
        }
        
        // Check we have not finished yet and AuctionService has been called
        XCTAssertFalse(completed)
        var auctionCompletion: (AdAuctionResponse) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.auctionService, .startAuction, parameters: [request, XCTMethodCaptureParameter { auctionCompletion = $0 }])
        
        // Make auction complete with success
        auctionCompletion(AdAuctionResponse(result: .success(bids), auctionID: expectedAuctionID))
        
        // Check we have not finished yet and the BidFulfillOperation has started
        XCTAssertFalse(completed)
        var fulfillCompletion: ((BidFulfillOperationResult) -> Void) = { _ in }
        XCTAssertMethodCalls(mocks.bidFulfillOperationFactory, .makeBidFulfillOperation, parameters: [bids, request, viewController, delegate])
        let fulfillOperation = mocks.bidFulfillOperationFactory.returnValue(for: .makeBidFulfillOperation) as BidFulfillOperationMock
        XCTAssertMethodCalls(fulfillOperation, .run, parameters: [XCTMethodCaptureParameter { fulfillCompletion = $0 }])
        
        // Make fulfill complete with failure
        fulfillCompletion(BidFulfillOperationResult(result: .failure(expectedError), loadEvents: expectedLoadEvents))
        
        // Check that we have finished with failure
        XCTAssertTrue(completed)
        
        // Check metrics are logged, including the error returned by the bid fulfill operation
        XCTAssertMethodCalls(mocks.metrics, .logLoad, parameters: [
            expectedAuctionID,
            loadID,
            XCTMethodSomeParameter<[MetricsEvent]> {
                self.assertEqual($0, expectedLoadEvents)
            },
            expectedError,
            request.adFormat,
            request.adSize?.size,
            XCTMethodSomeParameter<Date> {
                XCTAssertTrue($0 > testStartedOn)
                XCTAssertTrue($0 < Date())
            },
            XCTMethodSomeParameter<Date> {
                XCTAssertTrue($0 > testStartedOn)
                XCTAssertTrue($0 > self.mocks.metrics.recordedParameters[0][6] as! Date)
                XCTAssertTrue($0 < Date())
            },
            0.0
        ])
    }
    
    /// Validates that loadAd() succeeds if the BidFulfiller completes successfully
    func testLoadAdSucceedsIfBidFulfillerSucceeds() {
        let testStartedOn = Date()
        let request = AdLoadRequest.test(loadID: loadID)
        let viewController = UIViewController()
        let delegate = PartnerAdDelegateMock()
        let bids = [
            Bid.makeMock(),
            Bid.makeMock(rewardedCallbackData: .init(url: "https://winning.bid"), lineItemName: "some line item name"),
            Bid.makeMock()
        ]
        let winningBid = bids[1]
        let partnerAd = PartnerAdMock()
        let expectedLoadEvents = [MetricsEvent.test()]
        let expectedAuctionID = "some auction ID"
        let expectedRawMetrics: [String: Any] = ["hello": 23, "babab": "asdasfd"]
        mocks.metrics.setReturnValue(expectedRawMetrics, for: .logLoad)
        
        // Load ad
        var completed = false
        adRepository.loadAd(request: request, viewController: viewController, delegate: delegate) { result in
            // Check that the returned ad is valid according to the input data
            if case .success(let ad) = result.result {
                XCTAssertJSONEqual(ad.ilrd, winningBid.ilrd)
                XCTAssertAnyEqual(ad.bidInfo, [
                    LoadedAd.auctionIDKey: winningBid.auctionIdentifier,
                    LoadedAd.partnerIDKey: winningBid.partnerIdentifier,
                    LoadedAd.priceKey: winningBid.cpmPrice ?? 0,
                    LoadedAd.lineItemIDKey: winningBid.lineItemIdentifier ?? "",
                    LoadedAd.lineItemNameKey: "some line item name"
                ] as [String: Any])
                XCTAssertEqual(ad.rewardedCallback?.adRevenue, winningBid.adRevenue)
                XCTAssertEqual(ad.rewardedCallback?.cpmPrice, winningBid.cpmPrice)
                XCTAssertEqual(ad.rewardedCallback?.partnerIdentifier, winningBid.partnerIdentifier)
                XCTAssertAnyEqual(ad.rewardedCallback, winningBid.rewardedCallback)
                self.assertEqual(ad.partnerAd, partnerAd)
                XCTAssertEqual(ad.request, request)
            } else {
                XCTFail("Received unexpected failed result")
            }
            // Check the returned metrics correspond to those obtained from the metrics logger
            XCTAssertAnyEqual(result.metrics, expectedRawMetrics)
            completed = true
        }
        
        // Check we have not finished yet and AuctionService has been called
        XCTAssertFalse(completed)
        var auctionCompletion: (AdAuctionResponse) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.auctionService, .startAuction, parameters: [request, XCTMethodCaptureParameter { auctionCompletion = $0 }])
        
        // Make auction complete with success
        auctionCompletion(AdAuctionResponse(result: .success(bids), auctionID: expectedAuctionID))
        
        // Check we have not finished yet and BidFulfiller has been called
        XCTAssertFalse(completed)
        var fulfillCompletion: ((BidFulfillOperationResult) -> Void) = { _ in }
        XCTAssertMethodCalls(mocks.bidFulfillOperationFactory, .makeBidFulfillOperation, parameters: [bids, request, viewController, delegate])
        let fulfillOperation = mocks.bidFulfillOperationFactory.returnValue(for: .makeBidFulfillOperation) as BidFulfillOperationMock
        XCTAssertMethodCalls(fulfillOperation, .run, parameters: [XCTMethodCaptureParameter { fulfillCompletion = $0 }])
        
        // Make fulfill complete successfully
        fulfillCompletion(BidFulfillOperationResult(result: .success((winningBid, partnerAd, nil)), loadEvents: expectedLoadEvents))
        
        // Check that we have finished with success
        XCTAssertTrue(completed)
        
        // Check metrics are logged
        XCTAssertMethodCalls(mocks.metrics, .logLoad, .logAuctionCompleted, parameters:
            [
                expectedAuctionID,
                loadID,
                XCTMethodSomeParameter<[MetricsEvent]> {
                    self.assertEqual($0, expectedLoadEvents)
                },
                nil,
                request.adFormat,
                request.adSize?.size,
                XCTMethodSomeParameter<Date> {
                    XCTAssertTrue($0 > testStartedOn)
                    XCTAssertTrue($0 < Date())
                },
                XCTMethodSomeParameter<Date> {
                    XCTAssertTrue($0 > testStartedOn)
                    XCTAssertTrue($0 > self.mocks.metrics.recordedParameters[0][6] as! Date)
                    XCTAssertTrue($0 < Date())
                },
                0.0
            ], [
                bids,
                winningBid,
                loadID,
                request.adFormat,
                XCTMethodIgnoredParameter()
            ]
        )
    }

    func testSendsCorrectSizeInLogAuctionCompleted() {
        let testStartedOn = Date()
        let request = AdLoadRequest.test(loadID: loadID)
        let viewController = UIViewController()
        let delegate = PartnerAdDelegateMock()
        let bids = [
            Bid.makeMock()
        ]
        let winningBid = bids[0]
        let partnerAd = PartnerAdMock()
        let expectedLoadEvents = [MetricsEvent.test()]
        let expectedAuctionID = "some auction ID"
        let expectedRawMetrics: [String: Any] = ["hello": 23, "babab": "asdasfd"]
        mocks.metrics.setReturnValue(expectedRawMetrics, for: .logLoad)

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        adRepository.loadAd(request: request, viewController: viewController, delegate: delegate) { result in
            loadExpectation.fulfill()
        }

        var auctionCompletion: (AdAuctionResponse) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.auctionService, .startAuction, parameters: [request, XCTMethodCaptureParameter { auctionCompletion = $0 }])

        // Make auction complete with success
        auctionCompletion(AdAuctionResponse(result: .success(bids), auctionID: expectedAuctionID))

        var fulfillCompletion: ((BidFulfillOperationResult) -> Void) = { _ in }
        XCTAssertMethodCalls(mocks.bidFulfillOperationFactory, .makeBidFulfillOperation, parameters: [bids, request, viewController, delegate])
        let fulfillOperation = mocks.bidFulfillOperationFactory.returnValue(for: .makeBidFulfillOperation) as BidFulfillOperationMock
        XCTAssertMethodCalls(fulfillOperation, .run, parameters: [XCTMethodCaptureParameter { fulfillCompletion = $0 }])

        // Make fulfill complete successfully
        // The expected size should be sent in the `logAuctionCompleted` call.
        let expectedSize = CGSize(width: 400.0, height: 100.0)
        let size = ChartboostMediationBannerSize(size: expectedSize, type: .adaptive)
        fulfillCompletion(BidFulfillOperationResult(result: .success((winningBid, partnerAd, size)), loadEvents: expectedLoadEvents))

        waitForExpectations(timeout: 1.0)

        // Check metrics are logged
        XCTAssertMethodCalls(mocks.metrics, .logLoad, .logAuctionCompleted, parameters:
            [
                expectedAuctionID,
                loadID,
                XCTMethodSomeParameter<[MetricsEvent]> {
                    self.assertEqual($0, expectedLoadEvents)
                },
                nil,
                request.adFormat,
                request.adSize?.size,
                XCTMethodSomeParameter<Date> {
                    XCTAssertTrue($0 > testStartedOn)
                    XCTAssertTrue($0 < Date())
                },
                XCTMethodSomeParameter<Date> {
                    XCTAssertTrue($0 > testStartedOn)
                    XCTAssertTrue($0 > self.mocks.metrics.recordedParameters[0][6] as! Date)
                    XCTAssertTrue($0 < Date())
                },
                0.0
            ], [
                bids,
                winningBid,
                loadID,
                request.adFormat,
                expectedSize
            ]
        )
    }

    func testFallsBackToRequestedSizeIfSizeReturnedByAdapterIsNilInLogAuctionCompleted() {
        let testStartedOn = Date()
        let expectedSize = CGSize(width: 400.0, height: 100.0)
        let size = ChartboostMediationBannerSize(size: expectedSize, type: .adaptive)
        let request = AdLoadRequest.test(adSize: size, loadID: loadID)
        let viewController = UIViewController()
        let delegate = PartnerAdDelegateMock()
        let bids = [
            Bid.makeMock()
        ]
        let winningBid = bids[0]
        let partnerAd = PartnerAdMock()
        let expectedLoadEvents = [MetricsEvent.test()]
        let expectedAuctionID = "some auction ID"
        let expectedRawMetrics: [String: Any] = ["hello": 23, "babab": "asdasfd"]
        mocks.metrics.setReturnValue(expectedRawMetrics, for: .logLoad)

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        adRepository.loadAd(request: request, viewController: viewController, delegate: delegate) { result in
            loadExpectation.fulfill()
        }

        var auctionCompletion: (AdAuctionResponse) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.auctionService, .startAuction, parameters: [request, XCTMethodCaptureParameter { auctionCompletion = $0 }])

        // Make auction complete with success
        auctionCompletion(AdAuctionResponse(result: .success(bids), auctionID: expectedAuctionID))

        var fulfillCompletion: ((BidFulfillOperationResult) -> Void) = { _ in }
        XCTAssertMethodCalls(mocks.bidFulfillOperationFactory, .makeBidFulfillOperation, parameters: [bids, request, viewController, delegate])
        let fulfillOperation = mocks.bidFulfillOperationFactory.returnValue(for: .makeBidFulfillOperation) as BidFulfillOperationMock
        XCTAssertMethodCalls(fulfillOperation, .run, parameters: [XCTMethodCaptureParameter { fulfillCompletion = $0 }])

        // Make fulfill complete successfully
        fulfillCompletion(BidFulfillOperationResult(result: .success((winningBid, partnerAd, nil)), loadEvents: expectedLoadEvents))

        waitForExpectations(timeout: 1.0)

        // Check metrics are logged
        XCTAssertMethodCalls(mocks.metrics, .logLoad, .logAuctionCompleted, parameters:
            [
                expectedAuctionID,
                loadID,
                XCTMethodSomeParameter<[MetricsEvent]> {
                    self.assertEqual($0, expectedLoadEvents)
                },
                nil,
                request.adFormat,
                request.adSize?.size,
                XCTMethodSomeParameter<Date> {
                    XCTAssertTrue($0 > testStartedOn)
                    XCTAssertTrue($0 < Date())
                },
                XCTMethodSomeParameter<Date> {
                    XCTAssertTrue($0 > testStartedOn)
                    XCTAssertTrue($0 > self.mocks.metrics.recordedParameters[0][6] as! Date)
                    XCTAssertTrue($0 < Date())
                },
                0.0
            ], [
                bids,
                winningBid,
                loadID,
                request.adFormat,
                expectedSize
            ]
        )
    }

    func testSendsNilIfRequestedSizeisNilInLogAuctionCompleted() {
        let testStartedOn = Date()
        let request = AdLoadRequest.test(adSize: nil, loadID: loadID)
        let viewController = UIViewController()
        let delegate = PartnerAdDelegateMock()
        let bids = [
            Bid.makeMock()
        ]
        let winningBid = bids[0]
        let partnerAd = PartnerAdMock()
        let expectedLoadEvents = [MetricsEvent.test()]
        let expectedAuctionID = "some auction ID"
        let expectedRawMetrics: [String: Any] = ["hello": 23, "babab": "asdasfd"]
        mocks.metrics.setReturnValue(expectedRawMetrics, for: .logLoad)

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        adRepository.loadAd(request: request, viewController: viewController, delegate: delegate) { result in
            loadExpectation.fulfill()
        }

        var auctionCompletion: (AdAuctionResponse) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.auctionService, .startAuction, parameters: [request, XCTMethodCaptureParameter { auctionCompletion = $0 }])

        // Make auction complete with success
        auctionCompletion(AdAuctionResponse(result: .success(bids), auctionID: expectedAuctionID))

        var fulfillCompletion: ((BidFulfillOperationResult) -> Void) = { _ in }
        XCTAssertMethodCalls(mocks.bidFulfillOperationFactory, .makeBidFulfillOperation, parameters: [bids, request, viewController, delegate])
        let fulfillOperation = mocks.bidFulfillOperationFactory.returnValue(for: .makeBidFulfillOperation) as BidFulfillOperationMock
        XCTAssertMethodCalls(fulfillOperation, .run, parameters: [XCTMethodCaptureParameter { fulfillCompletion = $0 }])

        // Make fulfill complete successfully
        fulfillCompletion(BidFulfillOperationResult(result: .success((winningBid, partnerAd, nil)), loadEvents: expectedLoadEvents))

        waitForExpectations(timeout: 1.0)

        // Check metrics are logged
        XCTAssertMethodCalls(mocks.metrics, .logLoad, .logAuctionCompleted, parameters:
            [
                expectedAuctionID,
                loadID,
                XCTMethodSomeParameter<[MetricsEvent]> {
                    self.assertEqual($0, expectedLoadEvents)
                },
                nil,
                request.adFormat,
                request.adSize?.size,
                XCTMethodSomeParameter<Date> {
                    XCTAssertTrue($0 > testStartedOn)
                    XCTAssertTrue($0 < Date())
                },
                XCTMethodSomeParameter<Date> {
                    XCTAssertTrue($0 > testStartedOn)
                    XCTAssertTrue($0 > self.mocks.metrics.recordedParameters[0][6] as! Date)
                    XCTAssertTrue($0 < Date())
                },
                0.0
            ], [
                bids,
                winningBid,
                loadID,
                request.adFormat,
                nil
            ]
        )
    }

    // MARK: - Background Duration

    func testLoadAdSuccessWithBackgroundDuration() {
        let testStartedOn = Date()
        let request = AdLoadRequest.test(loadID: loadID)
        let viewController = UIViewController()
        let delegate = PartnerAdDelegateMock()
        let bids = [
            Bid.makeMock(),
            Bid.makeMock(rewardedCallbackData: .init(url: "https://winning.bid"), lineItemName: "some line item name"),
            Bid.makeMock()
        ]
        let backgroundDuration = TimeInterval.random(in: 0.1...3.0)
        mocks.backgroundTimeMonitor.backgroundTime = backgroundDuration
        let winningBid = bids[1]
        let partnerAd = PartnerAdMock()
        let expectedLoadEvents = [MetricsEvent.test()]
        let expectedAuctionID = "some auction ID"
        let expectedRawMetrics: [String: Any] = ["hello": 23, "babab": "asdasfd"]
        mocks.metrics.setReturnValue(expectedRawMetrics, for: .logLoad)

        // Load ad
        var completed = false
        adRepository.loadAd(request: request, viewController: viewController, delegate: delegate) { result in
            // Check that the returned ad is valid according to the input data
            if case .success(let ad) = result.result {
                XCTAssertJSONEqual(ad.ilrd, winningBid.ilrd)
                XCTAssertAnyEqual(ad.bidInfo, [
                    LoadedAd.auctionIDKey: winningBid.auctionIdentifier,
                    LoadedAd.partnerIDKey: winningBid.partnerIdentifier,
                    LoadedAd.priceKey: winningBid.cpmPrice ?? 0,
                    LoadedAd.lineItemIDKey: winningBid.lineItemIdentifier ?? "",
                    LoadedAd.lineItemNameKey: "some line item name"
                ] as [String: Any])
                XCTAssertEqual(ad.rewardedCallback?.adRevenue, winningBid.adRevenue)
                XCTAssertEqual(ad.rewardedCallback?.cpmPrice, winningBid.cpmPrice)
                XCTAssertEqual(ad.rewardedCallback?.partnerIdentifier, winningBid.partnerIdentifier)
                XCTAssertAnyEqual(ad.rewardedCallback, winningBid.rewardedCallback)
                self.assertEqual(ad.partnerAd, partnerAd)
                XCTAssertEqual(ad.request, request)
            } else {
                XCTFail("Received unexpected failed result")
            }
            // Check the returned metrics correspond to those obtained from the metrics logger
            XCTAssertAnyEqual(result.metrics, expectedRawMetrics)
            completed = true
        }

        // Check we have not finished yet and AuctionService has been called
        XCTAssertFalse(completed)
        var auctionCompletion: (AdAuctionResponse) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.auctionService, .startAuction, parameters: [request, XCTMethodCaptureParameter { auctionCompletion = $0 }])

        // Make auction complete with success
        auctionCompletion(AdAuctionResponse(result: .success(bids), auctionID: expectedAuctionID))

        // Check we have not finished yet and BidFulfiller has been called
        XCTAssertFalse(completed)
        var fulfillCompletion: ((BidFulfillOperationResult) -> Void) = { _ in }
        XCTAssertMethodCalls(mocks.bidFulfillOperationFactory, .makeBidFulfillOperation, parameters: [bids, request, viewController, delegate])
        let fulfillOperation = mocks.bidFulfillOperationFactory.returnValue(for: .makeBidFulfillOperation) as BidFulfillOperationMock
        XCTAssertMethodCalls(fulfillOperation, .run, parameters: [XCTMethodCaptureParameter { fulfillCompletion = $0 }])

        // Make fulfill complete successfully
        fulfillCompletion(BidFulfillOperationResult(result: .success((winningBid, partnerAd, nil)), loadEvents: expectedLoadEvents))

        // Check that we have finished with success
        XCTAssertTrue(completed)

        // Check metrics are logged
        XCTAssertMethodCalls(mocks.metrics, .logLoad, .logAuctionCompleted, parameters:
            [
                expectedAuctionID,
                loadID,
                XCTMethodSomeParameter<[MetricsEvent]> {
                    self.assertEqual($0, expectedLoadEvents)
                },
                nil,
                request.adFormat,
                request.adSize?.size,
                XCTMethodSomeParameter<Date> {
                    XCTAssertTrue($0 > testStartedOn)
                    XCTAssertTrue($0 < Date())
                },
                XCTMethodSomeParameter<Date> {
                    XCTAssertTrue($0 > testStartedOn)
                    XCTAssertTrue($0 > self.mocks.metrics.recordedParameters[0][6] as! Date)
                    XCTAssertTrue($0 < Date())
                },
                backgroundDuration
            ], [
                bids,
                winningBid,
                loadID,
                request.adFormat,
                XCTMethodIgnoredParameter()
            ]
        )
    }

    func testLoadAdFailsWithBackgroundDuration() {
        let testStartedOn = Date()
        let request = AdLoadRequest.test(loadID: loadID)
        let viewController = UIViewController()
        let delegate = PartnerAdDelegateMock()
        let bids = [Bid.makeMock(), Bid.makeMock(), Bid.makeMock()]
        let backgroundDuration = TimeInterval.random(in: 0.1...3.0)
        mocks.backgroundTimeMonitor.backgroundTime = backgroundDuration
        let expectedError = ChartboostMediationError(code: .loadFailureUnknown)
        let expectedResult = AdLoadResult(
            result: .failure(ChartboostMediationError(code: .loadFailureUnknown)),
            metrics: ["hello": 23, "babab": "asdasfd"]
        )
        let expectedAuctionID = "some auction ID"
        let expectedLoadEvents = [MetricsEvent.test(), MetricsEvent.test(), MetricsEvent.test(), MetricsEvent.test()]
        mocks.metrics.setReturnValue(expectedResult.metrics, for: .logLoad)

        // Load ad
        var completed = false
        adRepository.loadAd(request: request, viewController: viewController, delegate: delegate) { result in
            // Check the result is as expected and metrics correspond to those obtained from the metrics logger
            XCTAssertAnyEqual(result, expectedResult)
            completed = true
        }

        // Check we have not finished yet and AuctionService has been called
        XCTAssertFalse(completed)
        var auctionCompletion: (AdAuctionResponse) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.auctionService, .startAuction, parameters: [request, XCTMethodCaptureParameter { auctionCompletion = $0 }])

        // Make auction complete with success
        auctionCompletion(AdAuctionResponse(result: .success(bids), auctionID: expectedAuctionID))

        // Check we have not finished yet and the BidFulfillOperation has started
        XCTAssertFalse(completed)
        var fulfillCompletion: ((BidFulfillOperationResult) -> Void) = { _ in }
        XCTAssertMethodCalls(mocks.bidFulfillOperationFactory, .makeBidFulfillOperation, parameters: [bids, request, viewController, delegate])
        let fulfillOperation = mocks.bidFulfillOperationFactory.returnValue(for: .makeBidFulfillOperation) as BidFulfillOperationMock
        XCTAssertMethodCalls(fulfillOperation, .run, parameters: [XCTMethodCaptureParameter { fulfillCompletion = $0 }])

        // Make fulfill complete with failure
        fulfillCompletion(BidFulfillOperationResult(result: .failure(expectedError), loadEvents: expectedLoadEvents))

        // Check that we have finished with failure
        XCTAssertTrue(completed)

        // Check metrics are logged, including the error returned by the bid fulfill operation
        XCTAssertMethodCalls(mocks.metrics, .logLoad, parameters: [
            expectedAuctionID,
            loadID,
            XCTMethodSomeParameter<[MetricsEvent]> {
                self.assertEqual($0, expectedLoadEvents)
            },
            expectedError,
            request.adFormat,
            request.adSize?.size,
            XCTMethodSomeParameter<Date> {
                XCTAssertTrue($0 > testStartedOn)
                XCTAssertTrue($0 < Date())
            },
            XCTMethodSomeParameter<Date> {
                XCTAssertTrue($0 > testStartedOn)
                XCTAssertTrue($0 > self.mocks.metrics.recordedParameters[0][6] as! Date)
                XCTAssertTrue($0 < Date())
            },
            backgroundDuration
        ])
    }

    // MARK: - Helpers
    func assertEqual(_ ad1: PartnerAd, _ ad2: PartnerAd) {
        XCTAssertIdentical(ad1.inlineView, ad2.inlineView)
        XCTAssertEqual(ad1.request, ad2.request)
    }
    
    private func assertEqual(_ observedLoads: [MetricsEvent], _ expectedLoads: [MetricsEvent]) {
        XCTAssertEqual(observedLoads.count, expectedLoads.count)
        for (observed, expected) in zip(observedLoads, expectedLoads) {
            XCTAssertEqual(observed.partnerIdentifier, expected.partnerIdentifier)
            XCTAssertEqual(observed.partnerPlacement, expected.partnerPlacement)
            XCTAssertEqual(observed.lineItemIdentifier, expected.lineItemIdentifier)
            XCTAssertEqual(observed.error?.chartboostMediationCode, expected.error?.chartboostMediationCode)
        }
    }
}
