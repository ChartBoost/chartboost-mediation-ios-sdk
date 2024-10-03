// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import Foundation
import XCTest

class BannerSwapControllerTests: ChartboostMediationTestCase {

    lazy var bannerSwapController = BannerSwapController()

    let viewController = UIViewController()

    override func setUp() {
        super.setUp()

        bannerSwapController.delegate = mocks.bannerSwapControllerDelegate
    }

    override func tearDown() {
        // Remove all records to clear any calls and controllers that might be left over after
        // running a test.
        mocks.adFactory.removeAllRecords()
    }

    // MARK: - Properties
    func testPassesInitialKeywords() throws {
        let keywords = ["test": "keywords"]
        bannerSwapController.keywords = keywords
        bannerSwapController.loadAd(request: .test(), viewController: viewController) { result in }
        let controller = try assertCreatesController()
        XCTAssertEqual(controller.keywords, keywords)
    }

    func testPassesKeywordsWithActiveController() throws {
        bannerSwapController.loadAd(request: .test(), viewController: viewController) { result in }
        let controller = try assertCreatesController()
        let completion = try assertLoad(controller: controller)
        completion(.testSuccess())

        let keywords = ["test": "keywords"]
        bannerSwapController.keywords = keywords
        XCTAssertEqual(controller.keywords, keywords)
    }

    func testPassesKeywordsWithSwappingController() throws {
        let requestA = BannerAdLoadRequest.test(placement: "placementA")
        bannerSwapController.loadAd(request: requestA, viewController: viewController) { result in }
        let controllerA = try assertCreatesController()
        let completionA = try assertLoad(controller: controllerA)
        completionA(.testSuccess())

        let requestB = BannerAdLoadRequest.test(placement: "placementB")
        bannerSwapController.loadAd(request: requestB, viewController: viewController) { result in }
        let controllerB = try assertCreatesController()
        try assertLoad(controller: controllerB)
        // Keep controllerB loading so we are in the swapping state.

        let keywords = ["test": "keywords"]
        bannerSwapController.keywords = keywords
        XCTAssertEqual(controllerA.keywords, keywords)
        XCTAssertEqual(controllerB.keywords, keywords)
    }

    func testDoesNotPassKeywordsWhenControllerHasBeenCleared() throws {
        bannerSwapController.loadAd(request: .test(), viewController: viewController) { result in }
        let controller = try assertCreatesController()
        let completion = try assertLoad(controller: controller)
        completion(.testSuccess())

        let oldKeywords = ["test": "keywords"]
        bannerSwapController.keywords = oldKeywords
        XCTAssertEqual(controller.keywords, oldKeywords)

        bannerSwapController.clearAd()

        // The controller should have been cleared, so the underlying controller should still have
        // the old keywords.
        let newKeywords = ["test2": "keywords2"]
        bannerSwapController.keywords = newKeywords
        XCTAssertEqual(controller.keywords, oldKeywords)
    }

    func testRequestWithActiveController() throws {
        let request = BannerAdLoadRequest.test()
        bannerSwapController.loadAd(request: request, viewController: viewController) { result in }
        let controller = try assertCreatesController()
        let completion = try assertLoad(controller: controller)
        completion(.testSuccess())

        XCTAssertEqual(controller.request, request)
        XCTAssertEqual(bannerSwapController.request, request)
    }

    func testRequestWithSwappingController() throws {
        let requestA = BannerAdLoadRequest.test(placement: "placementA")
        bannerSwapController.loadAd(request: requestA, viewController: viewController) { result in }
        let controllerA = try assertCreatesController()
        let completionA = try assertLoad(controller: controllerA)
        completionA(.testSuccess())

        let requestB = BannerAdLoadRequest.test(placement: "placementB")
        bannerSwapController.loadAd(request: requestB, viewController: viewController) { result in }
        let controllerB = try assertCreatesController()
        let completionB = try assertLoad(controller: controllerB)

        // Keep controllerB loading so we are in the swapping state.

        XCTAssertEqual(bannerSwapController.request, requestA)
        XCTAssertNotEqual(bannerSwapController.request, requestB)

        // Complete controllerB to complete the swap.
        completionB(.testSuccess())

        XCTAssertNotEqual(bannerSwapController.request, requestA)
        XCTAssertEqual(bannerSwapController.request, requestB)
    }

