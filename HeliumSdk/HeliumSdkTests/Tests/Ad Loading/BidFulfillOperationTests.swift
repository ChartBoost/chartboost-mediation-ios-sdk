// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class BidFulfillOperationTests: ChartboostMediationTestCase {

    lazy var operation = PartnerControllerBidFulfillOperation(
        bids: bids,
        request: request,
        viewController: viewController,
        delegate: delegate
    )
    
    var bids: [Bid] = []
    var request = AdLoadRequest(
        adSize: .init(size: CGSize(width: 23, height: 45), type: .fixed),
        adFormat: .interstitial,
        keywords: ["asd": "fgh"],
        mediationPlacement: "some helium placement",
        loadID: "some load ID"
    )
    let viewController = UIViewController()
    let delegate = PartnerAdDelegateMock()

    override func setUp() {
        super.setUp()
        mocks.environment.sdkSettings.discardOversizedAds = false
    }
    
    /// Validates that the bid fulfiller returns immediately if an empty list of bids is passed in the fulfill() call.
    func testFulfillWithNoBids() {
        bids = []
        
        var completed = false
        // Fulfill 0 bids
        operation.run { result in
            // Check completion error
            if case .failure(let error) = result.result {
                XCTAssertEqual(error.chartboostMediationCode, .loadFailureWaterfallExhaustedNoFill)
            } else {
                XCTFail("Received unexpected successful result")
            }
            // Check load events
            XCTAssertEqual(result.loadEvents.count, 0)
            completed = true
        }
        // Completion should be called immediately with failure
        XCTAssertTrue(completed)
    }
    
    /// Validates that the bid fulfiller returns fails early on fulfill() if another fulfill operation was already ongoing.
    func testFulfillFailsIfAPreviousFulfillmentIsStillOngoing() {
        bids = [Bid.makeMock()]
        var completed = false
        // Fulfill 1 bids
        operation.run { result in
            XCTFail("Should not complete yet")
            completed = true
        }
        // Check that we have not completed yet, since the fulfiller should be waiting for the partner controller load response
        XCTAssertFalse(completed)
        
        // Call fulfill again
        var completed2 = false
        operation.run { result in
            // Check completion error
            if case .failure(let error) = result.result {
                XCTAssertEqual(error.chartboostMediationCode, .loadFailureUnknown)
            } else {
                XCTFail("Received unexpected successful result")
            }
            // Check load events
            XCTAssertEqual(result.loadEvents.count, 0)
            completed2 = true
        }

        // Check that the second fulfill() call completed immediately with failure, while the first one is still ongoing
        XCTAssertTrue(completed2)
        XCTAssertFalse(completed)
    }
    
    /// Validates that the bid fulfiller finishes when the first bid load succeeds without evaluating any other bid
    func testFulfillWhenFirstBidLoadSucceeds() {
        let bid1 = Bid.makeMock()
        let bid2 = Bid.makeMock()
        let bid3 = Bid.makeMock()
        bids = [bid1, bid2, bid3]
        let expectedRequest1 = partnerLoadRequest(for: bid1)
        let expectedPartnerAd1 = PartnerAdMock(request: expectedRequest1)
        let expectedLoadAttempt1 = MetricsEvent.test(bid: bid1, errorCode: nil)

        var completed = false
        // Fulfill
        operation.run { [self] result in
            // Check that first bid won
            if case .success(let response) = result.result {
                XCTAssertAnyEqual(response.winningBid, bid1)
                assertEqual(response.partnerAd, expectedPartnerAd1)
            } else {
                XCTFail("Received unexpected failure result")
            }
            // Check load events
            assertEqual(result.loadEvents, [expectedLoadAttempt1])
            completed = true
        }
        // Check that we have not completed yet, since the fulfiller should be waiting for the partner controller load response
        XCTAssertFalse(completed)
        // Check that partner controller was asked to load for the first bid
        var partnerLoadCompletion: (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeLoad, parameters: [expectedRequest1, viewController, delegate, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        
        // Make partner controller finish the load
        partnerLoadCompletion(.success((expectedPartnerAd1, [:])))
        
        // Check that bid fulfiller has finished successfuly
        XCTAssertTrue(completed)
    }

    /// Validates that the bid fulfiller finishes when the second bid load succeeds after the first one failed.
    func testFulfillWhenFirstBidLoadFailsAndSecondBidLoadSucceeds() {
        let bid1 = Bid.makeMock()
        let bid2 = Bid.makeMock()
        let bid3 = Bid.makeMock()
        bids = [bid1, bid2, bid3]
        let expectedRequest1 = partnerLoadRequest(for: bid1)
        let expectedRequest2 = partnerLoadRequest(for: bid2)
        let expectedPartnerAd2 = PartnerAdMock(request: expectedRequest2)
        let expectedLoadAttempt1 = MetricsEvent.test(bid: bid1, errorCode: .partnerError)
        let expectedLoadAttempt2 = MetricsEvent.test(bid: bid2, errorCode: nil)
        
        var completed = false
        // Fulfill
        operation.run { [self] result in
            // Check that second bid won
            if case .success(let response) = result.result {
                XCTAssertAnyEqual(response.winningBid, bid2)
                assertEqual(response.partnerAd, expectedPartnerAd2)
            } else {
                XCTFail("Received unexpected failure result")
            }
            // Check load events
            assertEqual(result.loadEvents, [expectedLoadAttempt1, expectedLoadAttempt2])
            completed = true
        }
        // Check that we have not completed yet, since the fulfiller should be waiting for the partner controller load response
        XCTAssertFalse(completed)
        // Check that partner controller was asked to load for the first bid
        var partnerLoadCompletion: (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeLoad, parameters: [expectedRequest1, viewController, delegate, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        
        // Make partner controller finish the load with a failure
        partnerLoadCompletion(.failure(ChartboostMediationError(code: .partnerError)))
        
        // Check that we have not completed yet and the partner controller was asked to load the second bid
        XCTAssertFalse(completed)
        var partnerLoadCompletion2: (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeLoad, parameters: [expectedRequest2, viewController, delegate, XCTMethodCaptureParameter { partnerLoadCompletion2 = $0 }])

        // Make partner controller finish the second load successfuly
        partnerLoadCompletion2(.success((expectedPartnerAd2, [:])))
        
        // Check that bid fulfiller has finished successfuly
        XCTAssertTrue(completed)
    }
    
    /// Validates that the bid fulfiller finishes when the last bid load succeeds after all the previous ones failed.
    func testFulfillWhenAllBidLoadsFailExpceptTheLastOne() {
        let bid1 = Bid.makeMock()
        let bid2 = Bid.makeMock()
        let bid3 = Bid.makeMock()
        let bid4 = Bid.makeMock()
        bids = [bid1, bid2, bid3, bid4]
        let expectedRequest1 = partnerLoadRequest(for: bid1)
        let expectedRequest2 = partnerLoadRequest(for: bid2)
        let expectedRequest3 = partnerLoadRequest(for: bid3)
        let expectedRequest4 = partnerLoadRequest(for: bid4)
        let expectedPartnerAd4 = PartnerAdMock(request: expectedRequest4)
        let expectedLoadAttempt1 = MetricsEvent.test(bid: bid1, errorCode: .partnerError)
        let expectedLoadAttempt2 = MetricsEvent.test(bid: bid2, errorCode: .loadFailureTimeout)
        let expectedLoadAttempt3 = MetricsEvent.test(bid: bid3, errorCode: .loadFailurePartnerInstanceNotFound)
        let expectedLoadAttempt4 = MetricsEvent.test(bid: bid4, errorCode: nil)
        
        var completed = false
        // Fulfill
        operation.run { [self] result in
            // Check that last bid won
            if case .success(let response) = result.result {
                XCTAssertAnyEqual(response.winningBid, bid4)
                assertEqual(response.partnerAd, expectedPartnerAd4)
            } else {
                XCTFail("Received unexpected failure result")
            }
            // Check load events
            assertEqual(result.loadEvents, [expectedLoadAttempt1, expectedLoadAttempt2, expectedLoadAttempt3, expectedLoadAttempt4])
            completed = true
        }
        // Check that we have not completed yet, since the fulfiller should be waiting for the partner controller load response
        XCTAssertFalse(completed)
        // Check that partner controller was asked to load for the first bid
        var partnerLoadCompletion: (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeLoad, parameters: [expectedRequest1, viewController, delegate, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        
        // Make partner controller finish the load with a failure
        partnerLoadCompletion(.failure(ChartboostMediationError(code: .partnerError)))
        
        // Check that we have not completed yet and the partner controller was asked to load the second bid
        XCTAssertFalse(completed)
        XCTAssertMethodCalls(mocks.partnerController, .routeLoad, parameters: [expectedRequest2, viewController, delegate, XCTMethodIgnoredParameter()])

        // Make fulfiller's time out task fire immediately, so it moves on to the next bid
        mocks.taskDispatcher.performDelayedWorkItems()

        // Check that we have not completed yet and the partner controller was asked to cancel the previous load and load the third bid
        XCTAssertFalse(completed)
        var partnerLoadCompletion3: (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .cancelLoad, .routeLoad, parameters: [], [expectedRequest3, viewController, delegate, XCTMethodCaptureParameter { partnerLoadCompletion3 = $0 }])
        
        // Make partner controller finish the load with a failure
        partnerLoadCompletion3(.failure(ChartboostMediationError(code: .loadFailurePartnerInstanceNotFound)))
        
        // Check that we have not completed yet and the partner controller was asked to load the fourth bid
        XCTAssertFalse(completed)
        var partnerLoadCompletion4: (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeLoad, parameters: [expectedRequest4, viewController, delegate, XCTMethodCaptureParameter { partnerLoadCompletion4 = $0 }])
        
        // Make partner controller finish the fourth load successfuly
        partnerLoadCompletion4(.success((expectedPartnerAd4, [:])))
        
        // Check that bid fulfiller has finished successfuly
        XCTAssertTrue(completed)
    }
    
    /// Validates that the bid fulfiller finishes with a failure when all partners fail.
    func testFulfillWhenAllBidLoadsFail() {
        let bid1 = Bid.makeMock()
        let bid2 = Bid.makeMock()
        let bid3 = Bid.makeMock()
        let bid4 = Bid.makeMock()
        bids = [bid1, bid2, bid3, bid4]
        let expectedRequest1 = partnerLoadRequest(for: bid1)
        let expectedRequest2 = partnerLoadRequest(for: bid2)
        let expectedRequest3 = partnerLoadRequest(for: bid3)
        let expectedRequest4 = partnerLoadRequest(for: bid4)
        let expectedLoadAttempt1 = MetricsEvent.test(bid: bid1, errorCode: .partnerError)
        let expectedLoadAttempt2 = MetricsEvent.test(bid: bid2, errorCode: .loadFailureTimeout)
        let expectedLoadAttempt3 = MetricsEvent.test(bid: bid3, errorCode: .loadFailureAdapterNotFound)
        let expectedLoadAttempt4 = MetricsEvent.test(bid: bid4, errorCode: .partnerError)
        
        var completed = false
        // Fulfill
        operation.run { [self] result in
            // Check that no bid won
            if case .failure(let error) = result.result {
                XCTAssertEqual(error.chartboostMediationCode, .loadFailureWaterfallExhaustedNoFill)
            } else {
                XCTFail("Received unexpected successful result")
            }
            // Check load events
            assertEqual(result.loadEvents, [expectedLoadAttempt1, expectedLoadAttempt2, expectedLoadAttempt3, expectedLoadAttempt4])
            completed = true
        }
        // Check that we have not completed yet, since the fulfiller should be waiting for the partner controller load response
        XCTAssertFalse(completed)
        // Check that partner controller was asked to load for the first bid
        var partnerLoadCompletion: (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeLoad, parameters: [expectedRequest1, viewController, delegate, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        
        // Make partner controller finish the load with a failure
        partnerLoadCompletion(.failure(ChartboostMediationError(code: .partnerError)))
        
        // Check that we have not completed yet and the partner controller was asked to load the second bid
        XCTAssertFalse(completed)
        XCTAssertMethodCalls(mocks.partnerController, .routeLoad, parameters: [expectedRequest2, viewController, delegate, XCTMethodIgnoredParameter()])

        // Make fulfiller's time out task fire immediately, so it moves on to the next bid
        mocks.taskDispatcher.performDelayedWorkItems()

        // Check that we have not completed yet and the partner controller was asked to cancel the previous load and load the third bid
        XCTAssertFalse(completed)
        var partnerLoadCompletion3: (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .cancelLoad, .routeLoad, parameters: [], [expectedRequest3, viewController, delegate, XCTMethodCaptureParameter { partnerLoadCompletion3 = $0 }])
        
        // Make partner controller finish the load with a failure
        partnerLoadCompletion3(.failure(ChartboostMediationError(code: .loadFailureAdapterNotFound)))
        
        // Check that we have not completed yet and the partner controller was asked to load the fourth bid
        XCTAssertFalse(completed)
        var partnerLoadCompletion4: (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeLoad, parameters: [expectedRequest4, viewController, delegate, XCTMethodCaptureParameter { partnerLoadCompletion4 = $0 }])
        
        // Make partner controller finish the fourth load with a failure
        partnerLoadCompletion4(.failure(ChartboostMediationError(code: .partnerError)))
        
        // Check that bid fulfiller has finished with a failure
        XCTAssertTrue(completed)
    }
    
    /// Validates that the bid fulfiller times out a bid load when it takes too long.
    func testFulfillWhenBidsTimeOut() {
        let bid1 = Bid.makeMock()
        let bid2 = Bid.makeMock()
        bids = [bid1, bid2]
        let expectedRequest1 = partnerLoadRequest(for: bid1)
        let expectedRequest2 = partnerLoadRequest(for: bid2)
        let expectedLoadAttempt1 = MetricsEvent.test(bid: bid1, errorCode: .loadFailureTimeout)
        let expectedLoadAttempt2 = MetricsEvent.test(bid: bid2, errorCode: .loadFailureTimeout)
        
        var completed = false
        // Fulfill
        operation.run { [self] result in
            // Check that no bid won
            if case .failure(let error) = result.result {
                XCTAssertEqual(error.chartboostMediationCode, .loadFailureWaterfallExhaustedNoFill)
            } else {
                XCTFail("Received unexpected successful result")
            }
            // Check load events
            assertEqual(result.loadEvents, [expectedLoadAttempt1, expectedLoadAttempt2])
            completed = true
        }
        // Check that we have not completed yet, since the fulfiller should be waiting for the partner controller load response
        XCTAssertFalse(completed)
        // Check that partner controller was asked to load for the first bid
        XCTAssertMethodCalls(mocks.partnerController, .routeLoad, parameters: [expectedRequest1, viewController, delegate, XCTMethodIgnoredParameter()])
        // Check that the timeout task has been scheduled
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), mocks.bidFulfillOperationConfiguration.fullscreenLoadTimeout, XCTMethodIgnoredParameter()])
        
        // Make fulfiller's time out task fire immediately, so it moves on to the next bid
        mocks.taskDispatcher.performDelayedWorkItems()
        
        // Check that we have not completed yet and the partner controller was asked to cancel the previous load and load the second bid
        XCTAssertFalse(completed)
        XCTAssertMethodCalls(mocks.partnerController, .cancelLoad, .routeLoad, parameters: [], [expectedRequest2, viewController, delegate, XCTMethodIgnoredParameter()])
        // Check that the timeout task has been scheduled
        XCTAssertMethodCalls(mocks.taskDispatcher, .asyncDelayed, parameters: [XCTMethodIgnoredParameter(), mocks.bidFulfillOperationConfiguration.fullscreenLoadTimeout, XCTMethodIgnoredParameter()])
        
        // Make fulfiller's time out task fire immediately, so it moves on to finish the operation
        mocks.taskDispatcher.performDelayedWorkItems()
        
        // Check that bid fulfiller has finished with failure
        XCTAssertTrue(completed)
    }
    
    /// Validates that the bid fulfiller ignores a late load response received after the timeout period.
    func testFulfillIgnoresATimedOutLoadResponse() {
        let bid1 = Bid.makeMock()
        let bid2 = Bid.makeMock()
        bids = [bid1, bid2]
        let expectedRequest1 = partnerLoadRequest(for: bid1)
        let expectedRequest2 = partnerLoadRequest(for: bid2)
        let expectedPartnerAd1 = PartnerAdMock(request: expectedRequest1)
        let expectedPartnerAd2 = PartnerAdMock(request: expectedRequest2)
        let expectedLoadAttempt1 = MetricsEvent.test(bid: bid1, errorCode: .loadFailureTimeout)
        let expectedLoadAttempt2 = MetricsEvent.test(bid: bid2, errorCode: nil)
        
        var completed = false
        // Fulfill
        operation.run { [self] result in
            // Check that second bid won
            if case .success(let response) = result.result {
                XCTAssertAnyEqual(response.winningBid, bid2)
                assertEqual(response.partnerAd, expectedPartnerAd2)
            } else {
                XCTFail("Received unexpected failure result")
            }
            // Check load events
            assertEqual(result.loadEvents, [expectedLoadAttempt1, expectedLoadAttempt2])
            completed = true
        }
        // Check that we have not completed yet, since the fulfiller should be waiting for the partner controller load response
        XCTAssertFalse(completed)
        // Check that partner controller was asked to load for the first bid
        var partnerLoadCompletion: (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeLoad, parameters: [expectedRequest1, viewController, delegate, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        
        // Make fulfiller's time out task fire immediately, so it moves on to the next bid
        mocks.taskDispatcher.performDelayedWorkItems()
        
        // Check that we have not completed yet and the partner controller was asked to cancel the previous load and load the second bid
        XCTAssertFalse(completed)
        var partnerLoadCompletion2: (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .cancelLoad, .routeLoad, parameters: [], [expectedRequest2, viewController, delegate, XCTMethodCaptureParameter { partnerLoadCompletion2 = $0 }])
        
        // Make first bid load finish now, which should be too late!
        partnerLoadCompletion(.success((expectedPartnerAd1, [:])))
        
        // Check that we have not completed yet, since the fulfiller should be waiting for the second partner controller load response
        XCTAssertFalse(completed)
        
        // Make partner controller finish the second load successfuly
        partnerLoadCompletion2(.success((expectedPartnerAd2, [:])))
        
        // Check that bid fulfiller has finished successfuly
        XCTAssertTrue(completed)
    }
    
    /// Validates that the bid fulfiller sends proper events to the event logger when a bid fails.
    func testFulfillLogsErrorEvents() {
        let bid1 = Bid.makeMock()
        bids = [bid1]
        let expectedRequest1 = partnerLoadRequest(for: bid1)
        let expectedLoadAttempt1 = MetricsEvent.test(bid: bid1, errorCode: .partnerError)
        
        var completed = false
        // Fulfill
        operation.run { [self] result in
            // Check that no bid won
            if case .failure(let error) = result.result {
                XCTAssertEqual(error.chartboostMediationCode, .loadFailureWaterfallExhaustedNoFill)
            } else {
                XCTFail("Received unexpected successful result")
            }
            // Check load events
            assertEqual(result.loadEvents, [expectedLoadAttempt1])
            completed = true
        }
        // Check that we have not completed yet, since the fulfiller should be waiting for the partner controller load response
        XCTAssertFalse(completed)
        // Check that partner controller was asked to load for the first bid
        var partnerLoadCompletion: (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeLoad, parameters: [expectedRequest1, viewController, delegate, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        
        // Make partner controller finish the load with a failure
        let error = ChartboostMediationError(code: .partnerError)
        partnerLoadCompletion(.failure(error))
        
        // Check that bid fulfiller has finished with a failure
        XCTAssertTrue(completed)
    }
    
    /// Validates that the bid fulfiller returns load attempt models with proper loadTime values.
    func testFulfillReturnsAttemptsWithProperLoadTime() {
        let bid1 = Bid.makeMock()
        let bid2 = Bid.makeMock()
        let bid3 = Bid.makeMock()
        bids = [bid1, bid2, bid3]
        let expectedRequest1 = partnerLoadRequest(for: bid1)
        let expectedRequest2 = partnerLoadRequest(for: bid2)
        let expectedRequest3 = partnerLoadRequest(for: bid3)
        let expectedPartnerAd3 = PartnerAdMock(request: expectedRequest3)
        var expectedLoadAttempt1: MetricsEvent?
        var expectedLoadAttempt2: MetricsEvent?
        let expectedLoadAttempt3 = MetricsEvent.test(bid: bid3, errorCode: nil, loadTime: 0)
        
        var completed = false
        let load1StartDate = Date()
        // Fulfill
        operation.run { [self] result in
            // Check that third bid won
            if case .success(let response) = result.result {
                XCTAssertAnyEqual(response.winningBid, bid3)
                assertEqual(response.partnerAd, expectedPartnerAd3)
            } else {
                XCTFail("Received unexpected failure result")
            }
            // Check load events
            assertEqual(result.loadEvents, [expectedLoadAttempt1, expectedLoadAttempt2, expectedLoadAttempt3].compactMap { $0 })
            completed = true
        }
        // Check that we have not completed yet, since the fulfiller should be waiting for the partner controller load response
        XCTAssertFalse(completed)
        // Check that partner controller was asked to load for the first bid
        var partnerLoadCompletion: (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .routeLoad, parameters: [expectedRequest1, viewController, delegate, XCTMethodCaptureParameter { partnerLoadCompletion = $0 }])
        
        // Make partner controller finish the load with a failure after 1 second
        wait(duration: 1)
        let load2StartDate = Date()
        partnerLoadCompletion(.failure(ChartboostMediationError(code: .partnerError)))
        expectedLoadAttempt1 = MetricsEvent.test(bid: bid1, errorCode: .partnerError, loadTime: -load1StartDate.timeIntervalSinceNow) // save expected load attempt event now that we know what `duration` value to expect. note that wait() can take longer than expected when run on CI machines.
        
        // Check that we have not completed yet and the partner controller was asked to load the second bid
        XCTAssertFalse(completed)
        XCTAssertMethodCalls(mocks.partnerController, .routeLoad, parameters: [expectedRequest2, viewController, delegate, XCTMethodIgnoredParameter()])

        // Make fulfiller's time out task fire after 2.5 seconds, so it moves on to the next bid
        wait(duration: 2.5)
        mocks.taskDispatcher.performDelayedWorkItems()
        expectedLoadAttempt2 = MetricsEvent.test(bid: bid2, errorCode: .loadFailureTimeout, loadTime: -load2StartDate.timeIntervalSinceNow) // save expected load attempt event now that we know what `duration` value to expect. note that wait() can take longer than expected when run on CI machines.
        
        // Check that we have not completed yet and the partner controller was asked to cancel the previous load and load the third bid
        XCTAssertFalse(completed)
        var partnerLoadCompletion3: (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void = { _ in }
        XCTAssertMethodCalls(mocks.partnerController, .cancelLoad, .routeLoad, parameters: [], [expectedRequest3, viewController, delegate, XCTMethodCaptureParameter { partnerLoadCompletion3 = $0 }])
        
        // Make partner controller finish the load with success after 0 seconds
        partnerLoadCompletion3(.success((expectedPartnerAd3, [:])))
        
        // Check that bid fulfiller has finished successfuly
        XCTAssertTrue(completed)
    }

    func testRoutesLoadWithBannerSizeFromBid() throws {
        request = AdLoadRequest.test(adSize: .standard, adFormat: .banner)
        bids = [Bid.makeMock(size: CGSize(width: 400.0, height: 100.0))]
        operation.run { _ in }
        try assertRoutesLoad(bid: bids[0])
    }

    func testRoutesLoadWithRequestedSizeIfBidSizeIsNil() throws {
        request = AdLoadRequest.test(adSize: .standard, adFormat: .banner)
        bids = [Bid.makeMock()]
        operation.run { _ in }
        try assertRoutesLoad(bid: bids[0])
    }

    // MARK: - Banner Size
    func testAdSizeIsNilWhenPartnerDetailsDoesNotContainSizeAndRequestedAdSizeIsNil() throws {
        request = AdLoadRequest.test(adSize: nil, adFormat: .interstitial)
        bids = [Bid.makeMock()]
        let partnerDetails: [String: String] = [:]

        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .success(let response) = result.result {
                XCTAssertNil(response.adSize)
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((PartnerAdMock(), partnerDetails)))
        waitForExpectations(timeout: 1.0)
    }


    func testAdSizeIsRequestedAdSizeWhenPartnerDetailsDoesNotContainSize() throws {
        request = AdLoadRequest.test(adSize: .standard, adFormat: .banner)
        bids = [Bid.makeMock()]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails: [String: String] = [:]

        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .success(let response) = result.result {
                XCTAssertEqual(response.adSize?.type, .fixed)
                XCTAssertEqual(response.adSize?.size.width, 320)
                XCTAssertEqual(response.adSize?.size.height, 50)
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        waitForExpectations(timeout: 1.0)
    }

    func testAdaptiveAdSizeIsParsedFromPartnerDetails() throws {
        request = AdLoadRequest.test(adSize: .adaptive(width: 500.0), adFormat: .banner)
        bids = [Bid.makeMock()]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails = [
            "bannerType": "1",
            "bannerWidth": "400.0",
            "bannerHeight": "100.0",
        ]

        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .success(let response) = result.result {
                XCTAssertEqual(response.adSize?.type, .adaptive)
                XCTAssertEqual(response.adSize?.size.width, 400)
                XCTAssertEqual(response.adSize?.size.height, 100)
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        waitForExpectations(timeout: 1.0)
    }

    func testFixedAdSizeIsParsedFromPartnerDetails() throws {
        request = AdLoadRequest.test(adSize: .adaptive(width: 500.0), adFormat: .banner)
        bids = [Bid.makeMock()]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails = [
            "bannerType": "0",
            "bannerWidth": "320.0",
            "bannerHeight": "50.0",
        ]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .success(let response) = result.result {
                XCTAssertEqual(response.adSize?.type, .fixed)
                XCTAssertEqual(response.adSize?.size.width, 320)
                XCTAssertEqual(response.adSize?.size.height, 50)
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Discard oversized ads
    func testDoesNotDiscardAdWhenRequestedHeightIsZero() throws {
        mocks.environment.sdkSettings.discardOversizedAds = true

        request = AdLoadRequest.test(adSize: .adaptive(width: 500.0), adFormat: .banner)
        bids = [Bid.makeMock()]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails = [
            "bannerType": "1",
            "bannerWidth": "400.0",
            "bannerHeight": "100.0",
        ]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .success(let response) = result.result {
                XCTAssertEqual(response.adSize?.type, .adaptive)
                XCTAssertEqual(response.adSize?.size.width, 400)
                XCTAssertEqual(response.adSize?.size.height, 100)
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        waitForExpectations(timeout: 1.0)
    }

    func testDoesNotDiscardAdaptiveSizeAdWhenAdSizeMatchesRequestedSize() throws {
        mocks.environment.sdkSettings.discardOversizedAds = true

        request = AdLoadRequest.test(adSize: .adaptive(width: 400.0, maxHeight: 50.0), adFormat: .banner)
        bids = [Bid.makeMock()]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails = [
            "bannerType": "1",
            "bannerWidth": "400.0",
            "bannerHeight": "50.0",
        ]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .success(let response) = result.result {
                XCTAssertEqual(response.adSize?.type, .adaptive)
                XCTAssertEqual(response.adSize?.size.width, 400)
                XCTAssertEqual(response.adSize?.size.height, 50)
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        waitForExpectations(timeout: 1.0)
    }

    func testDoesNotDiscardFixedSizeAdWhenAdSizeMatchesRequestedSize() throws {
        mocks.environment.sdkSettings.discardOversizedAds = true

        request = AdLoadRequest.test(adSize: .standard, adFormat: .banner)
        bids = [Bid.makeMock()]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails = [
            "bannerType": "0",
            "bannerWidth": "320.0",
            "bannerHeight": "50.0",
        ]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .success(let response) = result.result {
                XCTAssertEqual(response.adSize?.type, .fixed)
                XCTAssertEqual(response.adSize?.size.width, 320)
                XCTAssertEqual(response.adSize?.size.height, 50)
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        waitForExpectations(timeout: 1.0)
    }

    func testDoesNotDiscardAdIfWidthIsTooLargeButDiscardOversizedAdsIsFalse() throws {
        mocks.environment.sdkSettings.discardOversizedAds = false

        request = AdLoadRequest.test(adSize: .adaptive(width: 300.0), adFormat: .banner)
        bids = [Bid.makeMock()]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails = [
            "bannerType": "1",
            "bannerWidth": "400.0",
            "bannerHeight": "100.0",
        ]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .success(let response) = result.result {
                XCTAssertEqual(response.adSize?.type, .adaptive)
                XCTAssertEqual(response.adSize?.size.width, 400)
                XCTAssertEqual(response.adSize?.size.height, 100)
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        waitForExpectations(timeout: 1.0)
    }

    func testDoesNotDiscardAdIfHeightIsTooLargeButDiscardOversizedAdsIsFalse() throws {
        mocks.environment.sdkSettings.discardOversizedAds = false

        request = AdLoadRequest.test(adSize: .adaptive(width: 500.0, maxHeight: 50.0), adFormat: .banner)
        bids = [Bid.makeMock()]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails = [
            "bannerType": "1",
            "bannerWidth": "400.0",
            "bannerHeight": "100.0",
        ]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .success(let response) = result.result {
                XCTAssertEqual(response.adSize?.type, .adaptive)
                XCTAssertEqual(response.adSize?.size.width, 400)
                XCTAssertEqual(response.adSize?.size.height, 100)
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        waitForExpectations(timeout: 1.0)
    }

    func testDiscardsAdWhenWidthIsTooLarge() throws {
        mocks.environment.sdkSettings.discardOversizedAds = true

        request = AdLoadRequest.test(adSize: .adaptive(width: 300.0), adFormat: .banner)
        bids = [Bid.makeMock()]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails = [
            "bannerType": "1",
            "bannerWidth": "400.0",
            "bannerHeight": "100.0",
        ]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .failure(let error) = result.result {
                if #available(iOS 14.5, *) {
                    let underlyingError = try? XCTUnwrap(error.underlyingErrors.first as? ChartboostMediationError)
                    XCTAssertEqual(underlyingError?.code, ChartboostMediationError.Code.loadFailureAdTooLarge.rawValue)
                }
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        waitForExpectations(timeout: 1.0)
    }

    func testDiscardsAdWhenHeightIsTooLarge() throws {
        mocks.environment.sdkSettings.discardOversizedAds = true

        request = AdLoadRequest.test(adSize: .adaptive(width: 500.0, maxHeight: 50.0), adFormat: .banner)
        bids = [Bid.makeMock()]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails = [
            "bannerType": "1",
            "bannerWidth": "400.0",
            "bannerHeight": "100.0",
        ]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .failure(let error) = result.result {
                if #available(iOS 14.5, *) {
                    let underlyingError = try? XCTUnwrap(error.underlyingErrors.first as? ChartboostMediationError)
                    XCTAssertEqual(underlyingError?.code, ChartboostMediationError.Code.loadFailureAdTooLarge.rawValue)
                }
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        waitForExpectations(timeout: 1.0)
    }

    func testDoesNotDiscardAdIfRequestedSizeIsNil() throws {
        mocks.environment.sdkSettings.discardOversizedAds = true

        request = AdLoadRequest.test(adSize: nil, adFormat: .banner)
        bids = [Bid.makeMock()]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails: [String: String] = [:]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .success(let response) = result.result {
                XCTAssertNil(response.adSize)
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        waitForExpectations(timeout: 1.0)
    }

    func testDoesNotDiscardAdIfReturnedSizeIsNil() throws {
        mocks.environment.sdkSettings.discardOversizedAds = true

        request = AdLoadRequest.test(adSize: nil, adFormat: .banner)
        bids = [Bid.makeMock()]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails: [String: String] = [:]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .success(let response) = result.result {
                XCTAssertNil(response.adSize)
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        waitForExpectations(timeout: 1.0)
    }

    func testDiscardsAdForAdaptiveBannerFormat() throws {
        mocks.environment.sdkSettings.discardOversizedAds = true

        request = AdLoadRequest.test(adSize: .adaptive(width: 500.0, maxHeight: 50.0), adFormat: .adaptiveBanner)
        bids = [Bid.makeMock()]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails = [
            "bannerType": "1",
            "bannerWidth": "400.0",
            "bannerHeight": "100.0",
        ]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .failure(let error) = result.result {
                if #available(iOS 14.5, *) {
                    let underlyingError = try? XCTUnwrap(error.underlyingErrors.first as? ChartboostMediationError)
                    XCTAssertEqual(underlyingError?.code, ChartboostMediationError.Code.loadFailureAdTooLarge.rawValue)
                }
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        waitForExpectations(timeout: 1.0)
    }

    // MARK: Continuing Waterfall
    func testDoesNotContinueWaterfallIfSizeIsTooLargeButDiscardOversizedAdsIsFalse() throws {
        mocks.environment.sdkSettings.discardOversizedAds = false

        request = AdLoadRequest.test(adSize: .adaptive(width: 300.0), adFormat: .banner)
        bids = [
            Bid.makeMock(),
            Bid.makeMock()
        ]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails = [
            "bannerType": "1",
            "bannerWidth": "400.0",
            "bannerHeight": "100.0",
        ]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .success(let response) = result.result {
                XCTAssertEqual(response.adSize?.type, .adaptive)
                XCTAssertEqual(response.adSize?.size.width, 400)
                XCTAssertEqual(response.adSize?.size.height, 100)
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        XCTAssertNoMethodCalls(mocks.partnerController)
        waitForExpectations(timeout: 1.0)
    }

    func testDoesNotContinueWaterfallIfSizeFitsAndDiscardOversizedAdsIsTrue() throws {
        mocks.environment.sdkSettings.discardOversizedAds = true

        request = AdLoadRequest.test(adSize: .adaptive(width: 300.0), adFormat: .banner)
        bids = [
            Bid.makeMock(),
            Bid.makeMock()
        ]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails = [
            "bannerType": "1",
            "bannerWidth": "300.0",
            "bannerHeight": "100.0",
        ]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .success(let response) = result.result {
                XCTAssertEqual(response.adSize?.type, .adaptive)
                XCTAssertEqual(response.adSize?.size.width, 300)
                XCTAssertEqual(response.adSize?.size.height, 100)
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        XCTAssertNoMethodCalls(mocks.partnerController)
        waitForExpectations(timeout: 1.0)
    }

    func testContinuesWaterfallAndSucceedsIfSizeIsTooLargeAndDiscardOversizedAdsIsTrue() throws {
        mocks.environment.sdkSettings.discardOversizedAds = true

        request = AdLoadRequest.test(adSize: .adaptive(width: 300.0), adFormat: .banner)
        bids = [
            Bid.makeMock(),
            Bid.makeMock()
        ]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails = [
            "bannerType": "1",
            "bannerWidth": "400.0",
            "bannerHeight": "100.0",
        ]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .success(let response) = result.result {
                XCTAssertEqual(response.adSize?.type, .adaptive)
                XCTAssertEqual(response.adSize?.size.width, 250.0)
                XCTAssertEqual(response.adSize?.size.height, 100)
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        assertRoutesInvalidate(ad: partnerAd)

        let partnerAd2 = PartnerAdMock(inlineView: UIView())
        let partnerDetails2 = [
            "bannerType": "1",
            "bannerWidth": "250.0",
            "bannerHeight": "100.0",
        ]
        let completion2 = try assertRoutesLoad(bid: bids[1])
        completion2(.success((partnerAd2, partnerDetails2)))
        // The second ad succeeds, so there should be no more calls to partner controller.
        XCTAssertNoMethodCalls(mocks.partnerController)
        waitForExpectations(timeout: 1.0)
    }

    func testFailsIfSizeIsTooLargeMultipleTimesAndDiscardOversizedAdsIsTrue() throws {
        mocks.environment.sdkSettings.discardOversizedAds = true

        request = AdLoadRequest.test(adSize: .adaptive(width: 300.0), adFormat: .banner)
        bids = [
            Bid.makeMock(),
            Bid.makeMock()
        ]
        let partnerAd = PartnerAdMock(inlineView: UIView())
        let partnerDetails = [
            "bannerType": "1",
            "bannerWidth": "400.0",
            "bannerHeight": "100.0",
        ]

        // Load ad
        let loadExpectation = expectation(description: "Successful load")
        operation.run { result in
            if case .failure(let error) = result.result {
                if #available(iOS 14.5, *) {
                    let underlyingError = try? XCTUnwrap(error.underlyingErrors.first as? ChartboostMediationError)
                    XCTAssertEqual(underlyingError?.code, ChartboostMediationError.Code.loadFailureAdTooLarge.rawValue)
                }
            } else {
                XCTFail("Received unexpected result")
            }
            loadExpectation.fulfill()
        }

        let completion = try assertRoutesLoad(bid: bids[0])
        // Make partner controller finish the load
        completion(.success((partnerAd, partnerDetails)))
        assertRoutesInvalidate(ad: partnerAd)

        let partnerAd2 = PartnerAdMock(inlineView: UIView())
        let partnerDetails2 = [
            "bannerType": "1",
            "bannerWidth": "500.0",
            "bannerHeight": "150.0",
        ]
        let completion2 = try assertRoutesLoad(bid: bids[1])
        completion2(.success((partnerAd2, partnerDetails2)))
        assertRoutesInvalidate(ad: partnerAd2)
        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Configuration
    func testBidFullfillConfigurationLoadTimeout() {
        let config = BidFulfillOperationConfigurationMock()
        config.fullscreenLoadTimeout = 10
        config.bannerLoadTimeout = 20

        XCTAssertEqual(config.loadTimeout(for: .interstitial), 10)
        XCTAssertEqual(config.loadTimeout(for: .rewarded), 10)
        XCTAssertEqual(config.loadTimeout(for: .rewardedInterstitial), 10)
        XCTAssertEqual(config.loadTimeout(for: .banner), 20)
        XCTAssertEqual(config.loadTimeout(for: .adaptiveBanner), 20)
    }
}

// MARK: - Helpers

private extension BidFulfillOperationTests {
    
    func partnerLoadRequest(for bid: Bid) -> PartnerAdLoadRequest {
        PartnerAdLoadRequest(
            partnerIdentifier: bid.partnerIdentifier,
            chartboostPlacement: request.mediationPlacement,
            partnerPlacement: bid.partnerPlacement,
            format: request.adFormat,
            size: bid.size ?? request.adSize?.size,
            adm: bid.adm,
            partnerSettings: bid.partnerDetails ?? [:],
            identifier: request.loadID,
            auctionIdentifier: bid.auctionIdentifier
        )
    }
    
    func assertEqual(_ ad1: PartnerAd, _ ad2: PartnerAd) {
        XCTAssertIdentical(ad1.inlineView, ad2.inlineView)
        XCTAssertEqual(ad1.request, ad2.request)
    }
    
    func assertEqual(_ observedLoads: [MetricsEvent], _ expectedLoads: [MetricsEvent], loadTimeErrorMargin: TimeInterval = 0.5) {
        XCTAssertEqual(observedLoads.count, expectedLoads.count)
        for (observed, expected) in zip(observedLoads, expectedLoads) {
            XCTAssertEqual(observed.partnerIdentifier, expected.partnerIdentifier)
            XCTAssertEqual(observed.partnerPlacement, expected.partnerPlacement)
            XCTAssertEqual(observed.lineItemIdentifier, expected.lineItemIdentifier)
            XCTAssertEqual(observed.error?.chartboostMediationCode, expected.error?.chartboostMediationCode)
            XCTAssertGreaterThanOrEqual(observed.duration, 0)
            XCTAssertGreaterThanOrEqual(expected.duration, 0)
            XCTAssertLessThanOrEqual(abs(observed.duration - expected.duration), loadTimeErrorMargin)
        }
    }

    @discardableResult
    func assertRoutesLoad(
        bid: Bid
    ) throws -> (Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void {
        // Check we have not finished yet and AuctionService has been called
        var result: ((Result<(PartnerAd, PartnerEventDetails), ChartboostMediationError>) -> Void)?

        let expectedRequest = partnerLoadRequest(for: bid)

        let captureExpectation = expectation(description: "Capture completion block")
        XCTAssertMethodCallPop(
            mocks.partnerController,
            .routeLoad,
            parameters: [
                expectedRequest,
                viewController,
                delegate,
                XCTMethodCaptureParameter {
                    result = $0
                    captureExpectation.fulfill()
                }
            ]
        )

        wait(for: [captureExpectation], timeout: 1.0)
        return try XCTUnwrap(result)
    }

    func assertRoutesInvalidate(ad: PartnerAd) {
        XCTAssertMethodCallPop(mocks.partnerController, .routeInvalidate, parameters: [ad, XCTMethodIgnoredParameter()])
    }
}
