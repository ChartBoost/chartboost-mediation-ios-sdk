// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol SDKInfoProviding {
    var sdkName: String { get }
    var sdkVersion: String { get }
}

struct SDKInfoProvider: SDKInfoProviding {
    let sdkName = "Helium"

    let sdkVersion = "5.0.0"
}