    func testRequestsWhenControllerHasBeenCleared() throws {
        let request = BannerAdLoadRequest.test()
        bannerSwapController.loadAd(request: request, viewController: viewController) { result in }
        let controller = try assertCreatesController()
        let completion = try assertLoad(controller: controller)
        completion(.testSuccess())

        XCTAssertEqual(controller.request, request)
        XCTAssertEqual(bannerSwapController.request, request)

        bannerSwapController.clearAd()

        XCTAssertNil(bannerSwapController.request)
    }

    func testShowingBannerAdLoadResultIsNilWhileLoading() throws {
        let request = BannerAdLoadRequest.test()
        bannerSwapController.loadAd(request: request, viewController: viewController) { result in }
        let controller = try assertCreatesController()
        try assertLoad(controller: controller)

        XCTAssertNil(bannerSwapController.showingBannerAdLoadResult)
    }

    func testShowingBannerAdLoadResultWithActiveController() throws {
        let request = BannerAdLoadRequest.test()
        bannerSwapController.loadAd(request: request, viewController: viewController) { result in }
        let controller = try assertCreatesController()
        let completion = try assertLoad(controller: controller)

        let result = InternalAdLoadResult(result: .success(.test()), metrics: nil)
        controller.showingBannerAdLoadResult = result
        completion(.testSuccess())

        XCTAssertAnyEqual(bannerSwapController.showingBannerAdLoadResult, result)
    }

    func testShowingBannerAdLoadResultWhenSwappingControllers() throws {
        let requestA = BannerAdLoadRequest.test(placement: "placementA")
        bannerSwapController.loadAd(request: requestA, viewController: viewController) { result in }
        let controllerA = try assertCreatesController()
        let completionA = try assertLoad(controller: controllerA)

        let resultA = InternalAdLoadResult(result: .success(.test(request: .test(loadID: "loadA"))), metrics: nil)
        controllerA.showingBannerAdLoadResult = resultA
        completionA(.testSuccess())

        let requestB = BannerAdLoadRequest.test(placement: "placementB")
        bannerSwapController.loadAd(request: requestB, viewController: viewController) { result in }
        let controllerB = try assertCreatesController()
        let completionB = try assertLoad(controller: controllerB)

        let resultB = InternalAdLoadResult(result: .success(.test(request: .test(loadID: "loadB"))), metrics: nil)
        controllerB.showingBannerAdLoadResult = resultB

        // Keep controllerB loading so we are in the swapping state.
        XCTAssertAnyEqual(bannerSwapController.showingBannerAdLoadResult, resultA)
        XCTAssertAnyNotEqual(bannerSwapController.showingBannerAdLoadResult, resultB)

        // Complete controllerB to complete the swap.
        completionB(.testSuccess())

        XCTAssertAnyNotEqual(bannerSwapController.showingBannerAdLoadResult, resultA)
        XCTAssertAnyEqual(bannerSwapController.showingBannerAdLoadResult, resultB)
    }

    func testShowingBannerAdLoadResultWhenControllerHasBeenCleared() throws {
        let request = BannerAdLoadRequest.test()
        bannerSwapController.loadAd(request: request, viewController: viewController) { result in }
        let controller = try assertCreatesController()
        let completion = try assertLoad(controller: controller)

        let result = InternalAdLoadResult(result: .success(.test()), metrics: nil)
        controller.showingBannerAdLoadResult = result
        completion(.testSuccess())

        XCTAssertAnyEqual(bannerSwapController.showingBannerAdLoadResult, result)

        bannerSwapController.clearAd()

        XCTAssertNil(bannerSwapController.showingBannerAdLoadResult)
    }

