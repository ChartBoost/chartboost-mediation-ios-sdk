// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AppTrackingTransparency
@testable import ChartboostMediationSDK

// This mock cannot be auto-generated because of the `AuthStatusOverride` mechanism (see AppTrackingInfoProviderMock).
final class AppTrackingInfoProviderDependencyMock: AppTrackingInfoProviderDependency {
    /// `appTransparencyAuthStatus` returns the same value as this one.
    var authStatusOverride: AppTrackingInfoProviderMock.AuthStatusOverride = .notDetermined

    @available(iOS 14.0, *)
    var appTransparencyAuthStatus: ATTrackingManager.AuthorizationStatus {
        switch authStatusOverride {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        }
    }
    var idfa: String? = ""
    var idfv: String? = ""
    var isAdvertisingTrackingLimited = true
}
