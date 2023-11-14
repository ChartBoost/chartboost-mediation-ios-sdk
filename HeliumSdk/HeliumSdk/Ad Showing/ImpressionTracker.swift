// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Tracks the number of impressions for each ad format.
protocol ImpressionTracker {
    /// Increases the impression count for the specified ad format.
    func trackImpression(for format: AdFormat)
}

/// Provides the impression count for each ad format.
/// - note: We don't have a single method because AdFormat is not Obj-C compatible, but we should change this once this protocol isn't needed by Obj-C code anymore.
protocol ImpressionCounter {
    /// The number of interstitial impressions tracked.
    var interstitialImpressionCount: Int { get }
    
    /// The number of rewarded impressions tracked.
    var rewardedImpressionCount: Int { get }
    
    /// The number of banner impressions tracked.
    var bannerImpressionCount: Int { get }
}

/// Tracks the number of impressions during the current session.
final class CurrentSessionImpressionTracker: ImpressionTracker & ImpressionCounter {
    
    private var impressionCount: [AdFormat: Int] = [:]
    
    func trackImpression(for format: AdFormat) {
        impressionCount[format, default: 0] += 1
    }
    
    var interstitialImpressionCount: Int {
        impressionCount[.interstitial] ?? 0
    }
    
    var rewardedImpressionCount: Int {
        impressionCount[.rewarded] ?? 0
    }
    
    var bannerImpressionCount: Int {
        // Since we track impressions based on the requested ad format, we need to add impressions
        // for both banner types to get the total impression count for banners.
        (impressionCount[.banner] ?? 0) + (impressionCount[.adaptiveBanner] ?? 0)
    }
}
