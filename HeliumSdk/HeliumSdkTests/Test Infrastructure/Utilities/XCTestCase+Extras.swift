// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest

extension XCTestCase {
    /// Convience method for waiting for the specified amount of time.
    /// - Parameter timeout: the `TimerInterval` to wait before proceeding.
    func wait(duration: TimeInterval) {
        let expectation = XCTestExpectation(description: "wait for \(duration) seconds")
        expectation.isInverted = true
        wait(for: [expectation], timeout: duration)
    }
}
