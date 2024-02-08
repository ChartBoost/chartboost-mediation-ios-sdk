// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import XCTest

/// This is a compile time test, not a runtime test.
/// The tests pass as long as everything compiles without errors.
class APIStabilityTests_Swift: ChartboostMediationTestCase {

    /// API stability test for `Helium`.
    func stability_Helium() -> Any? {
        let helium = Helium.shared()
        var result: Any?

        helium.start(withAppId: "", options: nil, delegate: nil)
        helium.start(withAppId: "", options: HeliumInitializationOptions(skippedPartnerIdentifiers: nil), delegate: HeliumSdkDelegateMock())

        helium.start(withAppId: "", andAppSignature: "", options: nil, delegate: nil)
        helium.start(withAppId: "", andAppSignature: "", options: HeliumInitializationOptions(skippedPartnerIdentifiers: nil), delegate: HeliumSdkDelegateMock())

        result = helium.interstitialAdProvider(with: nil, andPlacementName: "")
        result = helium.interstitialAdProvider(with: HeliumInterstitialAdDelegateMock(), andPlacementName: "")

        result = helium.rewardedAdProvider(with: nil, andPlacementName: "")
        result = helium.rewardedAdProvider(with: HeliumRewardedAdDelegateMock(), andPlacementName: "")

        result = helium.bannerProvider(with: nil, andPlacementName: "", andSize: .standard)
        result = helium.bannerProvider(with: HeliumBannerAdDelegateMock(), andPlacementName: "", andSize: .standard)

        helium.loadFullscreenAd(with: ChartboostMediationAdLoadRequest(placement: "")) { _ in }

        helium.setSubjectToCoppa(false)
        helium.setSubjectToGDPR(false)
        helium.setUserHasGivenConsent(false)
        helium.setCCPAConsent(false)

        result = helium.userIdentifier
        helium.userIdentifier = nil

        helium.setGameEngineName(nil, version: nil)
        helium.setGameEngineName("", version: "")

        result = Helium.sdkVersion

        result = helium.initializedAdapterInfo

        let _: [PartnerIdentifier: Bool] = helium.partnerConsents
        helium.partnerConsents["some id"] = true
        helium.partnerConsents["some id"] = nil
        helium.partnerConsents = ["some id 1": false, "some id 2": true]

        return result // for suppressing the "variable was written to, but never read" warning
    }

    /// API stability test for notifications.
    func stability_notifications() {
        NotificationCenter.default.addObserver(
            forName: .heliumDidReceiveILRD,
            object: nil,
            queue: nil
        ) { notification in
            // Extract the ILRD payload.
            guard let ilrd = notification.object as? HeliumImpressionData else { return }
            let _ = ilrd.placement
            let _ = ilrd.jsonData
        }

        NotificationCenter.default.addObserver(
            forName: .heliumDidReceiveInitResults,
            object: nil,
            queue: nil
        ) { notification in
            // Extract the results payload.
            guard let _ = notification.object as? [String: Any] else { return }
        }
    }
}
