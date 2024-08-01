// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import Foundation
import XCTest

class BannerSizeTests: ChartboostMediationTestCase {
    func testFixedBannerSizes() {
        var size: BannerSize = .standard
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
        let size: BannerSize = .adaptive(width: 100.0)
        XCTAssertEqual(size.size.width, 100.0)
        XCTAssertEqual(size.size.height, 0.0)
        XCTAssertEqual(size.type, .adaptive)
    }

    func testAdaptiveSizeWithMaxHeight() {
        let size: BannerSize = .adaptive(width: 100.0, maxHeight: 50.0)
        XCTAssertEqual(size.size.width, 100.0)
        XCTAssertEqual(size.size.height, 50.0)
        XCTAssertEqual(size.type, .adaptive)
    }

    func testAspectRatioWhenSizeOrHeightIsZero() {
        var size: BannerSize = .adaptive(width: 0.0, maxHeight: 50.0)
        XCTAssertEqual(size.aspectRatio, 0.0)

        size = .adaptive(width: 100.0, maxHeight: 0.0)
        XCTAssertEqual(size.aspectRatio, 0.0)
    }

    func testAspectRatio() {
        var size: BannerSize = .adaptive(width: 100.0, maxHeight: 50.0)
        XCTAssertEqual(size.aspectRatio, 2.0, accuracy: Constants.accuracy)

        size = .adaptive(width: 50.0, maxHeight: 100.0)
        XCTAssertEqual(size.aspectRatio, 0.5, accuracy: Constants.accuracy)
    }

    func testIsValid() {
        // These should always be valid.
        XCTAssertTrue(BannerSize.standard.isValid)
        XCTAssertTrue(BannerSize.medium.isValid)
        XCTAssertTrue(BannerSize.leaderboard.isValid)

        var size: BannerSize = .adaptive(width: 200.0, maxHeight: 100.0)
        XCTAssertTrue(size.isValid)

        size = .adaptive(width: 50.0, maxHeight: 50.0)
        XCTAssertTrue(size.isValid)

        size = .adaptive(width: 1800.0, maxHeight: 1800.0)
        XCTAssertTrue(size.isValid)
    }

    func testIsValidWhenHeightIsZero() {
        var size: BannerSize = .adaptive(width: 100.0)
        XCTAssertTrue(size.isValid)

        size = .adaptive(width: 100.0, maxHeight: 1.0)
        XCTAssertFalse(size.isValid)
    }

    func testIsNotValidForInvalidSize() {
        var size: BannerSize = .adaptive(width: 100.0, maxHeight: 49.0)
        XCTAssertFalse(size.isValid)

        size = .adaptive(width: 100.0, maxHeight: 1801.0)
        XCTAssertFalse(size.isValid)

        size = .adaptive(width: 49.0, maxHeight: 100.0)
        XCTAssertFalse(size.isValid)

        size = .adaptive(width: 1801.0, maxHeight: 100.0)
        XCTAssertFalse(size.isValid)
    }

    func testIsEqual() {
        var size1: BannerSize = .adaptive(width: 100.0, maxHeight: 50.0)
        var size2: BannerSize = .adaptive(width: 100, maxHeight: 50)
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
        var size: BannerSize = .adaptive2x1(width: 400.0)
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
        var size: BannerSize = .adaptive1x2(width: 100.0)
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
        let size: BannerSize = .adaptive1x1(width: 100.0)
        XCTAssertEqual(size.size.width, 100.0, accuracy: Constants.accuracy)
        XCTAssertEqual(size.size.height, 100.0, accuracy: Constants.accuracy)
    }

