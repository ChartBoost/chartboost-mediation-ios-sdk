// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import XCTest

final class AdFormatTests: ChartboostMediationTestCase {

    /// Validates that the `isBanner` property returns the expected value.
    func testIsBanner() throws {
        XCTAssertTrue(AdFormat.adaptiveBanner.isBanner)
        XCTAssertTrue(AdFormat.banner.isBanner)
        XCTAssertFalse(AdFormat.interstitial.isBanner)
        XCTAssertFalse(AdFormat.rewarded.isBanner)
        XCTAssertFalse(AdFormat.rewardedInterstitial.isBanner)
    }

    /// Validates that the `isFullscreen` property returns the expected value.
    func testIsFullscreen() throws {
        XCTAssertFalse(AdFormat.adaptiveBanner.isFullscreen)
        XCTAssertFalse(AdFormat.banner.isFullscreen)
        XCTAssertTrue(AdFormat.interstitial.isFullscreen)
        XCTAssertTrue(AdFormat.rewarded.isFullscreen)
        XCTAssertTrue(AdFormat.rewardedInterstitial.isFullscreen)
    }

    /// Validates that the `partnerAdFormat` property maps `AdFormat` to `PartnerAdFormat` properly.
    func testPartnerAdFormat() throws {
        XCTAssertEqual(AdFormat.adaptiveBanner.partnerAdFormat, PartnerAdFormats.banner)
        XCTAssertEqual(AdFormat.banner.partnerAdFormat, PartnerAdFormats.banner)
        XCTAssertEqual(AdFormat.interstitial.partnerAdFormat, PartnerAdFormats.interstitial)
        XCTAssertEqual(AdFormat.rewarded.partnerAdFormat, PartnerAdFormats.rewarded)
        XCTAssertEqual(AdFormat.rewardedInterstitial.partnerAdFormat, PartnerAdFormats.rewardedInterstitial)
    }
}
