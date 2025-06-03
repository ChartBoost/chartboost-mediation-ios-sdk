// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class FullscreenAdQueueTests: ChartboostMediationTestCase {
    /// Each run of a test gets a new version of this variable, ensuring that queues don't get reused
    lazy var queue = FullscreenAdQueue.queue(
        forPlacement: UUID().uuidString
    )

    let delegate = FullscreenAdQueueDelegateMock()

    override func tearDown() {
        // FullscreenAdQueues cannot be destroyed, the class retains a static collection of them.
        // In an attempt to tidy up a little we will flush any work items they've created.
        // Thich will also destroy any ads they're holding, because of the expiration tasks.
        mocks.taskDispatcher.performDelayedWorkItems()
    }

    /// Requesting queues with different placement IDs does not return the same object.
    func testUniqueQueuesReturnedForUniquePlacements() throws {
        let queue1 = FullscreenAdQueue.queue(
            forPlacement: "testUniqueQueuesReturnedForUniquePlacements_A"
        )
        let queue2 = FullscreenAdQueue.queue(
            forPlacement: "testUniqueQueuesReturnedForUniquePlacements_B"
        )
        XCTAssertNotIdentical(queue1, queue2)
    }

    /// Requesting queues with identical placement IDs returns the same object.
    func testSingletonQueueReturnedForIdenticalPlacements() throws {
        let queue1 = FullscreenAdQueue.queue(
            forPlacement: "testSingletonQueueReturnedForIdenticalPlacements"
        )
        let queue2 = FullscreenAdQueue.queue(
            forPlacement: "testSingletonQueueReturnedForIdenticalPlacements"
        )
        XCTAssertIdentical(queue1, queue2)
    }

    /// The correct MetricsEvent is logged when start() and stop() are called.
    func testStartAndStopEventsSent() throws {
        queue.start()
        mocks.taskDispatcher.performDelayedWorkItems()
        XCTAssertMethodCalls(mocks.metrics, .logStartQueue, parameters: [queue])
        queue.stop()
        mocks.taskDispatcher.performDelayedWorkItems()
        XCTAssertMethodCalls(mocks.metrics, .logEndQueue, parameters: [queue])
    }

    /// The queue waits to enter the .running state if called prior to SDK init.
    func testStartEventWaitsForInit() throws {
        mocks.initializationStatusProvider.isInitialized = false
        XCTAssertFalse(queue.isRunning)
        queue.start()
        // Test both that the publisher-facing queue state is correct, and also that
        // the start queue event has not been logged to the backend.
        XCTAssertFalse(queue.isRunning)
        XCTAssertNoMethodCall(mocks.metrics, to: .logStartQueue)
        
        let notificationName = Notification.Name.chartboostMediationDidFinishInitializing
        NotificationCenter.default.post(name: notificationName, object: nil)

        // Again, test both the publisher-facing and backend-facing indicators of queue state.
        XCTAssertTrue(queue.isRunning)
        XCTAssertMethodCalls(mocks.metrics, .logStartQueue, parameters: [queue])
    }

    /// Every time a stopped queue is restarted, it adopts a new ID.
    func testRestartedQueueUsesNewID() throws {
        queue.start()
        // Can't use simulateSuccessfulAdLoad() because we need to retain the request.
        var requestA: FullscreenAdLoadRequest?
        var completion: ((FullscreenAdLoadResult) -> Void)?
        XCTAssertMethodCalls(
            mocks.adLoader,
            .loadFullscreenAd,
            parameters: [
                XCTMethodCaptureParameter { requestA = $0 },
                XCTMethodCaptureParameter { completion = $0 }
            ]
        )
        queue.stop()

        // The first load request needs to complete before another can be sent.
        let result = FullscreenAdLoadResult(
            ad: .test(),
            error: nil,
            loadID: "loadid",
            metrics: nil,
            winningBidInfo: nil
        )
        if let completion {
            completion(result)
        }

        // When started, the queue will resume filling itself and send another load request.
        queue.start()
        // We need a second load request but can reuse the completion variable from earlier.
        var requestB: FullscreenAdLoadRequest?
        XCTAssertMethodCalls(
            mocks.adLoader,
            .loadFullscreenAd,
            parameters: [
                XCTMethodCaptureParameter { requestB = $0 },
                XCTMethodCaptureParameter { completion = $0 }
            ]
        )
        if let completion {
            completion(result)
        }

        // Unwrap optionals, fail if either ID was nil.
        let idA = try XCTUnwrap(requestA?.queueID, "Request from first queue run was nil")
        let idB = try XCTUnwrap(requestB?.queueID, "Request from first queue run was nil")

        // Make sure the queue ID wasn't reused after stopping and restarting.
        XCTAssertNotEqual(idA, idB)
        // Also check that neither ID is an empty string because that's a plausable
        // bug that would make this test pass for the wrong reason.
        XCTAssertNotEqual(idA, "")
        XCTAssertNotEqual(idB, "")
    }

    /// When a new queue is created, its capacity cannot be higher than maxQueueSize.
    /// Because .setQueueCapacity is unavailable during init, this checks different
    /// code than testSetQueueCapacityEnforcesMaxQueueSize.
    func testMaxQueueSizeOverridesPlacementSettingOnInit() throws {
        mocks.fullscreenAdQueueConfiguration.maxQueueSize = 3
        mocks.fullscreenAdQueueConfiguration.setReturnValue(4, for: .queueSize)
        // maxQueueSize should take precedence.
        XCTAssertEqual(queue.queueCapacity, 3)
    }

    /// A publisher cannot set queueCapacity higher than maxQueueSize.
    func testSetQueueCapacityEnforcesMaxQueueSize() throws {
        mocks.fullscreenAdQueueConfiguration.maxQueueSize = 3
        queue.setQueueCapacity(4)
        // maxQueueSize should take precedence.
        XCTAssertEqual(queue.queueCapacity, 3)
    }

    /// The queue stops loading ads when full.
    func testRunningQueueStopsLoadingWhenFull() throws {
        // Make queueCapacity just two ads so it's easy to fill up.
        mocks.fullscreenAdQueueConfiguration.maxQueueSize = 2
        mocks.fullscreenAdQueueConfiguration.setReturnValue(2, for: .queueSize)
        queue.start()
        // Respond to calls that were sent to the AdLoader mock.
        try simulateSuccessfulAdLoad()
        try simulateSuccessfulAdLoad()

        // If an error elsewhere causes this to be false then our test would not be valid.
        XCTAssertEqual(queue.numberOfAdsReady, queue.queueCapacity)
        // At this point, the queue should still be running but it should not load more ads.
        XCTAssertTrue(queue.isRunning)
        XCTAssertNoMethodCall(mocks.adLoader, to: .loadFullscreenAd)
    }

    /// A running queue tops itself off when an ad expires.
    func testRunningQueueRefillsWhenAdExpires() throws {
        // This test requires the queue to be full when the ad expires because if it's not full
        // then it would be trying to load another ad already. So let it be full with just one ad.
        mocks.fullscreenAdQueueConfiguration.setReturnValue(1, for: .queueSize)
        queue.start()
        // Respond to call that was sent to the AdLoader mock.
        try simulateSuccessfulAdLoad()
        // We expect that there was not a second call to .loadFullscreenAd.
        XCTAssertNoMethodCall(mocks.adLoader, to: .loadFullscreenAd)
        // Now cause the expiration timer to fire.
        mocks.taskDispatcher.performDelayedWorkItems()
        // Triggering the expiration task should have removed the ad from the queue,
        // causing the queue to request a new ad to replace it.
        XCTAssertMethodCallCount(mocks.adLoader, .loadFullscreenAd, calls: 1)
    }

    /// A stopped queue does not try to replace expired ads.
    func testStoppedQueueDoesNotRefillWhenAdExpires() throws {
        // This test requires the queue to be full when the ad expires,
        // so let it be full with just one ad.
        mocks.fullscreenAdQueueConfiguration.setReturnValue(1, for: .queueSize)
        queue.start()
        // Respond to call that was sent to the AdLoader mock.
        try simulateSuccessfulAdLoad()
        queue.stop()
        // Now cause the expiration timer to fire.
        mocks.taskDispatcher.performDelayedWorkItems()
        // Confirm that the expired ad has been removed.
        XCTAssertEqual(queue.numberOfAdsReady, 0)
        // There should be no attempt to load a replacement ad.
        XCTAssertNoMethodCall(mocks.adLoader, to: .loadFullscreenAd)
    }

    /// Validates that a partner ad expiration is properly handled for queued ads.
    func testAdExpirationByPartner() throws {
        // Setup: start queue and have a loaded ad in the queue
        queue.start()
        let (ad, controller) = try simulateSuccessfulAdLoad()
        queue.delegate = delegate

        // Simulate a partner expiration event on the ad
        ad.delegate?.didExpire?(ad: ad)

        // Confirm that the expired ad has been removed.
        XCTAssertEqual(queue.numberOfAdsReady, 0)
        // Confirm that the ad is not forced to be expired again through the controller, since this path has already been taken
        // care of by the partner controller
        XCTAssertNoMethodCalls(controller)
        // Confirm that queue delegate methods have been called
        XCTAssertMethodCalls(delegate, .fullscreenAdQueueDidRemoveExpiredAd, parameters: [queue, XCTMethodIgnoredParameter()])
    }

    /// Validates that on timeout a queued ad is expired.
    func testAdExpirationByQueueTimeout() throws {
        // Setup: start queue and have a loaded ad in the queue
        queue.start()
        let (ad, controller) = try simulateSuccessfulAdLoad()
        queue.delegate = delegate

        // Now cause the expiration timer to fire.
        mocks.taskDispatcher.performDelayedWorkItems()

        // Confirm that the expired ad has been removed.
        XCTAssertEqual(queue.numberOfAdsReady, 0)
        // Confirm that the ad is forced to be expired through the controller, triggering metrics logging
        XCTAssertMethodCalls(controller, .forceInternalExpiration, parameters: [])
        // Confirm that queue delegate methods have been called
        XCTAssertMethodCalls(delegate, .fullscreenAdQueueDidRemoveExpiredAd, parameters: [queue, XCTMethodIgnoredParameter()])

        // Simulate a partner expiration event on the ad
        ad.delegate?.didExpire?(ad: ad)

        // Confirm that nothing happens since the ad has already been expired
        XCTAssertNoMethodCalls(controller)
        XCTAssertNoMethodCalls(delegate)
    }

    // MARK: Helpers
    /// Grabs the most recent request that was sent to mocks.adLoader.loadFullscreenAd and gives the
    /// completion a ChartboostMediationFullscreenAdMock with the load id "loadid" and no metrics.
    /// NOTE THAT IT CALLS XCTAssertMethodCalls, WHICH REMOVES ALL RECORDS FROM THE MOCK
    @discardableResult
    func simulateSuccessfulAdLoad() throws -> (FullscreenAd, AdControllerMock) {
        var completion: ((FullscreenAdLoadResult) -> Void)?
        XCTAssertMethodCalls(
            mocks.adLoader,
            .loadFullscreenAd,
            parameters: [
                XCTMethodIgnoredParameter() ,
                XCTMethodCaptureParameter { completion = $0 }
            ]
        )
        let controller = AdControllerMock()
        let ad = FullscreenAd.test(controller: controller)
        let result = FullscreenAdLoadResult(
            ad: ad,
            error: nil,
            loadID: "loadid",
            metrics: nil,
            winningBidInfo: nil
        )
        let unwrappedCompletion = try XCTUnwrap(completion)
        unwrappedCompletion(result)
        return (ad, controller)
    }
}
