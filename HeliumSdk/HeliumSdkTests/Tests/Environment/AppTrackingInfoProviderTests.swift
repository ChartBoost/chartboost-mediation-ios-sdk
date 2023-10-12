// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class AppTrackingInfoProviderTests: HeliumTestCase {

    private static let zeroUUID = AppTrackingInfoProvider.Constant.zeroUUID // "00000000-0000-0000-0000-000000000000"
    private static let validUUID = "12300000-0000-0000-0000-000000000789"
    private static let possibleValuesOfIsSubjectToCOPPA = [true, false, nil]
    private static let possibleValuesOfAuthStatus = AppTrackingInfoProviderDependencyMock.AuthStatusOverride.allCases
    private static let possibleValuesOfIDFADependency = [validUUID, zeroUUID] // Apple IDFA is never nil
    private static let possibleValuesOfIDFVDependency = [validUUID, zeroUUID, nil]
    private static let possibleValuesOfIsAdvertisingTrackingEnabled = [true, false]
    private let appTrackingInfo = AppTrackingInfoProvider()

    func testAllProperties() throws {
        Self.possibleValuesOfAuthStatus.forEach { authStatus in
            Self.possibleValuesOfIDFADependency.forEach { idfa in
                Self.possibleValuesOfIDFVDependency.forEach { idfv in
                    Self.possibleValuesOfIsAdvertisingTrackingEnabled.forEach { isAdvertisingTrackingEnabled in

                        // setup and mock the values provided by iOS
                        let dependencyMock = mocks.appTrackingInfoProviderDependency
                        dependencyMock.authStatusOverride = authStatus
                        dependencyMock.idfa = idfa
                        dependencyMock.idfv = idfv
                        dependencyMock.isAdvertisingTrackingEnabled = isAdvertisingTrackingEnabled

                        // test 1: auth status (always the same as the dependency)
                        XCTAssertEqual(appTrackingInfo.appTransparencyAuthStatus, authStatus.rawValue)

                        // test 2: IDFA
                        // `dependencyMock.authStatusOverride` does not have a role in this `if`
                        // because it's a implicit dependency. In reality, IDFA is valid only if
                        // the auth status is `.authorized`.
                        if
                            idfa != Self.zeroUUID,
                            appTrackingInfo.idfa != Self.zeroUUID
                        {
                            XCTAssertEqual(appTrackingInfo.idfa, Self.validUUID)
                        } else {
                            XCTAssertNil(appTrackingInfo.idfa)
                        }

                        // test 3: IDFV (always the same as the dependency)
                        XCTAssertEqual(appTrackingInfo.idfv, idfv)

                        // test 4: limit ad tracking
                        switch authStatus {
                        case .authorized:
                            XCTAssertFalse(appTrackingInfo.isLimitAdTrackingEnabled)

                        case .notDetermined:
                            XCTAssertEqual(appTrackingInfo.isLimitAdTrackingEnabled, idfa == Self.zeroUUID)

                        case .restricted, .denied:
                            XCTAssert(appTrackingInfo.isLimitAdTrackingEnabled)
                        }
                    }
                }
            }
        }
    }
}
