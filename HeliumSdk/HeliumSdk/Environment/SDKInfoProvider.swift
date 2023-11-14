// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol SDKInfoProviding {
    var sdkName: String { get }
    var sdkVersion: String { get }
}

struct SDKInfoProvider: SDKInfoProviding {
    // HB-5026: do not change this to "Chartboost" yet - this appears in the request payload of the
    // /auction endpoint and there are validation rules against this name.
    let sdkName = "Helium"

    // WARNING: CI updates the following line with the correct SDK version. Check CI first before editing.
    var sdkVersion: String { "4.7.0" }
}
