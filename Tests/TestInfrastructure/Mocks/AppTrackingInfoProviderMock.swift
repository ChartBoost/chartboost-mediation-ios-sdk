// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AppTrackingTransparency
@testable import ChartboostMediationSDK

// This mock cannot be auto-generated because of the `AuthStatusOverride` mechanism.
final class AppTrackingInfoProviderMock: AppTrackingInfoProviding {

    /// This is needed because `appTransparencyAuthStatus` cannot be a stored property.
    /// From the compiler: `Stored properties cannot be marked potentially unavailable with '@available'`.
    enum AuthStatusOverride: UInt, CaseIterable {
        case notDetermined
        case restricted
        case denied
        case authorized
    }

    /// `appTransparencyAuthStatus` returns the same value as this one.
    var authStatusOverride: AuthStatusOverride = .notDetermined

    @available(iOS 14.0, *)
    var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus {
        switch authStatusOverride {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        }
    }
    var idfa: String?
    var idfv: String?
    var isLimitAdTrackingEnabled = false
}
