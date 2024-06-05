// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension SDKInitHTTPRequest {
    /// A convenience factory method to obtain an instance with minimum boilerplate code.
    static func test(
        appID: String = "some app id",
        deviceOSName: String = "some os name",
        deviceOSVersion: String = "some os version",
        sdkInitHash: String? = "some init hash",
        sdkVersion: String = "some SDK version"
    ) -> Self {
        SDKInitHTTPRequest(
            appID: appID,
            deviceOSName: deviceOSName,
            deviceOSVersion: deviceOSVersion,
            sdkInitHash: sdkInitHash,
            sdkVersion: sdkVersion
        )
    }
}
