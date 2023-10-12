// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class DeviceInfoTests: HeliumTestCase {
    func testDeviceInfo() {
        let info = DeviceInfoProvider()
        XCTAssert(
            info.batteryLevel == -1 || // -1 if UIDeviceBatteryStateUnknown, which is typical on Mac
            (0 <= info.batteryLevel && info.batteryLevel <= 1)
        )
        XCTAssertEqual(info.deviceMake, "Apple")
        XCTAssertFalse(info.deviceModel.isEmpty)
        XCTAssertEqual(info.deviceType, UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone)
        XCTAssertEqual(info.osName, "iOS")
        XCTAssertFalse(info.osVersion.isEmpty)
        if #available(iOS 17.0, *) {
            XCTAssert(info.freeDiskSpace == 0)
            XCTAssert(info.totalDiskSpace == 0)
        } else {
            XCTAssert(info.freeDiskSpace > 0)
            XCTAssert(info.totalDiskSpace > 0)
        }
    }

    func testPrivacyBanList() {
        let info = DeviceInfoProvider()

        if #available(iOS 17.0, *) {
            mocks.privacyConfigurationDependency.privacyBanList = [.sysctl]
            XCTAssertEqual(info.deviceModel, "iPhone")

            mocks.privacyConfigurationDependency.privacyBanList = []
            XCTAssert(["arm64", "x86_64"].contains(info.deviceModel))
        } else {
            mocks.privacyConfigurationDependency.privacyBanList = [.sysctl]
            XCTAssert(["arm64", "x86_64"].contains(info.deviceModel))

            mocks.privacyConfigurationDependency.privacyBanList = []
            XCTAssert(["arm64", "x86_64"].contains(info.deviceModel))
        }
    }
}
