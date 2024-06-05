// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import XCTest

/// This is a compile time test, not a runtime test.
/// The tests pass as long as everything compiles without errors.
class APIStabilityTests_Swift: ChartboostMediationTestCase {

    /// API stability test for the Chartboost Mediation SDK.
    func stability_Mediation() -> Any? {
        let mediation = Helium.shared()
        var result: Any?

        mediation.start(withAppId: "", options: nil, delegate: nil)
        mediation.start(withAppId: "", options: HeliumInitializationOptions(skippedPartnerIdentifiers: nil), delegate: HeliumSdkDelegateMock())

        mediation.start(withAppId: "", andAppSignature: "", options: nil, delegate: nil)
        mediation.start(withAppId: "", andAppSignature: "", options: HeliumInitializationOptions(skippedPartnerIdentifiers: nil), delegate: HeliumSdkDelegateMock())

        result = mediation.interstitialAdProvider(with: nil, andPlacementName: "")
        result = mediation.interstitialAdProvider(with: HeliumInterstitialAdDelegateMock(), andPlacementName: "")

        result = mediation.rewardedAdProvider(with: nil, andPlacementName: "")
        result = mediation.rewardedAdProvider(with: HeliumRewardedAdDelegateMock(), andPlacementName: "")

        result = mediation.bannerProvider(with: nil, andPlacementName: "", andSize: .standard)
        result = mediation.bannerProvider(with: HeliumBannerAdDelegateMock(), andPlacementName: "", andSize: .standard)

        mediation.loadFullscreenAd(with: ChartboostMediationAdLoadRequest(placement: "")) { _ in }

        mediation.setSubjectToCoppa(false)
        mediation.setSubjectToGDPR(false)
        mediation.setUserHasGivenConsent(false)
        mediation.setCCPAConsent(false)

        result = mediation.userIdentifier
        mediation.userIdentifier = nil

        mediation.setGameEngineName(nil, version: nil)
        mediation.setGameEngineName("", version: "")

        result = Helium.sdkVersion
        result = Helium.isTestModeEnabled
        Helium.isTestModeEnabled = false

        result = mediation.initializedAdapterInfo

        let _: [PartnerIdentifier: Bool] = mediation.partnerConsents
        mediation.partnerConsents["some id"] = true
        mediation.partnerConsents["some id"] = nil
        mediation.partnerConsents = ["some id 1": false, "some id 2": true]

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
