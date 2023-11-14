// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

// Test placements
fileprivate extension String {
    static let a = "PlacementNameA"
    static let b = "PlacementNameB"
    static let c = "PlacementNameC"
    static let d = "PlacementNameD"
}

class LoadRateLimiterTests: ChartboostMediationTestCase {
    
    let loadRateLimiter = LoadRateLimiter()
    
    func testFundamentals() throws {
        XCTAssertEqual(0, loadRateLimiter.timeUntilNextLoadIsAllowed(placement: .a))

        XCTAssertEqual(0, loadRateLimiter.loadRateLimit(placement: .a))

        let positivelimit = TimeInterval.random(in: 1...10)

        loadRateLimiter.setLoadRateLimit(positivelimit, placement: .a)
        XCTAssertEqual(positivelimit, loadRateLimiter.loadRateLimit(placement: .a))

        loadRateLimiter.setLoadRateLimit(0, placement: .a)
        XCTAssertEqual(0, loadRateLimiter.loadRateLimit(placement: .a))

        loadRateLimiter.setLoadRateLimit(positivelimit, placement: .a)
        loadRateLimiter.setLoadRateLimit(666, placement: .a)
        XCTAssertEqual(666, loadRateLimiter.loadRateLimit(placement: .a))

        let negativelimit = -TimeInterval.random(in: 1...10)

        loadRateLimiter.setLoadRateLimit(negativelimit, placement: .a)
        XCTAssertEqual(0, loadRateLimiter.loadRateLimit(placement: .a))
    }

    func testCollisions() throws {
        // add two placements with different names

        let positivelimit1 = TimeInterval.random(in: 1...10)

        loadRateLimiter.setLoadRateLimit(positivelimit1, placement: .a)
        XCTAssertEqual(positivelimit1, loadRateLimiter.loadRateLimit(placement: .a))

        let positivelimit2 = TimeInterval.random(in: 1...10)

        loadRateLimiter.setLoadRateLimit(positivelimit2, placement: .b)
        XCTAssertEqual(positivelimit2, loadRateLimiter.loadRateLimit(placement: .b))
        XCTAssertEqual(positivelimit1, loadRateLimiter.loadRateLimit(placement: .a))
        XCTAssertEqual(positivelimit2, loadRateLimiter.loadRateLimit(placement: .b))

        // add another placement with same name but lowercased

        let positivelimit3 = TimeInterval.random(in: 1...10)

        loadRateLimiter.setLoadRateLimit(positivelimit3, placement: .a.lowercased())
        XCTAssertEqual(positivelimit1, loadRateLimiter.loadRateLimit(placement: .a))
        XCTAssertEqual(positivelimit2, loadRateLimiter.loadRateLimit(placement: .b))
        XCTAssertEqual(positivelimit3, loadRateLimiter.loadRateLimit(placement: .a.lowercased()))

        // zero them out, one by one

        loadRateLimiter.setLoadRateLimit(0, placement: .a)
        XCTAssertEqual(0, loadRateLimiter.loadRateLimit(placement: .a))
        XCTAssertEqual(positivelimit2, loadRateLimiter.loadRateLimit(placement: .b))
        XCTAssertEqual(positivelimit3, loadRateLimiter.loadRateLimit(placement: .a.lowercased()))

        loadRateLimiter.setLoadRateLimit(0, placement: .b)
        XCTAssertEqual(0, loadRateLimiter.loadRateLimit(placement: .a))
        XCTAssertEqual(0, loadRateLimiter.loadRateLimit(placement: .b))
        XCTAssertEqual(positivelimit3, loadRateLimiter.loadRateLimit(placement: .a.lowercased()))

        loadRateLimiter.setLoadRateLimit(0, placement: .a.lowercased())
        XCTAssertEqual(0, loadRateLimiter.loadRateLimit(placement: .a))
        XCTAssertEqual(0, loadRateLimiter.loadRateLimit(placement: .b))
        XCTAssertEqual(0, loadRateLimiter.loadRateLimit(placement: .a.lowercased()))
    }

    func testTimeUntilNextLoadIsAllowed() throws {
        loadRateLimiter.setLoadRateLimit(0, placement: .a)
        XCTAssertEqual(0, loadRateLimiter.timeUntilNextLoadIsAllowed(placement: .a))
        
        let startDate1 = Date()
        loadRateLimiter.setLoadRateLimit(5, placement: .a)
        wait(duration: 1)   // actual wait time is unpredictable, that's why we record start and end dates
        let waitTime1 = abs(startDate1.timeIntervalSinceNow)
        let expectedRemainingTime1 = 5 - waitTime1
        XCTAssertLessThanOrEqual(abs(loadRateLimiter.timeUntilNextLoadIsAllowed(placement: .a) - expectedRemainingTime1), 0.5)   // 0.5 as margin of error
        
        let startDate2 = Date()
        wait(duration: 1)
        let waitTime2 = abs(startDate2.timeIntervalSinceNow)
        let expectedRemainingTime2 = expectedRemainingTime1 - waitTime2
        XCTAssertLessThanOrEqual(abs(loadRateLimiter.timeUntilNextLoadIsAllowed(placement: .a) - expectedRemainingTime2), 0.5)   // 0.5 as margin of error
        
        wait(duration: 4)
        XCTAssertEqual(0, loadRateLimiter.timeUntilNextLoadIsAllowed(placement: .a))
    }

    func testThreadSafe() throws {
        let expectation = XCTestExpectation(description: "testThreadSafe")
        expectation.expectedFulfillmentCount = 3
        let queue1 = DispatchQueue(label: "1")
        let queue2 = DispatchQueue(label: "2")
        let queue3 = DispatchQueue(label: "3")

        let positivelimit1 = TimeInterval.random(in: 1...10)
        let positivelimit2 = TimeInterval.random(in: 1...10)
        let positivelimit3 = TimeInterval.random(in: 1...10)
        let positivelimit4 = TimeInterval.random(in: 1...10)

        queue1.async {
            self.loadRateLimiter.setLoadRateLimit(positivelimit1, placement: .a)
            expectation.fulfill()
        }

        queue2.async {
            self.loadRateLimiter.setLoadRateLimit(positivelimit3, placement: .c)
            self.loadRateLimiter.setLoadRateLimit(positivelimit4, placement: .d)
            expectation.fulfill()
        }

        queue3.async {
            self.loadRateLimiter.setLoadRateLimit(positivelimit2, placement: .b)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5)

        XCTAssertEqual(positivelimit1, loadRateLimiter.loadRateLimit(placement: .a))
        XCTAssertEqual(positivelimit2, loadRateLimiter.loadRateLimit(placement: .b))
        XCTAssertEqual(positivelimit3, loadRateLimiter.loadRateLimit(placement: .c))
        XCTAssertEqual(positivelimit4, loadRateLimiter.loadRateLimit(placement: .d))
    }
}
