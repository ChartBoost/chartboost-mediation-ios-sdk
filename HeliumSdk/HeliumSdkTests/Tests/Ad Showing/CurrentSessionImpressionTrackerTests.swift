// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class CurrentSessionImpressionTrackerTests: HeliumTestCase {
    
    let impressionTracker = CurrentSessionImpressionTracker()
    
    /// Validates that the intial tracker values are 0 for all ad types.
    func testInitialValues() {
        XCTAssertEqual(impressionTracker.interstitialImpressionCount, 0)
        XCTAssertEqual(impressionTracker.rewardedImpressionCount, 0)
        XCTAssertEqual(impressionTracker.bannerImpressionCount, 0)
    }
    
    /// Validates that tracking an impression increases the count only for that ad format.
    func testTrackImpression() {
        impressionTracker.trackImpression(for: .rewarded)
        
        XCTAssertEqual(impressionTracker.interstitialImpressionCount, 0)
        XCTAssertEqual(impressionTracker.rewardedImpressionCount, 1)
        XCTAssertEqual(impressionTracker.bannerImpressionCount, 0)
    }
    
    /// Validates that tracking multiple impressions affect only the corresponding ad formats.
    func testTrackMultipleImpressions() {
        impressionTracker.trackImpression(for: .interstitial)
        impressionTracker.trackImpression(for: .interstitial)
        
        XCTAssertEqual(impressionTracker.interstitialImpressionCount, 2)
        XCTAssertEqual(impressionTracker.rewardedImpressionCount, 0)
        XCTAssertEqual(impressionTracker.bannerImpressionCount, 0)
        
        impressionTracker.trackImpression(for: .banner)
        impressionTracker.trackImpression(for: .interstitial)
        
        XCTAssertEqual(impressionTracker.interstitialImpressionCount, 3)
        XCTAssertEqual(impressionTracker.rewardedImpressionCount, 0)
        XCTAssertEqual(impressionTracker.bannerImpressionCount, 1)
    }
}
