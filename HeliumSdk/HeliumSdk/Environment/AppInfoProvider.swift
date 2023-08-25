// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol AppInfoProviding: AnyObject {
    var appID: String? { get set }
    var appSignature: String? { get set }
    var appVersion: String? { get }
    var bundleID: String? { get }
    var gameEngineName: String? { get set }
    var gameEngineVersion: String? { get set }
}

final class AppInfoProvider: AppInfoProviding {

    @Injected(\.bundleInfo) private var bundleInfo
    @Injected(\.infoPlist) private var infoPlist

    var appID: String?

    var appSignature: String?

    var appVersion: String? {
        infoPlist.appVersion
    }

    var bundleID: String? {
        bundleInfo.mainBundle.bundleIdentifier
    }

    var gameEngineName: String?

    var gameEngineVersion: String?
}
