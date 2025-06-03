// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol SDKSettingsProviding: AnyObject {
    var discardOversizedAds: Bool { get set }
}

final class SDKSettingsProvider: SDKSettingsProviding {
    var discardOversizedAds = false
}
