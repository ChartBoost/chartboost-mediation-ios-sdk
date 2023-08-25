// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class UserIDProviderTests: HeliumTestCase {
    private static let zeroUUID = AppTrackingInfoProvider.Constant.zeroUUID
    private static let validUUID = "12300000-0000-0000-0000-000000000789"
    private static let idfa_testValues = [nil, zeroUUID, validUUID]
    private static let idfv_testValues = [nil, zeroUUID, validUUID]
    private static let isLimitAdTrackingEnabled_testValues = [false, true]
    private static let chartboostID_testValues = [nil, "some chartboost ID"]

    func testPublisherUserID() {
        let userIDProvider = UserIDProvider()
        userIDProvider.publisherUserID = "123"
        XCTAssertEqual(userIDProvider.publisherUserID, "123")
        userIDProvider.publisherUserID = nil
        XCTAssertNil(userIDProvider.publisherUserID)
    }

    func testUserID() {
        let userIDProvider = UserIDProvider()
        Self.idfa_testValues.forEach { idfa in
            Self.idfv_testValues.forEach { idfv in
                Self.isLimitAdTrackingEnabled_testValues.forEach { isLimitAdTrackingEnabled in
                    Self.chartboostID_testValues.forEach { chartboostID in

                        // setup
                        mocks.appTrackingInfo.idfa = idfa
                        mocks.appTrackingInfo.idfv = idfv
                        mocks.appTrackingInfo.isLimitAdTrackingEnabled = isLimitAdTrackingEnabled
                        mocks.chartboostIDProvider.chartboostID = chartboostID

                        // test
                        if !isLimitAdTrackingEnabled,
                           let idfa,
                           idfa != AppTrackingInfoProvider.Constant.zeroUUID
                        {
                            XCTAssertEqual(userIDProvider.userID, idfa)
                        } else if let idfv, idfv != Self.zeroUUID {
                            XCTAssertEqual(userIDProvider.userID, idfv)
                        } else {
                            XCTAssertEqual(userIDProvider.userID, chartboostID)
                        }
                    }
                }
            }
        }
    }
}
