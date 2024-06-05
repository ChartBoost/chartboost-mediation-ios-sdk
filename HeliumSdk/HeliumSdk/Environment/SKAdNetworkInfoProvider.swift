// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol SKAdNetworkInfoProviding {
    var skAdNetworkIDs: [String] { get }
    var skAdNetworkVersion: String { get }
}

struct SKAdNetworkInfoProvider: SKAdNetworkInfoProviding {
    @Injected(\.infoPlist) private var infoPlist

    var skAdNetworkIDs: [String] {
        infoPlist.skAdNetworkIDs
    }

    var skAdNetworkVersion: String {
        // https://developer.apple.com/documentation/storekit/skadnetwork/skadnetwork_release_notes
        if #available(iOS 14.5, *) {
            return "2.2"
        } else if #available(iOS 14, *) {
            return "2.0"
        } else if #available(iOS 11.3, *) {
            return "1.0"
        } else {
            return "0.0"
        }
    }
}
