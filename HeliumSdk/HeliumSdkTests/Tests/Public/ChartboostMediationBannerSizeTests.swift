// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import Foundation
import XCTest

class ChartboostMediationBannerSizeTests: HeliumTestCase {
    func testFixedBannerSizes() {
        var size: ChartboostMediationBannerSize = .standard
        XCTAssertEqual(size.size.width, 320.0)
        XCTAssertEqual(size.size.height, 50.0)
        XCTAssertEqual(size.type, .fixed)

        size = .medium
        XCTAssertEqual(size.size.width, 300.0)
        XCTAssertEqual(size.size.height, 250.0)
        XCTAssertEqual(size.type, .fixed)

        size = .leaderboard
        XCTAssertEqual(size.size.width, 728.0)
        XCTAssertEqual(size.size.height, 90.0)
        XCTAssertEqual(size.type, .fixed)
    }

    func testAdaptiveSize() {
        let size: ChartboostMediationBannerSize = .adaptive(width: 100.0)
        XCTAssertEqual(size.size.width, 100.0)
        XCTAssertEqual(size.size.height, 0.0)
        XCTAssertEqual(size.type, .adaptive)
    }

    func testAdaptiveSizeWithMaxHeight() {
        let size: ChartboostMediationBannerSize = .adaptive(width: 100.0, maxHeight: 50.0)
        XCTAssertEqual(size.size.width, 100.0)
        XCTAssertEqual(size.size.height, 50.0)
        XCTAssertEqual(size.type, .adaptive)
    }

    func testAspectRatioWhenSizeOrHeightIsZero() {
        var size: ChartboostMediationBannerSize = .adaptive(width: 0.0, maxHeight: 50.0)
        XCTAssertEqual(size.aspectRatio, 0.0)

        size = .adaptive(width: 100.0, maxHeight: 0.0)
        XCTAssertEqual(size.aspectRatio, 0.0)
    }

    func testAspectRatio() {
        var size: ChartboostMediationBannerSize = .adaptive(width: 100.0, maxHeight: 50.0)
        XCTAssertEqual(size.aspectRatio, 2.0, accuracy: Constants.accuracy)

        size = .adaptive(width: 50.0, maxHeight: 100.0)
        XCTAssertEqual(size.aspectRatio, 0.5, accuracy: Constants.accuracy)
    }

    func testIsValid() {
        // These should always be valid.
        XCTAssertTrue(ChartboostMediationBannerSize.standard.isValid)
        XCTAssertTrue(ChartboostMediationBannerSize.medium.isValid)
        XCTAssertTrue(ChartboostMediationBannerSize.leaderboard.isValid)

        var size: ChartboostMediationBannerSize = .adaptive(width: 200.0, maxHeight: 100.0)
        XCTAssertTrue(size.isValid)

        size = .adaptive(width: 50.0, maxHeight: 50.0)
        XCTAssertTrue(size.isValid)

        size = .adaptive(width: 1800.0, maxHeight: 1800.0)
        XCTAssertTrue(size.isValid)
    }

    func testIsValidWhenHeightIsZero() {
        var size: ChartboostMediationBannerSize = .adaptive(width: 100.0)
        XCTAssertTrue(size.isValid)

        size = .adaptive(width: 100.0, maxHeight: 1.0)
        XCTAssertFalse(size.isValid)
    }

    func testIsNotValidForInvalidSize() {
        var size: ChartboostMediationBannerSize = .adaptive(width: 100.0, maxHeight: 49.0)
        XCTAssertFalse(size.isValid)

        size = .adaptive(width: 100.0, maxHeight: 1801.0)
        XCTAssertFalse(size.isValid)

        size = .adaptive(width: 49.0, maxHeight: 100.0)
        XCTAssertFalse(size.isValid)

        size = .adaptive(width: 1801.0, maxHeight: 100.0)
        XCTAssertFalse(size.isValid)
    }

    func testIsEqual() {
        var size1: ChartboostMediationBannerSize = .adaptive(width: 100.0, maxHeight: 50.0)
        var size2: ChartboostMediationBannerSize = .adaptive(width: 100, maxHeight: 50)
        XCTAssertEqual(size1, size2)

        size1 = .standard
        size2 = .adaptive(width: 320.0, maxHeight: 50.0)
        XCTAssertNotEqual(size1, size2)

        size1 = .adaptive(width: 99.0, maxHeight: 50.0)
        size2 = .adaptive(width: 100.0, maxHeight: 50.0)
        XCTAssertNotEqual(size1, size2)
    }

    // MARK: - Conveniences
    func testHorizontalConveniences() {
        var size: ChartboostMediationBannerSize = .adaptive2x1(width: 400.0)
        XCTAssertEqual(size.size.width, 400.0, accuracy: Constants.accuracy)
        XCTAssertEqual(size.size.height, 200.0, accuracy: Constants.accuracy)

        size = .adaptive4x1(width: 400.0)
        XCTAssertEqual(size.size.width, 400.0, accuracy: Constants.accuracy)
        XCTAssertEqual(size.size.height, 100.0, accuracy: Constants.accuracy)

        size = .adaptive6x1(width: 600.0)
        XCTAssertEqual(size.size.width, 600.0, accuracy: Constants.accuracy)
        XCTAssertEqual(size.size.height, 100.0, accuracy: Constants.accuracy)

        size = .adaptive8x1(width: 400.0)
        XCTAssertEqual(size.size.width, 400.0, accuracy: Constants.accuracy)
        XCTAssertEqual(size.size.height, 50.0, accuracy: Constants.accuracy)

        size = .adaptive10x1(width: 400.0)
        XCTAssertEqual(size.size.width, 400.0, accuracy: Constants.accuracy)
        XCTAssertEqual(size.size.height, 40.0, accuracy: Constants.accuracy)
    }

    func testVerticalConveniences() {
        var size: ChartboostMediationBannerSize = .adaptive1x2(width: 100.0)
        XCTAssertEqual(size.size.width, 100.0, accuracy: Constants.accuracy)
        XCTAssertEqual(size.size.height, 200.0, accuracy: Constants.accuracy)

        size = .adaptive1x3(width: 100.0)
        XCTAssertEqual(size.size.width, 100.0, accuracy: Constants.accuracy)
        XCTAssertEqual(size.size.height, 300.0, accuracy: Constants.accuracy)

        size = .adaptive1x4(width: 100.0)
        XCTAssertEqual(size.size.width, 100.0, accuracy: Constants.accuracy)
        XCTAssertEqual(size.size.height, 400.0, accuracy: Constants.accuracy)

        size = .adaptive9x16(width: 450.0)
        XCTAssertEqual(size.size.width, 450.0, accuracy: Constants.accuracy)
        XCTAssertEqual(size.size.height, 800.0, accuracy: Constants.accuracy)
    }

    func testTileConveniences() {
        let size: ChartboostMediationBannerSize = .adaptive1x1(width: 100.0)
        XCTAssertEqual(size.size.width, 100.0, accuracy: Constants.accuracy)
        XCTAssertEqual(size.size.height, 100.0, accuracy: Constants.accuracy)
    }
}

extension ChartboostMediationBannerSizeTests {
    private struct Constants {
        static let accuracy: Double = 0.001
    }
}