    func testLargestFixedSizeThatFits() {
        let narrowerThanStandard = BannerSize.adaptive(width: 319, maxHeight: 50)
        let shorterThanStandard = BannerSize.adaptive(width: 320, maxHeight: 49)
        let sameAsStandard = BannerSize.adaptive(width: 320, maxHeight: 50)
        let widerThanStandard = BannerSize.adaptive(width: 321, maxHeight: 50)
        let tallerThanStandard = BannerSize.adaptive(width: 320, maxHeight: 51)
        // Sizes smaller than .standard should return nil.
        XCTAssertNil(BannerSize.largestStandardFixedSizeThatFits(in: narrowerThanStandard))
        XCTAssertNil(BannerSize.largestStandardFixedSizeThatFits(in: shorterThanStandard))
        // Sizes with height and width >= .standard should return .standard
        XCTAssertEqual(BannerSize.largestStandardFixedSizeThatFits(in: sameAsStandard), .standard)
        XCTAssertEqual(BannerSize.largestStandardFixedSizeThatFits(in: widerThanStandard), .standard)
        XCTAssertEqual(BannerSize.largestStandardFixedSizeThatFits(in: tallerThanStandard), .standard)

        let narrowerThanMedium = BannerSize.adaptive(width: 299, maxHeight: 250)
        let shorterThanMedium = BannerSize.adaptive(width: 300, maxHeight: 249)
        let sameAsMedium = BannerSize.adaptive(width: 300, maxHeight: 250)
        let widerThanMedium = BannerSize.adaptive(width: 301, maxHeight: 250)
        let tallerThanMedium = BannerSize.adaptive(width: 300, maxHeight: 251)
        // Sizes that are smaller than .medium in one dimension but too large for .standard should return nil.
        XCTAssertNil(BannerSize.largestStandardFixedSizeThatFits(in: narrowerThanMedium))
        XCTAssertNil(BannerSize.largestStandardFixedSizeThatFits(in: shorterThanMedium))
        // Sizes with height and width >= .medium should return .medium.
        XCTAssertEqual(BannerSize.largestStandardFixedSizeThatFits(in: sameAsMedium), .medium)
        XCTAssertEqual(BannerSize.largestStandardFixedSizeThatFits(in: widerThanMedium), .medium)
        XCTAssertEqual(BannerSize.largestStandardFixedSizeThatFits(in: tallerThanMedium), .medium)

        let narrowerThanLeaderboard = BannerSize.adaptive(width: 727, maxHeight: 90)
        let shorterThanLeaderboard = BannerSize.adaptive(width: 728, maxHeight: 89)
        let sameAsLeaderboard = BannerSize.adaptive(width: 728, maxHeight: 90)
        let widerThanLeaderboard = BannerSize.adaptive(width: 729, maxHeight: 90)
        let tallerThanLeaderboard = BannerSize.adaptive(width: 728, maxHeight: 91)
        // Sizes that are slightly smaller than .leaderboard in one dimension will still fit in .standard.
        XCTAssertEqual(BannerSize.largestStandardFixedSizeThatFits(in: narrowerThanLeaderboard), .standard)
        XCTAssertEqual(BannerSize.largestStandardFixedSizeThatFits(in: shorterThanLeaderboard), .standard)
        // Sizes with height and width >= .leaderboard should return .leaderboard.
        XCTAssertEqual(BannerSize.largestStandardFixedSizeThatFits(in: sameAsLeaderboard), .leaderboard)
        XCTAssertEqual(BannerSize.largestStandardFixedSizeThatFits(in: widerThanLeaderboard), .leaderboard)
        XCTAssertEqual(BannerSize.largestStandardFixedSizeThatFits(in: tallerThanLeaderboard), .leaderboard)

        let anyHeightStandardWidth = BannerSize.adaptive(width: 320, maxHeight: 0)
        let anyHeightMediumWidth = BannerSize.adaptive(width: 300, maxHeight: 0)
        let anyHeightLeaderboardWidth = BannerSize.adaptive(width: 728, maxHeight: 0)
        // Because we return the largest size that will fit and .medium is ranked as larger than .standard,
        // calling the method with either anyHeightStandardWidth and anyHeightMediumWidth will both return .medium
        XCTAssertEqual(BannerSize.largestStandardFixedSizeThatFits(in: anyHeightStandardWidth), .medium)
        XCTAssertEqual(BannerSize.largestStandardFixedSizeThatFits(in: anyHeightMediumWidth), .medium)
        XCTAssertEqual(BannerSize.largestStandardFixedSizeThatFits(in: anyHeightLeaderboardWidth), .leaderboard)
    }
}

extension BannerSizeTests {
    private struct Constants {
        static let accuracy: Double = 0.001
    }
}