    // MARK: - Load
    func testLoadFromClear() throws {
        let request = BannerAdLoadRequest.test()
        let expectedResult = BannerAdLoadResult.testSuccess()
        let loadExpectation = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: request, viewController: viewController) { result in
            XCTAssertEqual(expectedResult, result)
            loadExpectation.fulfill()
        }
        let controller = try assertCreatesController()
        let completion = try assertLoad(controller: controller)
        completion(expectedResult)
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(bannerSwapController.request, request)
    }

    func testLoadFromClearToError() throws {
        let request = BannerAdLoadRequest.test()
        let expectedResult = BannerAdLoadResult.testFailure()
        let loadExpectation = expectation(description: "Failed load")
        bannerSwapController.loadAd(request: request, viewController: viewController) { result in
            XCTAssertEqual(expectedResult, result)
            loadExpectation.fulfill()
        }
        let controller = try assertCreatesController()
        let completion = try assertLoad(controller: controller)
        completion(expectedResult)
        waitForExpectations(timeout: 1.0)

        // When loading from clear, if there's an error, we will still set the controller as the
        // active controller.
        XCTAssertNoMethodCalls(controller)
        XCTAssertEqual(bannerSwapController.request, request)
    }

    func testLoadFromClearIfClearIsCalledBeforeLoadCompletes() throws {
        let request = BannerAdLoadRequest.test()
        let expectedResult = BannerAdLoadResult.testFailure()
        let loadExpectation = expectation(description: "Completion should not be called")
        loadExpectation.isInverted = true
        bannerSwapController.loadAd(request: request, viewController: viewController) { result in
            loadExpectation.fulfill()
        }
        let controller = try assertCreatesController()
        let completion = try assertLoad(controller: controller)

        // Clear before the load has completed.
        bannerSwapController.clearAd()
        XCTAssertMethodCalls(controller, .clearAd, parameters: [])

        completion(expectedResult)
        waitForExpectations(timeout: 1.0)

        XCTAssertNil(bannerSwapController.request)
    }

    func testLoadWhileActive() throws {
        let request = BannerAdLoadRequest.test()
        let expectedResult = BannerAdLoadResult.testSuccess()
        var loadExpectation = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: request, viewController: viewController) { result in
            XCTAssertEqual(expectedResult, result)
            loadExpectation.fulfill()
        }
        let controller = try assertCreatesController()
        var completion = try assertLoad(controller: controller)
        completion(expectedResult)
        waitForExpectations(timeout: 1.0)

        // Second load after the controller is made active.
        loadExpectation = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: request, viewController: viewController) { result in
            XCTAssertEqual(expectedResult, result)
            loadExpectation.fulfill()
        }
        // Controller is active so no calls should be made to create a new controller.
        XCTAssertNoMethodCalls(mocks.adFactory)
        completion = try assertLoad(controller: controller)
        completion(expectedResult)
        waitForExpectations(timeout: 1.0)
    }

    func testLoadWhileActiveIfSecondRequestFails() throws {
        let request = BannerAdLoadRequest.test()
        let expectedResult = BannerAdLoadResult.testSuccess()
        var loadExpectation = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: request, viewController: viewController) { result in
            XCTAssertEqual(expectedResult, result)
            loadExpectation.fulfill()
        }
        let controller = try assertCreatesController()
        var completion = try assertLoad(controller: controller)
        completion(expectedResult)
        waitForExpectations(timeout: 1.0)

        // Second load after the controller is made active.
        let expectedResult2 = BannerAdLoadResult.testSuccess()
        loadExpectation = expectation(description: "Failed load")
        bannerSwapController.loadAd(request: request, viewController: viewController) { result in
            XCTAssertEqual(expectedResult2, result)
            loadExpectation.fulfill()
        }
        // Controller is active so no calls should be made to create a new controller.
        XCTAssertNoMethodCalls(mocks.adFactory)
        completion = try assertLoad(controller: controller)
        completion(expectedResult2)
        waitForExpectations(timeout: 1.0)
    }

    func testLoadSwap() throws {
        let requestA = BannerAdLoadRequest.test(placement: "placementA")
        let expectedResultA = BannerAdLoadResult.testSuccess()
        let loadExpectationA = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: requestA, viewController: viewController) { result in
            XCTAssertEqual(expectedResultA, result)
            loadExpectationA.fulfill()
        }
        let controllerA = try assertCreatesController()
        let completionA = try assertLoad(controller: controllerA)
        completionA(expectedResultA)
        waitForExpectations(timeout: 1.0)

        XCTAssertFalse(controllerA.isPaused)

        let requestB = BannerAdLoadRequest.test(placement: "placementB")
        let expectedResultB = BannerAdLoadResult.testSuccess()
        let loadExpectationB = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: requestB, viewController: viewController) { result in
            XCTAssertEqual(expectedResultB, result)
            loadExpectationB.fulfill()
        }
        let controllerB = try assertCreatesController()
        let completionB = try assertLoad(controller: controllerB)

        // Controller A should be paused while B is loading.
        XCTAssertTrue(controllerA.isPaused)

        completionB(expectedResultB)
        waitForExpectations(timeout: 1.0)

        // Since B succeeds in loading, we will clear controller A.
        XCTAssertMethodCalls(controllerA, .clearAd, parameters: [])
        XCTAssertNoMethodCalls(controllerB)

        // Ensure the swap is completed.
        XCTAssertEqual(bannerSwapController.request, requestB)
    }

    func testLoadSwapError() throws {
        let requestA = BannerAdLoadRequest.test(placement: "placementA")
        let expectedResultA = BannerAdLoadResult.testSuccess()
        let loadExpectationA = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: requestA, viewController: viewController) { result in
            XCTAssertEqual(expectedResultA, result)
            loadExpectationA.fulfill()
        }
        let controllerA = try assertCreatesController()
        let completionA = try assertLoad(controller: controllerA)
        completionA(expectedResultA)
        waitForExpectations(timeout: 1.0)

        XCTAssertFalse(controllerA.isPaused)

        let requestB = BannerAdLoadRequest.test(placement: "placementB")
        let expectedResultB = BannerAdLoadResult.testFailure()
        let loadExpectationB = expectation(description: "Failed load")
        bannerSwapController.loadAd(request: requestB, viewController: viewController) { result in
            XCTAssertEqual(expectedResultB, result)
            loadExpectationB.fulfill()
        }
        let controllerB = try assertCreatesController()
        let completionB = try assertLoad(controller: controllerB)

        // Controller A should be paused while B is loading.
        XCTAssertTrue(controllerA.isPaused)

        completionB(expectedResultB)
        waitForExpectations(timeout: 1.0)

        // We revert back to controller A when controller B fails.
        XCTAssertFalse(controllerA.isPaused)
        XCTAssertNoMethodCalls(controllerA)
        XCTAssertMethodCalls(controllerB, .clearAd, parameters: [])

        // Ensure we don't set the failed controller as active.
        XCTAssertEqual(bannerSwapController.request, requestA)
    }

    func testLoadWhenSwappingIfRequestForActiveControllerIsLoaded() throws {
        let requestA = BannerAdLoadRequest.test(placement: "placementA")
        let expectedResultA = BannerAdLoadResult.testSuccess()
        var loadExpectationA = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: requestA, viewController: viewController) { result in
            XCTAssertEqual(expectedResultA, result)
            loadExpectationA.fulfill()
        }
        let controllerA = try assertCreatesController()
        var completionA = try assertLoad(controller: controllerA)
        completionA(expectedResultA)
        waitForExpectations(timeout: 1.0)

        // Load to placement B after the controller is in the active state.
        let requestB = BannerAdLoadRequest.test(placement: "placementB")
        let loadExpectationB = expectation(description: "Completion should not be called")
        loadExpectationB.isInverted = true
        bannerSwapController.loadAd(request: requestB, viewController: viewController) { result in
            loadExpectationB.fulfill()
        }
        let controllerB = try assertCreatesController()
        let completionB = try assertLoad(controller: controllerB)

        // Controller A should be paused while B is loading.
        XCTAssertTrue(controllerA.isPaused)

        // Do not finish the load on controller B.
        // Instead, load placement A again.
        loadExpectationA = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: requestA, viewController: viewController) { result in
            XCTAssertEqual(expectedResultA, result)
            loadExpectationA.fulfill()
        }
        // The controller is active so it should not create another controller.
        XCTAssertNoMethodCalls(mocks.adFactory)
        // However controller A should be loaded again.
        completionA = try assertLoad(controller: controllerA)

        // We revert back to controller A.
        XCTAssertFalse(controllerA.isPaused)
        XCTAssertNoMethodCalls(controllerA)
        XCTAssertMethodCalls(controllerB, .clearAd, parameters: [])

        // Complete B then A. Completion B should not be called, but completion A should be called.
        completionB(.testSuccess())
        completionA(expectedResultA)

        waitForExpectations(timeout: 1.0)

        // Ensure the request is correct.
        XCTAssertEqual(bannerSwapController.request, requestA)
    }

    func testLoadWhenSwappingIfRequestForPendingControllerIsLoadedAgain() throws {
        let requestA = BannerAdLoadRequest.test(placement: "placementA")
        let expectedResultA = BannerAdLoadResult.testSuccess()
        let loadExpectationA = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: requestA, viewController: viewController) { result in
            XCTAssertEqual(expectedResultA, result)
            loadExpectationA.fulfill()
        }
        let controllerA = try assertCreatesController()
        let completionA = try assertLoad(controller: controllerA)
        completionA(expectedResultA)
        waitForExpectations(timeout: 1.0)

        // Load to placement B after the controller is in the active state.
        let requestB = BannerAdLoadRequest.test(placement: "placementB")
        let expectedResultB = BannerAdLoadResult.testSuccess()
        // This completion will be replaced, so it should not be called.
        let loadExpectationB1 = expectation(description: "Completion should not be called")
        loadExpectationB1.isInverted = true
        bannerSwapController.loadAd(request: requestB, viewController: viewController) { result in
            loadExpectationB1.fulfill()
        }
        let controllerB = try assertCreatesController()
        let completionB = try assertLoad(controller: controllerB)

        // Second load for placement B. The completion block should be updated.
        let loadExpectationB2 = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: requestB, viewController: viewController) { result in
            XCTAssertEqual(expectedResultB, result)
            loadExpectationB2.fulfill()
        }
        // Another controller should not be created.
        XCTAssertNoMethodCalls(mocks.adFactory)
        // No call to load should be made on the underlying controller.
        XCTAssertNoMethodCalls(controllerA)
        XCTAssertNoMethodCalls(controllerB)

        completionB(expectedResultB)

        waitForExpectations(timeout: 1.0)

        // Ensure the swap completed.
        XCTAssertMethodCalls(controllerA, .clearAd, parameters: [])
        XCTAssertEqual(bannerSwapController.request, requestB)
    }

    func testLoadWhenSwappingIfThirdRequestIsLoaded() throws {
        let requestA = BannerAdLoadRequest.test(placement: "placementA")
        let expectedResultA = BannerAdLoadResult.testSuccess()
        let loadExpectationA = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: requestA, viewController: viewController) { result in
            XCTAssertEqual(expectedResultA, result)
            loadExpectationA.fulfill()
        }
        let controllerA = try assertCreatesController()
        let completionA = try assertLoad(controller: controllerA)
        completionA(expectedResultA)
        waitForExpectations(timeout: 1.0)

        XCTAssertFalse(controllerA.isPaused)

        // Load to placement B after the controller is in the active state.
        let requestB = BannerAdLoadRequest.test(placement: "placementB")
        // This controller will be replaced, so the completion should not be called.
        let loadExpectationB = expectation(description: "Completion should not be called")
        loadExpectationB.isInverted = true
        bannerSwapController.loadAd(request: requestB, viewController: viewController) { result in
            loadExpectationB.fulfill()
        }
        let controllerB = try assertCreatesController()
        let completionB = try assertLoad(controller: controllerB)

        XCTAssertTrue(controllerA.isPaused)

        // Load request C while a request for B is ongoing.
        let requestC = BannerAdLoadRequest.test(placement: "placementC")
        let expectedResultC = BannerAdLoadResult.testSuccess()
        let loadExpectationC = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: requestC, viewController: viewController) { result in
            XCTAssertEqual(expectedResultC, result)
            loadExpectationC.fulfill()
        }
        let controllerC = try assertCreatesController()
        let completionC = try assertLoad(controller: controllerC)

        // We should have called clearAd on controller B in this case.
        XCTAssertMethodCalls(controllerB, .clearAd, parameters: [])

        // Complete B then C. Completion B should not be called, but completion C should be called.
        completionB(.testSuccess())
        completionC(expectedResultC)

        waitForExpectations(timeout: 1.0)

        // Ensure the swap completed.
        XCTAssertMethodCalls(controllerA, .clearAd, parameters: [])
        XCTAssertEqual(bannerSwapController.request, requestC)
    }

    func testLoadWhenSwappingIfThirdRequestIsLoadedButFails() throws {
        let requestA = BannerAdLoadRequest.test(placement: "placementA")
        let expectedResultA = BannerAdLoadResult.testSuccess()
        let loadExpectationA = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: requestA, viewController: viewController) { result in
            XCTAssertEqual(expectedResultA, result)
            loadExpectationA.fulfill()
        }
        let controllerA = try assertCreatesController()
        let completionA = try assertLoad(controller: controllerA)
        completionA(expectedResultA)
        waitForExpectations(timeout: 1.0)

        XCTAssertFalse(controllerA.isPaused)

        // Load to placement B after the controller is in the active state.
        let requestB = BannerAdLoadRequest.test(placement: "placementB")
        // This controller will be replaced, so the completion should not be called.
        let loadExpectationB = expectation(description: "Completion should not be called")
        loadExpectationB.isInverted = true
        bannerSwapController.loadAd(request: requestB, viewController: viewController) { result in
            loadExpectationB.fulfill()
        }
        let controllerB = try assertCreatesController()
        let completionB = try assertLoad(controller: controllerB)

        XCTAssertTrue(controllerA.isPaused)

        // Load request C while a request for B is ongoing.
        let requestC = BannerAdLoadRequest.test(placement: "placementC")
        let expectedResultC = BannerAdLoadResult.testFailure()
        let loadExpectationC = expectation(description: "Failed load")
        bannerSwapController.loadAd(request: requestC, viewController: viewController) { result in
            XCTAssertEqual(expectedResultC, result)
            loadExpectationC.fulfill()
        }
        let controllerC = try assertCreatesController()
        let completionC = try assertLoad(controller: controllerC)

        // We should have called clearAd on controller B as soon as load for controller C was
        // called.
        XCTAssertMethodCalls(controllerB, .clearAd, parameters: [])

        // Complete B then C. Completion B should not be called, but completion C should be called.
        completionB(.testSuccess())
        completionC(expectedResultC)

        waitForExpectations(timeout: 1.0)

        // We revert back to controller A when controller C fails.
        XCTAssertFalse(controllerA.isPaused)
        XCTAssertMethodCalls(controllerC, .clearAd, parameters: [])

        // Ensure we don't set the failed controller as active.
        XCTAssertEqual(bannerSwapController.request, requestA)
    }

    // MARK: - Clear
    func testClearWhenActive() throws {
        let request = BannerAdLoadRequest.test()
        let expectedResult = BannerAdLoadResult.testSuccess()
        let loadExpectation = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: request, viewController: viewController) { result in
            XCTAssertEqual(expectedResult, result)
            loadExpectation.fulfill()
        }
        let controller = try assertCreatesController()
        let completion = try assertLoad(controller: controller)
        completion(expectedResult)
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(bannerSwapController.request, request)

        bannerSwapController.clearAd()
        XCTAssertMethodCalls(controller, .clearAd, parameters: [])

        XCTAssertNil(bannerSwapController.request)
    }

    func testClearWhenSwapping() throws {
        let requestA = BannerAdLoadRequest.test(placement: "placementA")
        let expectedResultA = BannerAdLoadResult.testSuccess()
        let loadExpectationA = expectation(description: "Successful load")
        bannerSwapController.loadAd(request: requestA, viewController: viewController) { result in
            XCTAssertEqual(expectedResultA, result)
            loadExpectationA.fulfill()
        }
        let controllerA = try assertCreatesController()
        let completionA = try assertLoad(controller: controllerA)
        completionA(expectedResultA)
        waitForExpectations(timeout: 1.0)

        let requestB = BannerAdLoadRequest.test(placement: "placementB")
        let expectedResultB = BannerAdLoadResult.testSuccess()
        let loadExpectationB = expectation(description: "Completion should not be called")
        loadExpectationB.isInverted = true
        bannerSwapController.loadAd(request: requestB, viewController: viewController) { result in
            XCTAssertEqual(expectedResultB, result)
            loadExpectationB.fulfill()
        }
        let controllerB = try assertCreatesController()
        let completionB = try assertLoad(controller: controllerB)

        // Clear before swapping has completed.
        bannerSwapController.clearAd()

        XCTAssertMethodCalls(controllerA, .clearAd, parameters: [])
        XCTAssertMethodCalls(controllerB, .clearAd, parameters: [])

        // Complete B after the controller has been cleared
        completionB(expectedResultB)
        waitForExpectations(timeout: 1.0)

        // Ensure the request is correct.
        XCTAssertNil(bannerSwapController.request)
    }

    // MARK: - Delegate
    func testSetsDelegateOnLoad() throws {
        bannerSwapController.loadAd(request: .test(), viewController: viewController) { result in }
        let controller = try assertCreatesController()
        XCTAssertIdentical(controller.delegate, bannerSwapController)
    }

    func testPassesThroughDisplayBannerView() {
        let view = UIView()
        bannerSwapController.bannerController(mocks.bannerController, displayBannerView: view)
        XCTAssertMethodCalls(mocks.bannerSwapControllerDelegate, .bannerSwapControllerDisplayBannerView, parameters: [bannerSwapController, view])
    }

    func testPassesThroughClearBannerView() {
        let view = UIView()
        bannerSwapController.bannerController(mocks.bannerController, clearBannerView: view)
        XCTAssertMethodCalls(mocks.bannerSwapControllerDelegate, .bannerSwapControllerClearBannerView, parameters: [bannerSwapController, view])
    }

    func testPassesThroughDidRecordImpression() {
        bannerSwapController.bannerControllerDidRecordImpression(mocks.bannerController)
        XCTAssertMethodCalls(mocks.bannerSwapControllerDelegate, .bannerSwapControllerDidRecordImpression, parameters: [bannerSwapController])
    }

    func testPassesThroughDidClick() {
        bannerSwapController.bannerControllerDidClick(mocks.bannerController)
        XCTAssertMethodCalls(mocks.bannerSwapControllerDelegate, .bannerSwapControllerDidClick, parameters: [bannerSwapController])
    }
}

