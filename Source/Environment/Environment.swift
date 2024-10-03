// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

struct Environment {
    let app: AppInfoProviding
    let audio: AudioInfoProviding
    let device: DeviceInfoProviding
    let screen: ScreenInfoProviding
    let sdk: SDKInfoProviding
    let sdkSettings: SDKSettingsProviding
    let session: SessionInfoProviding
    let skAdNetwork: SKAdNetworkInfoProviding
    let telephonyNetwork: TelephonyNetworkInfoProviding
    let testMode: TestModeInfoProviding
    let userIDProvider: UserIDProviding
    let userSettings: UserSettingsProviding
    let userAgent: UserAgentProviding

    @Injected(\.appTrackingInfo)
    var appTracking

    @Injected(\.impressionCounter)
    var impressionCounter
}
