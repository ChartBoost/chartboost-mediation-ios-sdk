// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AdSupport
import AppTrackingTransparency

protocol AppTrackingInfoProviding {
    var appTransparencyAuthStatus: UInt? { get }
    var idfa: String? { get }
    var idfv: String? { get }
    var isLimitAdTrackingEnabled: Bool { get }
}

/// This is needed for mocking iOS provided values in unit tests.
protocol AppTrackingInfoProviderDependency {
    @available(iOS 14.0, *)
    var appTransparencyAuthStatus: ATTrackingManager.AuthorizationStatus { get }

    var idfa: String { get }

    var idfv: String? { get }

    // Apple doc: @available(iOS, introduced: 6, deprecated: 14, message: "This has been replaced by functionality in AppTrackingTransparency's ATTrackingManager class.")
    var isAdvertisingTrackingEnabled: Bool { get }
}

struct AppTrackingInfoProvider: AppTrackingInfoProviding {

    typealias Dependency = AppTrackingInfoProviderDependency

    /// All iOS API calls should be made here, not other places in `AppTrackingInfoProvider`.
    struct SystemDependency: Dependency {

        @available(iOS 14.0, *)
        var appTransparencyAuthStatus: ATTrackingManager.AuthorizationStatus {
            ATTrackingManager.trackingAuthorizationStatus
        }

        var idfa: String {
            ASIdentifierManager.shared().advertisingIdentifier.uuidString
        }

        var idfv: String? {
            UIDevice.current.identifierForVendor?.uuidString
        }

        var isAdvertisingTrackingEnabled: Bool {
            ASIdentifierManager.shared().isAdvertisingTrackingEnabled
        }
    }

    enum Constant {
        /// In cases where advertising tracking is not allowed, the UUID will be '00000000-0000-0000-0000-000000000000'
        /// https://developer.apple.com/documentation/adsupport/asidentifiermanager/1614151-advertisingidentifier
        static let zeroUUID = "00000000-0000-0000-0000-000000000000"
    }

    @Injected(\.appTrackingInfoDependency) private var appTrackingInfoDependency

    var appTransparencyAuthStatus: UInt? {
        if #available(iOS 14.0, *) {
            return appTrackingInfoDependency.appTransparencyAuthStatus.rawValue
        } else {
            return nil
        }
    }

    var idfa: String? {
        // In cases where advertising tracking is not allowed, the UUID will be '00000000-0000-0000-0000-000000000000'
        // https://developer.apple.com/documentation/adsupport/asidentifiermanager/1614151-advertisingidentifier
        let ifa = appTrackingInfoDependency.idfa

        // We translate '00000000-0000-0000-0000-000000000000' into `nil` so that it is
        // unambiguous that the IFA is unavailable for use.
        if ifa == Constant.zeroUUID {
            return nil;
        }

        return ifa;
    }

    var idfv: String? {
        appTrackingInfoDependency.idfv
    }

    var isLimitAdTrackingEnabled: Bool {
        !isAllowedToTrack
    }

    private var isAdvertisingTrackingLimitedOSLevel: Bool {
        !appTrackingInfoDependency.isAdvertisingTrackingEnabled
    }

    /// Indicates if we are allowed to track the user for advertising purposes.
    private var isAllowedToTrack: Bool {
        // Give priority to Apple's App Tracking Transparency framework which replaces
        // the deprecated `ASIdentifierManager.isAdvertisingTrackingEnabled` property.
        if #available(iOS 14.0, *) {
            // As of iOS 14, Apple does not provide an explicit means of checking if the IDFA is available.
            // The IDFA may or may not be available with an ATT status of `.notDetermined`, depending on if
            // Apple has decided to enforce ATT as opt-in as they plan to. Therefore, if the ATT status
            // is `.notDetermined`, use the IDFA itself to work out the return value of this method.
            var status = ATTrackingManager.AuthorizationStatus.notDetermined
            let attStatus = appTransparencyAuthStatus
            if let attStatus, let validAuthStatus = ATTrackingManager.AuthorizationStatus(rawValue: attStatus) {
                status = validAuthStatus
            }

            switch status {
            case .authorized:
                // Authorized to track
                return true

            case .notDetermined:
                // Allowed to track if an IFA is given back from Apple's API
                let idfa = self.idfa
                return idfa != nil && idfa != Constant.zeroUUID

            default:
                // Not allowed
                return false
            }
        }

        return isAdvertisingTrackingLimitedOSLevel == false
    }
}