extension BannerSwapControllerTests {

    /// Call to assert that the `BannerSwapController` created a new `BannerController` via the ad factory.
    ///
    /// - Returns: The banner controller that was created.
    /// - Throws: An error if a controller was not created.
    @discardableResult
    private func assertCreatesController() throws -> BannerControllerProtocolMock {
        // Since the `BannerSwapController` handles multiple `BannerController` instances at a time,
        // we need some way to keep track of the different instances of the underlying controllers
        // when testing. In order to do that we set a new instance as the return value after each
        // read of such value.
        // We also configure each controller instance by setting its properties to the values requested
        // by the `BannerSwapController`, so we can compare with the expected values on each test.
        let controller = try XCTUnwrap(mocks.adFactory.returnValue(for: .makeBannerController) as BannerControllerProtocolMock)
        var request: BannerAdLoadRequest?
        var delegate: BannerControllerDelegate?
        var keywords: [String: String]?
        var partnerSettings: [String: Any]?
        XCTAssertMethodCalls(mocks.adFactory, .makeBannerController, parameters: [
            XCTMethodCaptureParameter { request = $0 },
            XCTMethodCaptureParameter { delegate = $0 },
            XCTMethodCaptureParameter { keywords = $0 },
            XCTMethodCaptureParameter { partnerSettings = $0 }
        ])
        controller.request = try XCTUnwrap(request)
        controller.delegate = delegate
        controller.keywords = keywords
        controller.partnerSettings = partnerSettings
        // Set a new return value so multiple calls result in different instances being returned.
        mocks.adFactory.setReturnValue(BannerControllerProtocolMock(), for: .makeBannerController)
        // Return the value
        return controller
    }

    /// Call to assert that `load` was called on `controller`.
    /// - Parameter controller: The `BannerControllerMock` to ensure that load was called on.
    /// - Parameter viewVisibility: The view and visibility state that are expected to be set on the underlying
    ///   `BannerController`, or nil if the call is expected to not be made.
    /// - Returns: The completion block to call to mock the completion from `BannerController`.
    @discardableResult
    private func assertLoad(
        controller: BannerControllerProtocolMock,
        viewVisibility: Bool? = nil
    ) throws -> ((BannerAdLoadResult) -> Void) {
        var result: ((BannerAdLoadResult) -> Void)?

        let captureExpectation = expectation(description: "Capture completion block")
        XCTAssertMethodCallsContains(
            controller,
            .loadAd,
            parameters: [
                viewController,
                XCTMethodCaptureParameter { (completion: @escaping (BannerAdLoadResult) -> Void) in
                    result = completion
                    captureExpectation.fulfill()
                }
            ]
        )

        wait(for: [captureExpectation], timeout: 1.0)

        controller.removeAllRecords()

        return try XCTUnwrap(result)
    }
}
